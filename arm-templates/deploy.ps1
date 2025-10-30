# MediaGenie Azure Marketplace 部署脚本 (PowerShell)

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "MediaGenie Azure Marketplace 部署" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 部署配置�? -ForegroundColor Cyan
Write-Host "  资源�? $ResourceGroupName" -ForegroundColor Gray
Write-Host "  位置: $Location" -ForegroundColor Gray
Write-Host ""

# 检查是否已登录 Azure
Write-Host "🔐 检�?Azure 登录状�?.." -ForegroundColor Yellow
try {
    $account = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "未登�?
    }
    Write-Host "�?Azure 登录状态正�? -ForegroundColor Green
} catch {
    Write-Host "�?未登�?Azure，请先运�? az login" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 创建资源�?
Write-Host "📦 创建资源�?.." -ForegroundColor Yellow
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --output table

Write-Host ""

# 部署 ARM 模板
Write-Host "🚀 开始部�?ARM 模板..." -ForegroundColor Yellow
$deploymentName = "mediagenie-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --template-file arm-templates/azuredeploy.json `
    --parameters arm-templates/azuredeploy.parameters.json `
    --output table

Write-Host ""
Write-Host "�?ARM 模板部署完成�? -ForegroundColor Green
Write-Host ""

# 获取输出
Write-Host "📤 获取部署输出..." -ForegroundColor Yellow
$landingPageUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.landingPageUrl.value -o tsv

$webhookUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.webhookUrl.value -o tsv

$frontendUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.frontendUrl.value -o tsv

$marketplaceApp = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.marketplaceAppName.value -o tsv

$backendApp = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.backendAppName.value -o tsv

$storageAccount = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.storageAccountName.value -o tsv

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📊 部署完成�? -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 重要 URL�? -ForegroundColor Yellow
Write-Host "  Landing Page: $landingPageUrl" -ForegroundColor Cyan
Write-Host "  Webhook URL:  $webhookUrl" -ForegroundColor Cyan
Write-Host "  Frontend URL: $frontendUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 资源名称�? -ForegroundColor Yellow
Write-Host "  Marketplace App: $marketplaceApp" -ForegroundColor Gray
Write-Host "  Backend App:     $backendApp" -ForegroundColor Gray
Write-Host "  Storage Account: $storageAccount" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📝 下一步操作：" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 部署 Marketplace Portal 代码�? -ForegroundColor White
Write-Host "   cd marketplace-portal" -ForegroundColor Gray
Write-Host "   Compress-Archive -Path * -DestinationPath ../marketplace-portal.zip -Force" -ForegroundColor Gray
Write-Host "   az webapp deployment source config-zip ``" -ForegroundColor Gray
Write-Host "     --resource-group $ResourceGroupName ``" -ForegroundColor Gray
Write-Host "     --name $marketplaceApp ``" -ForegroundColor Gray
Write-Host "     --src ../marketplace-portal.zip" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 部署 Backend API 代码�? -ForegroundColor White
Write-Host "   cd backend/media-service" -ForegroundColor Gray
Write-Host "   Compress-Archive -Path * -DestinationPath ../../backend-api.zip -Force" -ForegroundColor Gray
Write-Host "   az webapp deployment source config-zip ``" -ForegroundColor Gray
Write-Host "     --resource-group $ResourceGroupName ``" -ForegroundColor Gray
Write-Host "     --name $backendApp ``" -ForegroundColor Gray
Write-Host "     --src ../../backend-api.zip" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 部署 Frontend (React)�? -ForegroundColor White
Write-Host "   cd frontend" -ForegroundColor Gray
Write-Host "   npm install" -ForegroundColor Gray
Write-Host "   `$env:REACT_APP_MEDIA_SERVICE_URL='$webhookUrl'; npm run build" -ForegroundColor Gray
Write-Host "   az storage blob upload-batch ``" -ForegroundColor Gray
Write-Host "     --account-name $storageAccount ``" -ForegroundColor Gray
Write-Host "     --destination '`$web' ``" -ForegroundColor Gray
Write-Host "     --source build/ ``" -ForegroundColor Gray
Write-Host "     --overwrite" -ForegroundColor Gray
Write-Host ""
Write-Host "4. 配置静态网站：" -ForegroundColor White
Write-Host "   az storage blob service-properties update ``" -ForegroundColor Gray
Write-Host "     --account-name $storageAccount ``" -ForegroundColor Gray
Write-Host "     --static-website ``" -ForegroundColor Gray
Write-Host "     --404-document index.html ``" -ForegroundColor Gray
Write-Host "     --index-document index.html" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "�?部署脚本执行完成�? -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 保存输出到文�?
$deploymentInfo = @"
# MediaGenie 部署信息
部署时间: $(Get-Date)
资源�? $ResourceGroupName
位置: $Location

## 重要 URL
- Landing Page: $landingPageUrl
- Webhook URL: $webhookUrl
- Frontend URL: $frontendUrl

## 资源名称
- Marketplace App: $marketplaceApp
- Backend App: $backendApp
- Storage Account: $storageAccount

## Azure Marketplace 提交信息
请在 Partner Center 中使用以�?URL�?
- Landing Page URL: $landingPageUrl
- Connection Webhook: $webhookUrl
"@

$deploymentInfo | Out-File -FilePath "deployment-info.txt" -Encoding UTF8
Write-Host "📄 部署信息已保存到: deployment-info.txt" -ForegroundColor Cyan
