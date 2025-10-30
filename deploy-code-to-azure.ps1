# Deploy code to Azure Web Apps
# Usage: .\deploy-code-to-azure.ps1

param(
    [string]$ResourceGroup = "mediagenie-rg",
    [string]$BackendAppName = "mediagenie-backend",
    [string]$FrontendAppName = "mediagenie-frontend"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Code to Azure" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Check if packages exist
Write-Host "[1/4] Checking deployment packages..." -ForegroundColor Yellow

if (-not (Test-Path "backend-deploy.zip")) {
    Write-Host "ERROR: backend-deploy.zip not found" -ForegroundColor Red
    Write-Host "Run prepare-deployment-packages.ps1 first" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: backend-deploy.zip found" -ForegroundColor Green

if (-not (Test-Path "frontend-deploy.zip")) {
    Write-Host "ERROR: frontend-deploy.zip not found" -ForegroundColor Red
    Write-Host "Run prepare-deployment-packages.ps1 first" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: frontend-deploy.zip found" -ForegroundColor Green

# Deploy backend
Write-Host "[2/4] Deploying backend code..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $BackendAppName `
    --src backend-deploy.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Backend deployed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1
}

# Deploy frontend
Write-Host "[3/4] Deploying frontend code..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $FrontendAppName `
    --src frontend-deploy.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Frontend deployed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Frontend deployment failed" -ForegroundColor Red
    exit 1
}

# Restart apps
Write-Host "[4/4] Restarting applications..." -ForegroundColor Yellow
az webapp restart --resource-group $ResourceGroup --name $BackendAppName
az webapp restart --resource-group $ResourceGroup --name $FrontendAppName
Write-Host "OK: Applications restarted" -ForegroundColor Green

# Summary
Write-Host "" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend: https://$BackendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for apps to start" -ForegroundColor White
Write-Host "2. Check backend health: https://$BackendAppName.azurewebsites.net/health" -ForegroundColor White
Write-Host "3. Check frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "4. Configure Azure AD settings" -ForegroundColor White
Write-Host "5. Test the application" -ForegroundColor White

