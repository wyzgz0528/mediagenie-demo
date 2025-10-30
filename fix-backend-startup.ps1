# MediaGenie Backend 启动修复脚本

Write-Host "🔧 MediaGenie Backend 启动修复..." -ForegroundColor Cyan

$resourceGroup = "mediagenie"
$webAppName = "mediagenie-backend-prod"

# 设置正确的启动命�?Write-Host "🚀 设置启动命令..." -ForegroundColor Yellow
az webapp config set --name $webAppName --resource-group $resourceGroup --startup-file "python -m gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind=0.0.0.0:8000 --timeout 120"

# 设置必要的应用设�?Write-Host "⚙️ 配置应用设置..." -ForegroundColor Yellow
az webapp config appsettings set --name $webAppName --resource-group $resourceGroup --settings `
    "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS=7" `
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" `
    "PYTHONPATH=/home/site/wwwroot"

# 重启应用
Write-Host "🔄 重启应用..." -ForegroundColor Yellow
az webapp restart --name $webAppName --resource-group $resourceGroup

Write-Host "�?配置完成!" -ForegroundColor Green
Write-Host "�?等待应用重启 (30�?..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 测试健康检�?Write-Host "🔍 测试健康检�?.." -ForegroundColor Yellow
try {
    $healthUrl = "https://$webAppName.azurewebsites.net/health"
    $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 30
    Write-Host "�?健康检查成�?" -ForegroundColor Green
    Write-Host "📊 响应: $($response | ConvertTo-Json)" -ForegroundColor White
} catch {
    Write-Host "�?健康检查失�? $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔗 请查看Azure Portal日志: https://portal.azure.com" -ForegroundColor Yellow
}

Write-Host "🔗 测试URL:" -ForegroundColor Yellow
Write-Host "  健康检�? https://$webAppName.azurewebsites.net/health" -ForegroundColor White
Write-Host "  API文档: https://$webAppName.azurewebsites.net/docs" -ForegroundColor White
