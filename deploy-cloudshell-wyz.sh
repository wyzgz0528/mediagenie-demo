#!/bin/bash
# MediaGenie 部署脚本 - 用于 Azure Cloud Shell (WYZ 订阅)
# 使用方法: �?Azure Cloud Shell (https://shell.azure.com) 中运行此脚本

set -e

echo "=========================================="
echo "MediaGenie Azure 部署脚本"
echo "目标订阅: WYZ"
echo "=========================================="

# 设置订阅
echo "步骤 1/4: 设置订阅..."
az account set --subscription "WYZ"
az account show --query "{Name:name, ID:id}" -o table

# 创建资源组（如果已存在则跳过�?echo -e "\n步骤 2/4: 创建资源�?.."
az group create \
  --name MediaGenie-RG \
  --location eastus \
  --output table

# 部署 ARM 模板
echo -e "\n步骤 3/4: 部署 ARM 模板..."
DEPLOYMENT_NAME="mediagenie-$(date +%Y%m%d%H%M%S)"

az deployment group create \
  --resource-group MediaGenie-RG \
  --name "$DEPLOYMENT_NAME" \
  --template-file azuredeploy-v2.json \
  --parameters appNamePrefix=mediagenie location=eastus sku=B1 \
  --output table

# 获取输出
echo -e "\n步骤 4/4: 获取部署输出..."
az deployment group show \
  --resource-group MediaGenie-RG \
  --name "$DEPLOYMENT_NAME" \
  --query "{MarketplaceApp:properties.outputs.marketplaceAppName.value, BackendApp:properties.outputs.backendAppName.value, StorageAccount:properties.outputs.storageAccountName.value, LandingPageURL:properties.outputs.landingPageUrl.value, WebhookURL:properties.outputs.webhookUrl.value, FrontendURL:properties.outputs.frontendUrl.value}" \
  --output table

echo -e "\n=========================================="
echo "部署完成�?
echo "=========================================="
echo "请保存上面的输出信息，特别是�?
echo "- Landing Page URL (用于 Azure Marketplace)"
echo "- Webhook URL (用于 Azure Marketplace)"
echo "=========================================="
