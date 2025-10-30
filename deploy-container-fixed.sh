# MediaGenie 容器部署脚本 - 修复版本
# 解决 osType 参数问题和优化配�?
#!/bin/bash

# 设置变量
TIMESTAMP=$(date +%m%d%H%M)
RESOURCE_GROUP="mediagenie-container-$TIMESTAMP"
CONTAINER_NAME="mediagenie-$TIMESTAMP"

# Azure 配置
SUBSCRIPTION_ID="296c69fb-e5f2-4063-b505-16b606eced30"
LOCATION="East US"

# 环境变量 (请替换为您的实际�?
AZURE_OPENAI_API_KEY="your-openai-key-here"
AZURE_OPENAI_ENDPOINT="https://your-openai-resource.openai.azure.com/"
AZURE_SPEECH_KEY="your-speech-key-here"
AZURE_SPEECH_REGION="eastus"
AZURE_VISION_KEY="your-vision-key-here" 
AZURE_VISION_ENDPOINT="https://your-vision-resource.cognitiveservices.azure.com/"

echo "=== MediaGenie Azure 容器部署 (修复版本) ==="
echo "时间�? $TIMESTAMP"
echo "资源�? $RESOURCE_GROUP"
echo "容器�? $CONTAINER_NAME"

# 1. 设置订阅
echo "1. 设置 Azure 订阅..."
az account set --subscription "$SUBSCRIPTION_ID"

# 2. 创建资源�?echo "2. 创建资源�?.."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# 3. 创建容器实例 (修复 osType 参数)
echo "3. 创建 MediaGenie 容器..."
az container create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_NAME" \
    --image "python:3.10-slim" \
    --dns-name-label "mediagenie-$TIMESTAMP" \
    --ports 8000 \
    --os-type Linux \
    --cpu 2 \
    --memory 4 \
    --environment-variables \
        AZURE_OPENAI_API_KEY="$AZURE_OPENAI_API_KEY" \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
        AZURE_SPEECH_REGION="$AZURE_SPEECH_REGION" \
        AZURE_VISION_KEY="$AZURE_VISION_KEY" \
        AZURE_VISION_ENDPOINT="$AZURE_VISION_ENDPOINT" \
        PORT="8000" \
    --command-line "bash -c 'apt-get update && apt-get install -y git && git clone https://github.com/your-repo/MediaGenie.git /app && cd /app && pip install -r requirements.txt && python -m uvicorn main:app --host 0.0.0.0 --port 8000'"

# 4. 检查部署状�?echo "4. 检查部署状�?.."
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_NAME" \
    --query "{name:name,provisioningState:provisioningState,fqdn:ipAddress.fqdn,restartCount:containers[0].instanceView.restartCount}" \
    --output table

# 5. 获取容器日志
echo "5. 获取容器启动日志..."
az container logs \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_NAME"

# 6. 输出访问信息
echo ""
echo "=== 部署完成 ==="
echo "�?MediaGenie API: http://mediagenie-$TIMESTAMP.eastus.azurecontainer.io:8000"
echo "�?健康检�? http://mediagenie-$TIMESTAMP.eastus.azurecontainer.io:8000/health"
echo "�?Marketplace 页面: http://mediagenie-$TIMESTAMP.eastus.azurecontainer.io:8000/marketplace/landing"
echo ""
echo "监控命令:"
echo "az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo ""
echo "清理资源:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"