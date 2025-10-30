#!/bin/bash
# ============================================================================
# MediaGenie Azure Marketplace 完整部署脚本 (前后端分�?
# 符合 Azure Marketplace 要求的双 URL 部署
# ============================================================================

set -e  # 遇到错误立即退�?
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "�?     MediaGenie - Azure Marketplace 完整部署 (前后端分�?        �?
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 配置变量
# ============================================================================

# 资源组名�?RESOURCE_GROUP="MediaGenie-Marketplace-RG"

# 应用名称基础 (会自动添加唯一后缀)
APP_NAME_BASE="mediagenie"

# 区域 (更换到配额充足的区域)
LOCATION="westus"

# App Service计划定价�?(使用 F1 免费层避�?Basic VM 配额限制)
SKU="F1"

# ============================================================================
# Azure服务配置 - 符合 Azure Marketplace 安全要求
# ============================================================================
# ⚠️  重要: 为了符合 Azure Marketplace 的安全规�?密钥不应硬编码在脚本�?# 
# 部署方式选择:
# 方式 1: 交互式输�?(推荐用于手动部署)
# 方式 2: 环境变量 (推荐用于 CI/CD)
# 方式 3: Azure Key Vault 引用 (推荐用于生产环境)
# ============================================================================

# 检查是否通过环境变量提供密钥
if [ -z "$AZURE_OPENAI_KEY" ]; then
    echo "请输�?Azure OpenAI API Key:"
    read -s AZURE_OPENAI_KEY
    echo ""
fi

if [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
    echo "请输�?Azure OpenAI Endpoint (�? https://your-openai.openai.azure.com/):"
    read AZURE_OPENAI_ENDPOINT
fi

if [ -z "$AZURE_SPEECH_KEY" ]; then
    echo "请输�?Azure Speech Service Key:"
    read -s AZURE_SPEECH_KEY
    echo ""
fi

if [ -z "$AZURE_SPEECH_REGION" ]; then
    echo "请输�?Azure Speech Service Region (�? westus):"
    read AZURE_SPEECH_REGION
fi

# 验证必需的密钥是否已提供
if [ -z "$AZURE_OPENAI_KEY" ] || [ -z "$AZURE_OPENAI_ENDPOINT" ] || \
   [ -z "$AZURE_SPEECH_KEY" ] || [ -z "$AZURE_SPEECH_REGION" ]; then
    print_error "缺少必需�?Azure 服务密钥配置"
fi

# 可�? Computer Vision 密钥
AZURE_VISION_KEY="${AZURE_VISION_KEY:-}"
AZURE_VISION_ENDPOINT="${AZURE_VISION_ENDPOINT:-}"

# ============================================================================
# 函数定义
# ============================================================================

print_step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() {
    echo "�?$1"
}

print_error() {
    echo "�?错误: $1"
    exit 1
}

print_warning() {
    echo "⚠️  警告: $1"
}

# ============================================================================
# 步骤 1: 验证环境
# ============================================================================

print_step "步骤 1/11: 验证环境"

# 检查是否在Cloud Shell�?if ! command -v az &> /dev/null; then
    print_error "Azure CLI未安�?请在Azure Cloud Shell中运行此脚本"
fi

# 检查是否已登录
az account show &> /dev/null || print_error "请先登录Azure (az login)"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "当前订阅: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# 检查必要工�?if ! command -v node &> /dev/null; then
    print_warning "Node.js未安�?将跳过前端构�?
    SKIP_FRONTEND_BUILD=true
else
    NODE_VERSION=$(node --version)
    echo "Node.js版本: $NODE_VERSION"
    SKIP_FRONTEND_BUILD=false
fi

if ! command -v zip &> /dev/null; then
    print_error "zip工具未安�?无法创建部署�?
fi

print_success "环境验证通过"

# ============================================================================
# 步骤 2: 生成唯一名称
# ============================================================================

print_step "步骤 2/11: 生成唯一应用名称"

# 生成随机后缀
RANDOM_SUFFIX=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)
BACKEND_APP_NAME="${APP_NAME_BASE}-api-${RANDOM_SUFFIX}"
FRONTEND_APP_NAME="${APP_NAME_BASE}-web-${RANDOM_SUFFIX}"

echo "后端应用名称: $BACKEND_APP_NAME"
echo "后端URL: https://${BACKEND_APP_NAME}.azurewebsites.net"
echo "前端应用名称: $FRONTEND_APP_NAME"
echo "前端URL: https://${FRONTEND_APP_NAME}.azurewebsites.net"

# ============================================================================
# 步骤 3: 创建资源�?# ============================================================================

print_step "步骤 3/11: 创建资源�?

if az group show --name $RESOURCE_GROUP &> /dev/null; then
    print_warning "资源�?$RESOURCE_GROUP 已存�?将使用现有资源组"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --output none
    print_success "资源组创建成�? $RESOURCE_GROUP"
fi

# ============================================================================
# 步骤 4: 创建App Service计划
# ============================================================================

print_step "步骤 4/11: 创建App Service计划"

PLAN_NAME="${APP_NAME_BASE}-plan-${RANDOM_SUFFIX}"

# 检查计划是否已存在
if az appservice plan show --name $PLAN_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    print_warning "App Service计划 $PLAN_NAME 已存�?
else
    az appservice plan create \
        --name $PLAN_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku $SKU \
        --is-linux \
        --output none
    print_success "App Service计划创建成功: $PLAN_NAME ($SKU)"
fi

# ============================================================================
# 步骤 5: 创建后端Web App
# ============================================================================

print_step "步骤 5/11: 创建后端API Web App"

az webapp create \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --runtime "PYTHON:3.10" \
    --output none

print_success "后端Web App创建成功: $BACKEND_APP_NAME"

# ============================================================================
# 步骤 6: 配置后端应用设置
# ============================================================================

print_step "步骤 6/11: 配置后端应用设置"

az webapp config appsettings set \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        AZURE_OPENAI_API_KEY="$AZURE_OPENAI_KEY" \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_OPENAI_DEPLOYMENT="gpt-4.1" \
        AZURE_OPENAI_API_VERSION="2025-01-01-preview" \
        AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
        AZURE_SPEECH_REGION="$AZURE_SPEECH_REGION" \
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
        WEBSITE_HTTPLOGGING_RETENTION_DAYS="7" \
    --output none

# 配置启动命令
az webapp config set \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --startup-file "cd backend/media-service && gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000 --timeout 120" \
    --output none

# 启用Always On (B1及以上支�?
if [ "$SKU" != "F1" ]; then
    az webapp config set \
        --name $BACKEND_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --always-on true \
        --output none
fi

# 启用HTTPS Only
az webapp update \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --https-only true \
    --output none

# 配置CORS (允许前端调用)
FRONTEND_URL="https://${FRONTEND_APP_NAME}.azurewebsites.net"
az webapp cors add \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --allowed-origins "$FRONTEND_URL" \
    --output none

print_success "后端应用设置配置完成"

# ============================================================================
# 步骤 7: 部署后端代码
# ============================================================================

print_step "步骤 7/11: 部署后端代码"

echo "准备后端部署�?.."

# 创建临时部署目录
BACKEND_DEPLOY_DIR="/tmp/mediagenie-backend-deploy"
rm -rf $BACKEND_DEPLOY_DIR
mkdir -p $BACKEND_DEPLOY_DIR

# 复制后端文件
echo "复制后端项目文件..."
cp -r backend $BACKEND_DEPLOY_DIR/

# 创建根目�?requirements.txt (如果不存�?
if [ ! -f "$BACKEND_DEPLOY_DIR/backend/media-service/requirements.txt" ]; then
    print_error "后端 requirements.txt 不存�?"
fi

# 复制到根目录 (Azure需�?
cp $BACKEND_DEPLOY_DIR/backend/media-service/requirements.txt $BACKEND_DEPLOY_DIR/requirements.txt

# 创建.deployment文件 (指导Azure如何构建)
cat > $BACKEND_DEPLOY_DIR/.deployment << 'EOF'
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
EOF

# 创建部署�?cd $BACKEND_DEPLOY_DIR
BACKEND_ZIP="/tmp/mediagenie-backend.zip"
rm -f $BACKEND_ZIP

echo "创建后端部署�?.."
zip -r $BACKEND_ZIP . -q

echo "上传后端部署包到Azure..."
az webapp deployment source config-zip \
    --name $BACKEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --src $BACKEND_ZIP \
    --output none

print_success "后端代码部署完成"

# 清理临时文件
rm -rf $BACKEND_DEPLOY_DIR
rm -f $BACKEND_ZIP

# ============================================================================
# 步骤 8: 构建前端
# ============================================================================

print_step "步骤 8/11: 构建前端应用"

if [ "$SKIP_FRONTEND_BUILD" = true ]; then
    print_warning "跳过前端构建 (Node.js未安�?"
else
    # 检查前端目录是否存�?    if [ ! -d "frontend" ]; then
        print_error "frontend目录不存�?"
    fi

    cd frontend

    # 创建生产环境配置
    BACKEND_API_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"
    cat > .env.production << EOF
REACT_APP_MEDIA_SERVICE_URL=$BACKEND_API_URL
GENERATE_SOURCEMAP=false
EOF

    echo "前端将连接到: $BACKEND_API_URL"

    # 安装依赖并构�?    echo "安装前端依赖..."
    npm install --silent

    echo "构建前端生产版本..."
    npm run build

    print_success "前端构建完成"
    cd ..
fi

# ============================================================================
# 步骤 9: 创建前端Web App
# ============================================================================

print_step "步骤 9/11: 创建前端Web App"

# 前端使用Node.js静态托�?az webapp create \
    --name $FRONTEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --runtime "NODE:18-lts" \
    --output none

print_success "前端Web App创建成功: $FRONTEND_APP_NAME"

# ============================================================================
# 步骤 10: 部署前端
# ============================================================================

print_step "步骤 10/11: 部署前端代码"

if [ "$SKIP_FRONTEND_BUILD" = true ]; then
    print_warning "跳过前端部署 (未构�?"
else
    echo "准备前端部署�?.."

    # 创建临时部署目录
    FRONTEND_DEPLOY_DIR="/tmp/mediagenie-frontend-deploy"
    rm -rf $FRONTEND_DEPLOY_DIR
    mkdir -p $FRONTEND_DEPLOY_DIR

    # 复制构建产物
    if [ ! -d "frontend/build" ]; then
        print_error "frontend/build目录不存�?构建失败?"
    fi

    cp -r frontend/build/* $FRONTEND_DEPLOY_DIR/

    # 创建静态站点配�?(用于React Router)
    cat > $FRONTEND_DEPLOY_DIR/web.config << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="React Routes" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/" />
        </rule>
      </rules>
    </rewrite>
    <staticContent>
      <mimeMap fileExtension=".json" mimeType="application/json" />
    </staticContent>
  </system.webServer>
</configuration>
EOF

    # 创建部署�?    cd $FRONTEND_DEPLOY_DIR
    FRONTEND_ZIP="/tmp/mediagenie-frontend.zip"
    rm -f $FRONTEND_ZIP

    echo "创建前端部署�?.."
    zip -r $FRONTEND_ZIP . -q

    echo "上传前端部署包到Azure..."
    az webapp deployment source config-zip \
        --name $FRONTEND_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --src $FRONTEND_ZIP \
        --output none

    print_success "前端代码部署完成"

    # 清理临时文件
    rm -rf $FRONTEND_DEPLOY_DIR
    rm -f $FRONTEND_ZIP
fi

# 配置前端HTTPS Only
az webapp update \
    --name $FRONTEND_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --https-only true \
    --output none

# ============================================================================
# 步骤 11: 验证部署
# ============================================================================

print_step "步骤 11/11: 验证部署"

echo "等待应用启动 (可能需�?-3分钟)..."
sleep 45

BACKEND_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"
FRONTEND_URL="https://${FRONTEND_APP_NAME}.azurewebsites.net"
HEALTH_URL="${BACKEND_URL}/health"

echo ""
echo "检查后端健康状�? $HEALTH_URL"

# 尝试访问后端健康检�?MAX_RETRIES=6
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL || echo "000")
    
    if [ "$HTTP_CODE" == "200" ]; then
        print_success "后端健康检查通过 (HTTP 200)"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "后端检查失�?(HTTP $HTTP_CODE), 重试 $RETRY_COUNT/$MAX_RETRIES..."
            sleep 15
        else
            print_warning "后端健康检查超�?请手动验�?
        fi
    fi
done

echo ""
echo "检查前端页�? $FRONTEND_URL"
FRONTEND_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL || echo "000")

if [ "$FRONTEND_HTTP_CODE" == "200" ]; then
    print_success "前端页面可访�?(HTTP 200)"
else
    print_warning "前端访问失败 (HTTP $FRONTEND_HTTP_CODE), 可能需要更多时间启�?
fi

# ============================================================================
# 部署完成
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "�?                   🎉 部署完成!                                    �?
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 部署信息:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  订阅:          $SUBSCRIPTION_NAME"
echo "  资源�?        $RESOURCE_GROUP"
echo "  区域:          $LOCATION"
echo "  定价�?        $SKU"
echo "  计划:          $PLAN_NAME"
echo ""
echo "🌐 Azure Marketplace 要求�?2 �?URL:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  �?前端应用 (主URL):   $FRONTEND_URL"
echo "  🔌 后端API:            $BACKEND_URL"
echo "  📊 API文档:            ${BACKEND_URL}/docs"
echo "  💚 健康检�?           ${BACKEND_URL}/health"
echo ""
echo "🔗 Azure Marketplace 集成端点 (重要!):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 Landing Page URL:   ${BACKEND_URL}/marketplace/landing"
echo "  📡 Connection Webhook: ${BACKEND_URL}/marketplace/webhook"
echo "  📋 订阅管理:           ${BACKEND_URL}/marketplace/subscriptions"
echo "  🔍 Marketplace健康:    ${BACKEND_URL}/marketplace/health"
echo ""
echo "💡 重要提示:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  �?Azure Marketplace Partner Center 中配�?"
echo "  1. Landing Page URL: ${BACKEND_URL}/marketplace/landing"
echo "  2. Connection Webhook: ${BACKEND_URL}/marketplace/webhook"
echo ""
echo "📊 资源详情:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  前端Web App:   $FRONTEND_APP_NAME"
echo "  后端Web App:   $BACKEND_APP_NAME"
echo ""
echo "🔧 管理命令:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  查看后端日志:  az webapp log tail -n $BACKEND_APP_NAME -g $RESOURCE_GROUP"
echo "  查看前端日志:  az webapp log tail -n $FRONTEND_APP_NAME -g $RESOURCE_GROUP"
echo "  重启后端:      az webapp restart -n $BACKEND_APP_NAME -g $RESOURCE_GROUP"
echo "  重启前端:      az webapp restart -n $FRONTEND_APP_NAME -g $RESOURCE_GROUP"
echo "  删除所有资�?  az group delete -n $RESOURCE_GROUP --yes --no-wait"
echo ""
echo "📝 Azure Portal 链接:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  资源�? https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo ""
echo "�?部署成功! 请在浏览器中访问前端URL测试应用�?
echo ""
