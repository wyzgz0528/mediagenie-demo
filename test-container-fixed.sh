#!/bin/bash

# 容器测试脚本 - 修复版本
# 解决 osType 参数问题

# 设置变量
TIMESTAMP=$(date +%m%d%H%M)
RESOURCE_GROUP="test-container-$TIMESTAMP"

echo "=== Azure 容器实例测试 (修复版本) ==="
echo "时间�? $TIMESTAMP"
echo "资源�? $RESOURCE_GROUP"

# 创建资源�?echo "1. 创建资源�?.."
az group create --name "$RESOURCE_GROUP" --location "East US"

# 测试创建容器 (修复 osType 参数)
echo "2. 创建测试容器..."
az container create \
    --resource-group "$RESOURCE_GROUP" \
    --name "quota-test-$TIMESTAMP" \
    --image "nginx:latest" \
    --dns-name-label "quota-test-$TIMESTAMP" \
    --ports 80 \
    --os-type Linux \
    --cpu 1 \
    --memory 1.5

# 检查创建状�?echo "3. 检查容器状�?.."
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "quota-test-$TIMESTAMP" \
    --query "{name:name,provisioningState:provisioningState,fqdn:ipAddress.fqdn}" \
    --output table

# 如果成功，输出测�?URL
echo ""
echo "�?测试容器 URL: http://quota-test-$TIMESTAMP.eastus.azurecontainer.io"
echo ""
echo "如果容器创建成功，说明您的订阅支�?Azure 容器实例�?
echo "可以继续部署 MediaGenie 项目�?
echo ""
echo "清理测试资源 (可�?:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"