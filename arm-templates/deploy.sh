#!/bin/bash
# MediaGenie Azure Marketplace 部署脚本

set -e

echo "=========================================="
echo "MediaGenie Azure Marketplace 部署"
echo "=========================================="
echo ""

# 检查参�?if [ -z "$1" ]; then
    echo "�?错误：请提供资源组名�?
    echo "用法: ./deploy.sh <资源组名�? [位置]"
    exit 1
fi

RESOURCE_GROUP=$1
LOCATION=${2:-"eastus"}

echo "📋 部署配置�?
echo "  资源�? $RESOURCE_GROUP"
echo "  位置: $LOCATION"
echo ""

# 检查是否已登录 Azure
echo "🔐 检�?Azure 登录状�?.."
az account show > /dev/null 2>&1 || {
    echo "�?未登�?Azure，请先运�? az login"
    exit 1
}

echo "�?Azure 登录状态正�?
echo ""

# 创建资源�?echo "📦 创建资源�?.."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

echo ""

# 部署 ARM 模板
echo "🚀 开始部�?ARM 模板..."
DEPLOYMENT_NAME="mediagenie-deployment-$(date +%s)"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --template-file arm-templates/azuredeploy.json \
    --parameters arm-templates/azuredeploy.parameters.json \
    --output table

echo ""
echo "�?ARM 模板部署完成�?
echo ""

# 获取输出
echo "📤 获取部署输出..."
LANDING_PAGE_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.landingPageUrl.value -o tsv)

WEBHOOK_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.webhookUrl.value -o tsv)

FRONTEND_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.frontendUrl.value -o tsv)

MARKETPLACE_APP=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.marketplaceAppName.value -o tsv)

BACKEND_APP=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.backendAppName.value -o tsv)

STORAGE_ACCOUNT=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.storageAccountName.value -o tsv)

echo ""
echo "=========================================="
echo "📊 部署完成�?
echo "=========================================="
echo ""
echo "🌐 重要 URL�?
echo "  Landing Page: $LANDING_PAGE_URL"
echo "  Webhook URL:  $WEBHOOK_URL"
echo "  Frontend URL: $FRONTEND_URL"
echo ""
echo "📦 资源名称�?
echo "  Marketplace App: $MARKETPLACE_APP"
echo "  Backend App:     $BACKEND_APP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo ""
echo "=========================================="
echo "📝 下一步操作："
echo "=========================================="
echo ""
echo "1. 部署 Marketplace Portal 代码�?
echo "   cd marketplace-portal"
echo "   zip -r ../marketplace-portal.zip ."
echo "   az webapp deployment source config-zip \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --name $MARKETPLACE_APP \\"
echo "     --src ../marketplace-portal.zip"
echo ""
echo "2. 部署 Backend API 代码�?
echo "   cd backend/media-service"
echo "   zip -r ../../backend-api.zip ."
echo "   az webapp deployment source config-zip \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --name $BACKEND_APP \\"
echo "     --src ../../backend-api.zip"
echo ""
echo "3. 部署 Frontend (React)�?
echo "   cd frontend"
echo "   npm install"
echo "   REACT_APP_MEDIA_SERVICE_URL=$WEBHOOK_URL npm run build"
echo "   az storage blob upload-batch \\"
echo "     --account-name $STORAGE_ACCOUNT \\"
echo "     --destination '\$web' \\"
echo "     --source build/ \\"
echo "     --overwrite"
echo ""
echo "4. 配置静态网站："
echo "   az storage blob service-properties update \\"
echo "     --account-name $STORAGE_ACCOUNT \\"
echo "     --static-website \\"
echo "     --404-document index.html \\"
echo "     --index-document index.html"
echo ""
echo "=========================================="
echo "�?部署脚本执行完成�?
echo "=========================================="
