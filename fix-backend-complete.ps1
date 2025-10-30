# MediaGenie Backend 完整修复脚本

Write-Host "🔧 MediaGenie Backend 完整修复开�?.." -ForegroundColor Cyan

$resourceGroup = "mediagenie"
$webAppName = "mediagenie-backend-prod"

# 1. 检查当前配�?Write-Host "🔍 检查当前配�?.." -ForegroundColor Yellow
Write-Host "Web App状�?" -ForegroundColor White
az webapp show --name $webAppName --resource-group $resourceGroup --query "{name:name,state:state,defaultHostName:defaultHostName}" --output table

Write-Host "当前启动命令:" -ForegroundColor White
$currentStartup = az webapp config show --name $webAppName --resource-group $resourceGroup --query "appCommandLine" --output tsv
Write-Host "  $currentStartup" -ForegroundColor Gray

Write-Host "Python版本:" -ForegroundColor White
$pythonVersion = az webapp config show --name $webAppName --resource-group $resourceGroup --query "linuxFxVersion" --output tsv
Write-Host "  $pythonVersion" -ForegroundColor Gray

# 2. 设置正确的Python版本
Write-Host "🐍 设置Python版本..." -ForegroundColor Yellow
az webapp config set --name $webAppName --resource-group $resourceGroup --linux-fx-version "PYTHON|3.11"

# 3. 配置应用设置
Write-Host "⚙️ 配置应用设置..." -ForegroundColor Yellow
az webapp config appsettings set --name $webAppName --resource-group $resourceGroup --settings `
    "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
    "ENABLE_ORYX_BUILD=true" `
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS=7" `
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" `
    "PYTHONPATH=/home/site/wwwroot" `
    "PORT=8000"

# 4. 设置启动命令 - 使用更简单的方式
Write-Host "🚀 设置启动命令..." -ForegroundColor Yellow
az webapp config set --name $webAppName --resource-group $resourceGroup --startup-file "python -m uvicorn main:app --host 0.0.0.0 --port 8000"

# 5. 重启应用
Write-Host "🔄 重启应用..." -ForegroundColor Yellow
az webapp restart --name $webAppName --resource-group $resourceGroup

Write-Host "�?配置完成!" -ForegroundColor Green
Write-Host "�?等待应用启动 (60�?..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# 6. 测试连接
Write-Host "🔍 测试应用..." -ForegroundColor Yellow

# 测试根路�?try {
    $rootUrl = "https://$webAppName.azurewebsites.net/"
    Write-Host "测试根路�? $rootUrl" -ForegroundColor White
    $rootResponse = Invoke-WebRequest -Uri $rootUrl -TimeoutSec 30 -UseBasicParsing
    Write-Host "�?根路径响�? $($rootResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "�?根路径失�? $($_.Exception.Message)" -ForegroundColor Red
}

# 测试健康检�?try {
    $healthUrl = "https://$webAppName.azurewebsites.net/health"
    Write-Host "测试健康检�? $healthUrl" -ForegroundColor White
    $healthResponse = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 30
    Write-Host "�?健康检查成�?" -ForegroundColor Green
    Write-Host "📊 响应: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor White
} catch {
    Write-Host "�?健康检查失�? $($_.Exception.Message)" -ForegroundColor Red
}

# 7. 显示有用信息
Write-Host "" -ForegroundColor White
Write-Host "🔗 测试URL:" -ForegroundColor Yellow
Write-Host "  根路�? https://$webAppName.azurewebsites.net/" -ForegroundColor White
Write-Host "  健康检�? https://$webAppName.azurewebsites.net/health" -ForegroundColor White
Write-Host "  API文档: https://$webAppName.azurewebsites.net/docs" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "📋 如果还是不工作，请查看Azure Portal日志:" -ForegroundColor Yellow
Write-Host "  1. 打开 https://portal.azure.com" -ForegroundColor White
Write-Host "  2. 找到 $webAppName" -ForegroundColor White
Write-Host "  3. 点击 'Log stream' 查看详细错误" -ForegroundColor White
