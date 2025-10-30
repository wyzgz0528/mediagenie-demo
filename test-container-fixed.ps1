# PowerShell 版本 - 容器测试脚本

# 设置变量
$timestamp = Get-Date -Format "MMddHHmm"
$resourceGroup = "test-container-$timestamp"

Write-Host "=== Azure 容器实例测试 (PowerShell 版本) ===" -ForegroundColor Green
Write-Host "时间�? $timestamp" -ForegroundColor Yellow
Write-Host "资源�? $resourceGroup" -ForegroundColor Yellow

# 创建资源�?
Write-Host "1. 创建资源�?.." -ForegroundColor Cyan
az group create --name $resourceGroup --location "East US"

# 测试创建容器 (修复 osType 参数)
Write-Host "2. 创建测试容器..." -ForegroundColor Cyan
az container create `
    --resource-group $resourceGroup `
    --name "quota-test-$timestamp" `
    --image "nginx:latest" `
    --dns-name-label "quota-test-$timestamp" `
    --ports 80 `
    --os-type Linux `
    --cpu 1 `
    --memory 1.5

# 检查创建状�?
Write-Host "3. 检查容器状�?.." -ForegroundColor Cyan
az container show `
    --resource-group $resourceGroup `
    --name "quota-test-$timestamp" `
    --query "{name:name,provisioningState:provisioningState,fqdn:ipAddress.fqdn}" `
    --output table

# 输出测试结果
Write-Host ""
Write-Host "�?测试容器 URL: http://quota-test-$timestamp.eastus.azurecontainer.io" -ForegroundColor Green
Write-Host ""
Write-Host "如果容器创建成功，说明您的订阅支�?Azure 容器实例�? -ForegroundColor Green
Write-Host "可以继续部署 MediaGenie 项目�? -ForegroundColor Green
Write-Host ""
Write-Host "清理测试资源 (可�?:" -ForegroundColor Yellow
Write-Host "az group delete --name $resourceGroup --yes --no-wait" -ForegroundColor White