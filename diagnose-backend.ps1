# MediaGenie Backend 诊断脚本

Write-Host "🔍 MediaGenie Backend 诊断开�?.." -ForegroundColor Cyan

$resourceGroup = "mediagenie"
$webAppName = "mediagenie-backend-prod"

# 检查Web App状�?Write-Host "📊 检查Web App状�?.." -ForegroundColor Yellow
az webapp show --name $webAppName --resource-group $resourceGroup --query "{name:name,state:state,defaultHostName:defaultHostName}" --output table

# 检查应用设�?Write-Host "⚙️ 检查应用设�?.." -ForegroundColor Yellow
az webapp config appsettings list --name $webAppName --resource-group $resourceGroup --query "[?name=='SCM_DO_BUILD_DURING_DEPLOYMENT' || name=='WEBSITE_HTTPLOGGING_RETENTION_DAYS']" --output table

# 检查启动命�?Write-Host "🚀 检查启动命�?.." -ForegroundColor Yellow
az webapp config show --name $webAppName --resource-group $resourceGroup --query "appCommandLine" --output tsv

# 检查Python版本配置
Write-Host "🐍 检查Python配置..." -ForegroundColor Yellow
az webapp config show --name $webAppName --resource-group $resourceGroup --query "linuxFxVersion" --output tsv

# 获取最近的日志
Write-Host "📋 获取最近的日志..." -ForegroundColor Yellow
Write-Host "请在Azure Portal中查看Log stream获取详细错误信息" -ForegroundColor White
Write-Host "Portal地址: https://portal.azure.com" -ForegroundColor White

Write-Host "🔗 测试URL:" -ForegroundColor Yellow
Write-Host "  健康检�? https://$webAppName.azurewebsites.net/health" -ForegroundColor White
Write-Host "  API文档: https://$webAppName.azurewebsites.net/docs" -ForegroundColor White
Write-Host "  根路�? https://$webAppName.azurewebsites.net/" -ForegroundColor White
