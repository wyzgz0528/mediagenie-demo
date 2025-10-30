#!/bin/bash

# ============================================================================
# MediaGenie Azure 部署脚本 (配额友好版本)
# 使用 F1 (免费) �?S1 (标准) SKU 避免 Basic VM 配额限制
# ============================================================================

set -e

# 颜色输出函数
print_step() {
    echo -e "\033[1;34m━━�?$1 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
}

print_success() {
    echo -e "\033[1;32m�?$1\033[0m"
}

print_error() {
    echo -e "\033[1;31m�?$1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️ $1\033[0m"
}

print_info() {
    echo -e "\033[1;36m💡 $1\033[0m"
}

# 标题
echo -e "\033[1;36m╔════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m�?     MediaGenie Azure 部署 (配额友好�?                            ║\033[0m"
echo -e "\033[1;36m�?     避免 Basic VM 配额限制                                        ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

# ============================================================================
# 配置部分 - 使用配额友好�?SKU
# ============================================================================

# 基础配置
TIMESTAMP=$(date +%m%d%H%M)
RESOURCE_GROUP=${RESOURCE_GROUP:-"mediagenie-rg-$TIMESTAMP"}
LOCATION=${LOCATION:-"East US"}
APP_NAME_PREFIX="mediagenie-$TIMESTAMP"

# SKU 配置 (避免 Basic VM 限制)
# 策略: 使用 F1 (免费) 进行初始部署，然后可选升级到 S1
FRONTEND_SKU="F1"  # 免费�?(不占�?Basic VM 配额)
BACKEND_SKU="S1"   # 标准�?(通常配额更充�?

# App Names
FRONTEND_APP_NAME="${APP_NAME_PREFIX}-web"
BACKEND_APP_NAME="${APP_NAME_PREFIX}-api"
APP_SERVICE_PLAN_FRONTEND="${APP_NAME_PREFIX}-plan-web"
APP_SERVICE_PLAN_BACKEND="${APP_NAME_PREFIX}-plan-api"

print_info "配置信息:"
echo "  资源�? $RESOURCE_GROUP"
echo "  区域: $LOCATION"
echo "  前端SKU: $FRONTEND_SKU (免费�?"
echo "  后端SKU: $BACKEND_SKU (标准�?"
echo ""

# ============================================================================
# 1. 环境检�?# ============================================================================
print_step "步骤 1/11: 环境检�?

# 检�?Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI 未安�?
    exit 1
fi
print_success "Azure CLI 已安�?

# 检查登录状�? 
if ! az account show &> /dev/null; then
    print_error "未登�?Azure，请运行: az login"
    exit 1
fi

SUBSCRIPTION_INFO=$(az account show)
SUBSCRIPTION_ID=$(echo $SUBSCRIPTION_INFO | jq -r '.id')
SUBSCRIPTION_NAME=$(echo $SUBSCRIPTION_INFO | jq -r '.name')
print_success "已登�?Azure"
echo "  订阅: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"

# 检查环境变�?MISSING_VARS=()
if [ -z "$AZURE_OPENAI_KEY" ]; then MISSING_VARS+=("AZURE_OPENAI_KEY"); fi
if [ -z "$AZURE_OPENAI_ENDPOINT" ]; then MISSING_VARS+=("AZURE_OPENAI_ENDPOINT"); fi  
if [ -z "$AZURE_SPEECH_KEY" ]; then MISSING_VARS+=("AZURE_SPEECH_KEY"); fi
if [ -z "$AZURE_SPEECH_REGION" ]; then MISSING_VARS+=("AZURE_SPEECH_REGION"); fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    print_error "缺少环境变量: ${MISSING_VARS[*]}"
    echo "请设�?"
    for var in "${MISSING_VARS[@]}"; do
        echo "  export $var='your-value'"
    done
    exit 1
fi
print_success "环境变量检查通过"

# ============================================================================
# 2. 配额预检�?# ============================================================================
print_step "步骤 2/11: 配额预检�?

# 检�?Microsoft.Web 提供程序
WEB_PROVIDER_STATE=$(az provider show --namespace Microsoft.Web --query registrationState --output tsv)
if [ "$WEB_PROVIDER_STATE" != "Registered" ]; then
    print_warning "Microsoft.Web 提供程序未注册，正在注册..."
    az provider register --namespace Microsoft.Web
    print_success "已触发提供程序注�?
fi

# 检查区域可用�?print_info "检查区�?'$LOCATION' 可用�?.."
LOCATION_VALID=$(az account list-locations --query "[?displayName=='$LOCATION' || name=='$LOCATION']" --output tsv)
if [ -z "$LOCATION_VALID" ]; then
    print_warning "区域 '$LOCATION' 可能不可用，尝试 West US..."
    LOCATION="West US"
fi
print_success "使用区域: $LOCATION"

# 检查现有资�?(避免重复创建)
EXISTING_PLANS=$(az appservice plan list --query "[?location=='$LOCATION' && (sku.tier=='Free' || sku.tier=='Standard')].{name:name, sku:sku.name}" --output json)
if [ "$EXISTING_PLANS" != "[]" ]; then
    print_info "发现现有的可�?App Service Plans:"
    echo "$EXISTING_PLANS" | jq -r '.[] | "  \(.name) - \(.sku)"'
fi

# ============================================================================
# 3. 资源组管�?# ============================================================================  
print_step "步骤 3/11: 资源组管�?

if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_success "资源组已存在: $RESOURCE_GROUP"
else
    print_info "创建资源�? $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
    print_success "资源组创建成�?
fi

# ============================================================================
# 4. 创建前端 App Service Plan (免费�?
# ============================================================================
print_step "步骤 4/11: 创建前端 App Service Plan (免费�?"

print_info "使用 $FRONTEND_SKU SKU (免费层，不占�?Basic VM 配额)"
if az appservice plan show --name "$APP_SERVICE_PLAN_FRONTEND" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_success "前端 App Service Plan 已存�?
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN_FRONTEND" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "$FRONTEND_SKU" \
        --is-linux \
        --output table

    if [ $? -eq 0 ]; then
        print_success "前端 App Service Plan 创建成功 (SKU: $FRONTEND_SKU)"
    else
        print_error "前端 App Service Plan 创建失败"
        print_warning "尝试备选方�?.."
        
        # 备选方�? 尝试其他区域
        for alt_location in "West US" "Central US" "West US 2"; do
            print_info "尝试区域: $alt_location"
            if az appservice plan create \
                --name "$APP_SERVICE_PLAN_FRONTEND" \
                --resource-group "$RESOURCE_GROUP" \
                --location "$alt_location" \
                --sku "$FRONTEND_SKU" \
                --is-linux \
                --output table; then
                print_success "�?$alt_location 创建成功"
                LOCATION="$alt_location"
                break
            fi
        done
    fi
fi

# ============================================================================
# 5. 创建后端 App Service Plan (标准�?
# ============================================================================
print_step "步骤 5/11: 创建后端 App Service Plan (标准�?"

print_info "使用 $BACKEND_SKU SKU (标准层，通常配额更充�?"
if az appservice plan show --name "$APP_SERVICE_PLAN_BACKEND" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_success "后端 App Service Plan 已存�?
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN_BACKEND" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "$BACKEND_SKU" \
        --is-linux \
        --output table

    if [ $? -eq 0 ]; then
        print_success "后端 App Service Plan 创建成功 (SKU: $BACKEND_SKU)"
    else
        print_error "后端 App Service Plan 创建失败"
        print_warning "尝试降级�?F1..."
        
        # 备选方�? 降级到免费层
        az appservice plan create \
            --name "$APP_SERVICE_PLAN_BACKEND" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku "F1" \
            --is-linux \
            --output table
            
        if [ $? -eq 0 ]; then
            print_success "使用 F1 SKU 创建后端 Plan"
            BACKEND_SKU="F1"
        else
            print_error "所�?SKU 都失败，可能需要更换订阅或请求配额"
            exit 1
        fi
    fi
fi

# ============================================================================
# 6-8. Web Apps 创建 (与原版相�?
# ============================================================================
print_step "步骤 6/11: 创建前端 Web App"

if az webapp show --name "$FRONTEND_APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_success "前端 Web App 已存�?
else
    az webapp create \
        --name "$FRONTEND_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN_FRONTEND" \
        --runtime "NODE:18-lts" \
        --output table
    print_success "前端 Web App 创建成功"
fi

print_step "步骤 7/11: 创建后端 Web App"  

if az webapp show --name "$BACKEND_APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_success "后端 Web App 已存�?
else
    az webapp create \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN_BACKEND" \
        --runtime "PYTHON:3.10" \
        --output table
    print_success "后端 Web App 创建成功"
fi

print_step "步骤 8/11: 配置后端环境变量"

az webapp config appsettings set \
    --name "$BACKEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
        AZURE_SPEECH_REGION="$AZURE_SPEECH_REGION" \
        PYTHONPATH="/home/site/wwwroot" \
    --output table

print_success "后端环境变量配置完成"

# ============================================================================
# 9-11. 部署和配�?(与原版相同，但添�?SKU 信息)
# ============================================================================
print_step "步骤 9/11: 部署后端代码"

cd backend
zip -r ../backend-deploy.zip . -x "*.pyc" "*/__pycache__/*" "*.git/*"
cd ..

az webapp deploy \
    --name "$BACKEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src-path backend-deploy.zip \
    --type zip

print_success "后端代码部署完成"

print_step "步骤 10/11: 构建和部署前�?

cd frontend
npm install --production
npm run build
cd ..

az webapp deploy \
    --name "$FRONTEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src-path frontend/build \
    --type static

print_success "前端部署完成"

print_step "步骤 11/11: 配置 CORS"

FRONTEND_URL="https://${FRONTEND_APP_NAME}.azurewebsites.net"
az webapp cors add \
    --name "$BACKEND_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --allowed-origins "$FRONTEND_URL"

print_success "CORS 配置完成"

# ============================================================================
# 部署完成 - 显示结果 (包含 SKU 信息)
# ============================================================================
echo ""
echo -e "\033[1;32m🎉 部署完成！\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

BACKEND_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"
FRONTEND_URL="https://${FRONTEND_APP_NAME}.azurewebsites.net"
LANDING_PAGE_URL="$BACKEND_URL/marketplace/landing"
WEBHOOK_URL="$BACKEND_URL/marketplace/webhook"
HEALTH_URL="$BACKEND_URL/marketplace/health"

echo -e "\033[1;36m🔗 部署的服�?\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m📱 前端应用: $FRONTEND_URL\033[0m"
echo -e "\033[1;37m   SKU: $FRONTEND_SKU ($([ "$FRONTEND_SKU" = "F1" ] && echo "免费�? || echo "付费�?))\033[0m"
echo ""
echo -e "\033[1;32m🔧 后端 API: $BACKEND_URL\033[0m"  
echo -e "\033[1;37m   SKU: $BACKEND_SKU ($([ "$BACKEND_SKU" = "F1" ] && echo "免费�? || echo "标准�?))\033[0m"
echo ""
echo -e "\033[1;33m🏪 Landing Page: $LANDING_PAGE_URL\033[0m"
echo -e "\033[1;33m🔗 Connection Webhook: $WEBHOOK_URL\033[0m"
echo -e "\033[1;37m💓 Health Check: $HEALTH_URL\033[0m"
echo ""

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;33m📋 Partner Center 配置\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo "�?Partner Center 技术配置中填入:"
echo -e "\033[1;36m  Landing page URL: $LANDING_PAGE_URL\033[0m"
echo -e "\033[1;36m  Connection webhook: $WEBHOOK_URL\033[0m"
echo ""

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m" 
echo -e "\033[1;32m💡 配额友好提示\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "\033[1;37m�?使用了配额友好的 SKU 配置:\033[0m"
echo -e "\033[1;37m   �?前端: $FRONTEND_SKU (避免 Basic VM 限制)\033[0m"
echo -e "\033[1;37m   �?后端: $BACKEND_SKU (标准层配额通常更充�?\033[0m"
echo ""
if [ "$FRONTEND_SKU" = "F1" ] || [ "$BACKEND_SKU" = "F1" ]; then
    echo -e "\033[1;33m⚠️  免费层限�?\033[0m"
    echo -e "\033[1;37m   �?每天 60 分钟计算时间\033[0m" 
    echo -e "\033[1;37m   �?1GB 存储空间\033[0m"
    echo -e "\033[1;37m   �?无自定义域名\033[0m"
    echo ""
    echo -e "\033[1;36m💰 升级建议: 生产环境建议升级�?S1 (标准�?\033[0m"
fi

echo ""
echo -e "\033[1;32m�?部署成功完成！避免了 Basic VM 配额限制！\033[0m"

# 清理临时文件
rm -f backend-deploy.zip