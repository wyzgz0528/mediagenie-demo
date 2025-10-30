#!/bin/bash
# MediaGenie Azure Marketplace 快速手动部署脚�?# 适用于解�?Cloud Shell 超时问题

set -e

# ====================================
# 配置�?- 请修改以下参�?# ====================================
RESOURCE_GROUP="MediaGenie-Marketplace-RG"
LOCATION="eastus"
APP_NAME_PREFIX="mediagenie"
SKU="B1"

# Azure AI 服务配置 (必填)
AZURE_OPENAI_ENDPOINT="https://your-endpoint.openai.azure.com"
AZURE_OPENAI_KEY="your-openai-key"
AZURE_OPENAI_DEPLOYMENT="gpt-4"
AZURE_SPEECH_KEY="your-speech-key"
AZURE_SPEECH_REGION="eastus"
AZURE_VISION_ENDPOINT="https://your-vision.cognitiveservices.azure.com"
AZURE_VISION_KEY="your-vision-key"

# ====================================
# 函数定义
# ====================================
print_step() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_success() {
    echo "�?$1"
}

print_info() {
    echo "ℹ️  $1"
}

print_error() {
    echo "�?$1"
}

# ====================================
# 步骤 0: 检查前提条�?# ====================================
print_step "步骤 0: 检查环�?

# 检�?Azure CLI
if ! command -v az &> /dev/null; then
    print_error "未安�?Azure CLI,请访�? https://aka.ms/azure-cli"
    exit 1
fi
print_success "Azure CLI 已安�?

# 检查登录状�?if ! az account show &> /dev/null; then
    print_error "未登�?Azure,请运�? az login"
    exit 1
fi
print_success "Azure 登录正常"

# 检查部署包
if [ ! -d "deploy" ]; then
    print_error "未找�?deploy 目录,请先运行: ./build-deployment-packages.ps1"
    exit 1
fi

if [ ! -f "deploy/marketplace-portal.zip" ] || [ ! -f "deploy/backend-api.zip" ]; then
    print_error "部署包不完整,请重新运行构建脚�?
    exit 1
fi
print_success "部署包完�?

# 显示配置
print_info "资源�? $RESOURCE_GROUP"
print_info "位置: $LOCATION"
print_info "应用前缀: $APP_NAME_PREFIX"

# ====================================
# 步骤 1: 创建资源�?# ====================================
print_step "步骤 1: 创建资源�?

if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_info "资源组已存在,跳过创建"
else
    az group create \
      --name "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --output table
    print_success "资源组创建完�?
fi

# ====================================
# 步骤 2: 部署 ARM 模板
# ====================================
print_step "步骤 2: 部署基础设施 (ARM 模板)"

print_info "正在部署 App Service Plan, Web Apps, Storage Account..."
print_info "预计耗时: 3-5 分钟"

DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file deploy/azuredeploy-optimized.json \
  --parameters \
    appNamePrefix="$APP_NAME_PREFIX" \
    location="$LOCATION" \
    appServicePlanSku="$SKU" \
    azureOpenAIEndpoint="$AZURE_OPENAI_ENDPOINT" \
    azureOpenAIKey="$AZURE_OPENAI_KEY" \
    azureOpenAIDeployment="$AZURE_OPENAI_DEPLOYMENT" \
    azureSpeechKey="$AZURE_SPEECH_KEY" \
    azureSpeechRegion="$AZURE_SPEECH_REGION" \
    azureComputerVisionEndpoint="$AZURE_VISION_ENDPOINT" \
    azureComputerVisionKey="$AZURE_VISION_KEY" \
  --query 'properties.outputs' \
  --output json)

if [ $? -ne 0 ]; then
    print_error "ARM 模板部署失败"
    exit 1
fi

# 提取输出
PORTAL_APP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.marketplaceAppName.value')
BACKEND_APP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.backendAppName.value')
STORAGE_ACCOUNT=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.storageAccountName.value')
LANDING_PAGE_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.landingPageUrl.value')
WEBHOOK_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.webhookUrl.value')
FRONTEND_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendUrl.value')

print_success "基础设施部署完成"
echo ""
echo "📋 资源信息:"
echo "   Marketplace Portal App: $PORTAL_APP"
echo "   Backend API App: $BACKEND_APP"
echo "   Storage Account: $STORAGE_ACCOUNT"
echo ""

# ====================================
# 步骤 3: 部署 Marketplace Portal
# ====================================
print_step "步骤 3: 部署 Marketplace Portal"

print_info "上传 marketplace-portal.zip..."

az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PORTAL_APP" \
  --src-path deploy/marketplace-portal.zip \
  --type zip \
  --restart true \
  --timeout 600

if [ $? -ne 0 ]; then
    print_error "Marketplace Portal 部署失败,尝试使用 Kudu..."
    print_info "请手动上传到: https://$PORTAL_APP.scm.azurewebsites.net/ZipDeployUI"
else
    print_success "Marketplace Portal 部署完成"
fi

# ====================================
# 步骤 4: 部署 Backend API
# ====================================
print_step "步骤 4: 部署 Backend API"

print_info "上传 backend-api.zip..."

az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$BACKEND_APP" \
  --src-path deploy/backend-api.zip \
  --type zip \
  --restart true \
  --timeout 600

if [ $? -ne 0 ]; then
    print_error "Backend API 部署失败,尝试使用 Kudu..."
    print_info "请手动上传到: https://$BACKEND_APP.scm.azurewebsites.net/ZipDeployUI"
else
    print_success "Backend API 部署完成"
fi

# ====================================
# 步骤 5: 部署前端静态网�?# ====================================
if [ -f "deploy/frontend-build.zip" ]; then
    print_step "步骤 5: 部署前端静态网�?
    
    # 解压前端构建
    print_info "解压前端构建..."
    rm -rf deploy/frontend-build
    unzip -q deploy/frontend-build.zip -d deploy/frontend-build
    
    # 启用静态网�?    print_info "启用 Storage Account 静态网站托�?.."
    az storage blob service-properties update \
      --account-name "$STORAGE_ACCOUNT" \
      --static-website \
      --index-document index.html \
      --404-document index.html
    
    # 上传文件
    print_info "上传前端文件..."
    az storage blob upload-batch \
      --account-name "$STORAGE_ACCOUNT" \
      --destination '$web' \
      --source deploy/frontend-build \
      --overwrite
    
    print_success "前端部署完成"
else
    print_info "未找到前端构�?跳过前端部署"
fi

# ====================================
# 步骤 6: 验证部署
# ====================================
print_step "步骤 6: 验证部署"

print_info "等待应用启动 (30�?..."
sleep 30

# 验证 Marketplace Portal
print_info "验证 Marketplace Portal..."
if curl -s -o /dev/null -w "%{http_code}" "$LANDING_PAGE_URL" | grep -q "200\|302"; then
    print_success "Marketplace Portal 运行正常"
else
    print_error "Marketplace Portal 可能未正常启�?请查看日�?
    print_info "查看日志: az webapp log tail --resource-group $RESOURCE_GROUP --name $PORTAL_APP"
fi

# 验证 Backend API
print_info "验证 Backend API..."
if curl -s -o /dev/null -w "%{http_code}" "https://$BACKEND_APP.azurewebsites.net/health" | grep -q "200"; then
    print_success "Backend API 运行正常"
else
    print_error "Backend API 可能未正常启�?请查看日�?
    print_info "查看日志: az webapp log tail --resource-group $RESOURCE_GROUP --name $BACKEND_APP"
fi

# ====================================
# 完成
# ====================================
print_step "部署完成"

echo ""
echo "🎉 MediaGenie 已成功部署到 Azure!"
echo ""
echo "📋 关键信息 (请保�?:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Landing Page URL: $LANDING_PAGE_URL"
echo "Webhook URL: $WEBHOOK_URL"
echo "Frontend URL: $FRONTEND_URL"
echo "Backend API: https://$BACKEND_APP.azurewebsites.net"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 下一�?"
echo "   1. 在浏览器中打开 Landing Page URL 测试"
echo "   2. �?Azure Marketplace Portal 中配置上�?URL"
echo "   3. 测试所有功�?语音转写、TTS、GPT、图像分�?"
echo ""
echo "🔧 故障排查:"
echo "   查看 Portal 日志: az webapp log tail -g $RESOURCE_GROUP -n $PORTAL_APP"
echo "   查看 Backend 日志: az webapp log tail -g $RESOURCE_GROUP -n $BACKEND_APP"
echo ""
echo "💰 成本提示:"
echo "   当前配置 ($SKU) 预估费用: ~\$13.50/�?
echo "   不使用时可停�?App Service 以节省成�?
echo ""
