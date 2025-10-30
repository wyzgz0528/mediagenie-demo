# 修复 Marketplace Portal 部署问题
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修复 MediaGenie Marketplace Portal 部署" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "步骤 1: 启用自动构建..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group MediaGenie-RG --name mediagenie-marketplace --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true ENABLE_ORYX_BUILD=true --only-show-errors

if ($LASTEXITCODE -eq 0) {
    Write-Host "�?自动构建已启用`n" -ForegroundColor Green
}

Write-Host "步骤 2: 重启应用..." -ForegroundColor Yellow
az webapp restart --resource-group MediaGenie-RG --name mediagenie-marketplace --only-show-errors

if ($LASTEXITCODE -eq 0) {
    Write-Host "�?应用已重启`n" -ForegroundColor Green
}

Write-Host "步骤 3: 等待应用启动 (60 �?..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host "步骤 4: 测试应用..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://mediagenie-marketplace.azurewebsites.net" -UseBasicParsing

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "修复完成�? -ForegroundColor Cyan
Write-Host "访问: https://mediagenie-marketplace.azurewebsites.net" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
