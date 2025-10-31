# MediaGenie 快速部署脚本
# 此脚本将自动配置 Azure 资源并准备 GitHub Actions 部署

Write-Host "========================================" -ForegroundColor Green
Write-Host "   MediaGenie 快速部署脚本" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# 检查 Azure CLI
Write-Host "[1/6] 检查 Azure CLI..." -ForegroundColor Yellow
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未安装 Azure CLI" -ForegroundColor Red
    Write-Host "请访问: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Azure CLI 已安装" -ForegroundColor Green

# 检查登录状态
Write-Host "`n[2/6] 检查 Azure 登录状态..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (!$account) {
    Write-Host "未登录 Azure，正在启动登录..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "✓ 已登录为: $($account.user.name)" -ForegroundColor Green
Write-Host "  订阅: $($account.name)" -ForegroundColor Cyan

# 创建 ACR
Write-Host "`n[3/6] 创建 Azure Container Registry..." -ForegroundColor Yellow
$acrName = "mediageniecr"
$resourceGroup = "mediagenie-rg"
$location = "eastus2"

Write-Host "  资源组: $resourceGroup" -ForegroundColor Cyan
Write-Host "  ACR 名称: $acrName" -ForegroundColor Cyan
Write-Host "  位置: $location" -ForegroundColor Cyan

# 检查 ACR 是否已存在
$acrExists = az acr show --name $acrName --resource-group $resourceGroup 2>$null
if ($acrExists) {
    Write-Host "✓ ACR 已存在，跳过创建" -ForegroundColor Green
} else {
    Write-Host "  正在创建 ACR..." -ForegroundColor Yellow
    az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ ACR 创建成功" -ForegroundColor Green
    } else {
        Write-Host "✗ ACR 创建失败" -ForegroundColor Red
        exit 1
    }
}

# 启用管理员账户
Write-Host "  启用管理员账户..." -ForegroundColor Yellow
az acr update --name $acrName --admin-enabled true --output none
Write-Host "✓ 管理员账户已启用" -ForegroundColor Green

# 获取 ACR 凭据
Write-Host "`n[4/6] 获取 ACR 凭据..." -ForegroundColor Yellow
$acrCreds = az acr credential show --name $acrName | ConvertFrom-Json
$acrLoginServer = "$acrName.azurecr.io"
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "✓ ACR 凭据获取成功" -ForegroundColor Green
Write-Host "  登录服务器: $acrLoginServer" -ForegroundColor Cyan
Write-Host "  用户名: $acrUsername" -ForegroundColor Cyan
Write-Host "  密码: $acrPassword" -ForegroundColor Cyan

# 配置 Web App
Write-Host "`n[5/6] 配置 Azure Web App..." -ForegroundColor Yellow

# 后端
Write-Host "  配置后端 Web App..." -ForegroundColor Yellow
az webapp config container set `
    --name mediagenie-backend `
    --resource-group $resourceGroup `
    --docker-custom-image-name "$acrLoginServer/mediagenie-backend:latest" `
    --docker-registry-server-url "https://$acrLoginServer" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword `
    --output none

az webapp config appsettings set `
    --name mediagenie-backend `
    --resource-group $resourceGroup `
    --settings WEBSITES_PORT=8000 `
    --output none

Write-Host "✓ 后端配置完成" -ForegroundColor Green

# 前端
Write-Host "  配置前端 Web App..." -ForegroundColor Yellow
az webapp config container set `
    --name mediagenie-frontend `
    --resource-group $resourceGroup `
    --docker-custom-image-name "$acrLoginServer/mediagenie-frontend:latest" `
    --docker-registry-server-url "https://$acrLoginServer" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword `
    --output none

az webapp config appsettings set `
    --name mediagenie-frontend `
    --resource-group $resourceGroup `
    --settings WEBSITES_PORT=8080 `
    --output none

Write-Host "✓ 前端配置完成" -ForegroundColor Green

# 获取发布配置文件
Write-Host "`n[6/6] 获取发布配置文件..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles `
    --name mediagenie-backend `
    --resource-group $resourceGroup `
    --xml > backend-publish-profile.xml

az webapp deployment list-publishing-profiles `
    --name mediagenie-frontend `
    --resource-group $resourceGroup `
    --xml > frontend-publish-profile.xml

Write-Host "✓ 发布配置文件已保存" -ForegroundColor Green
Write-Host "  后端: backend-publish-profile.xml" -ForegroundColor Cyan
Write-Host "  前端: frontend-publish-profile.xml" -ForegroundColor Cyan

# 完成
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   部署准备完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n📋 GitHub Secrets 配置信息:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "请在 GitHub 仓库中添加以下 Secrets:" -ForegroundColor White
Write-Host "https://github.com/wyzgz0528/mediagenie-demo/settings/secrets/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ACR_LOGIN_SERVER" -ForegroundColor Yellow
Write-Host "   $acrLoginServer" -ForegroundColor White
Write-Host ""
Write-Host "2. ACR_USERNAME" -ForegroundColor Yellow
Write-Host "   $acrUsername" -ForegroundColor White
Write-Host ""
Write-Host "3. ACR_PASSWORD" -ForegroundColor Yellow
Write-Host "   $acrPassword" -ForegroundColor White
Write-Host ""
Write-Host "4. AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   (复制 backend-publish-profile.xml 的完整内容)" -ForegroundColor White
Write-Host ""
Write-Host "5. AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   (复制 frontend-publish-profile.xml 的完整内容)" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📝 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 打开 GitHub 仓库设置页面" -ForegroundColor White
Write-Host "2. 添加上述 5 个 Secrets" -ForegroundColor White
Write-Host "3. 进入 Actions 标签，手动触发工作流" -ForegroundColor White
Write-Host "4. 等待部署完成（约 5-10 分钟）" -ForegroundColor White
Write-Host "5. 访问应用验证部署" -ForegroundColor White

Write-Host "`n🌐 应用 URL:" -ForegroundColor Yellow
Write-Host "  后端: https://mediagenie-backend.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  前端: https://mediagenie-frontend.azurewebsites.net" -ForegroundColor Cyan

Write-Host "`n✨ 部署准备完成！祝你好运！" -ForegroundColor Green
Write-Host ""

