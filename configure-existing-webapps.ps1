# Configure Existing Web Apps for Docker Deployment
# This script configures your existing mediagenie-backend Web App

Write-Host "========================================" -ForegroundColor Green
Write-Host "   Configure Existing Web Apps" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check Azure CLI
Write-Host "[1/5] Checking Azure CLI..." -ForegroundColor Yellow
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Azure CLI not installed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Azure CLI installed" -ForegroundColor Green

# Check login
Write-Host "`n[2/5] Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (!$account) {
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green

# Get ACR credentials
Write-Host "`n[3/5] Getting ACR credentials..." -ForegroundColor Yellow
$acrName = "mediageniecr"
$resourceGroup = "mediagenie-rg"

$acrCreds = az acr credential show --name $acrName --resource-group $resourceGroup 2>$null | ConvertFrom-Json
if (!$acrCreds) {
    Write-Host "[ERROR] ACR not found. Please run quick-deploy.ps1 first" -ForegroundColor Red
    exit 1
}

$acrLoginServer = "$acrName.azurecr.io"
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "[OK] ACR credentials retrieved" -ForegroundColor Green
Write-Host "  Login Server: $acrLoginServer" -ForegroundColor Cyan

# Find existing Web Apps
Write-Host "`n[4/5] Finding existing Web Apps..." -ForegroundColor Yellow

$backendName = "mediagenie-backend"
$frontendName = "mediagenie-frontend"

# Find backend
$backendList = az webapp list --query "[?name=='$backendName']" 2>$null | ConvertFrom-Json
if ($backendList -and $backendList.Count -gt 0) {
    $backendRG = $backendList[0].resourceGroup
    $backendLocation = $backendList[0].location
    Write-Host "[OK] Found backend: $backendName" -ForegroundColor Green
    Write-Host "    Resource Group: $backendRG" -ForegroundColor Cyan
    Write-Host "    Location: $backendLocation" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Backend Web App '$backendName' not found" -ForegroundColor Red
    Write-Host "Please create it first in Azure Portal" -ForegroundColor Yellow
    exit 1
}

# Find or create frontend
$frontendList = az webapp list --query "[?name=='$frontendName']" 2>$null | ConvertFrom-Json
if ($frontendList -and $frontendList.Count -gt 0) {
    $frontendRG = $frontendList[0].resourceGroup
    $frontendLocation = $frontendList[0].location
    Write-Host "[OK] Found frontend: $frontendName" -ForegroundColor Green
    Write-Host "    Resource Group: $frontendRG" -ForegroundColor Cyan
    Write-Host "    Location: $frontendLocation" -ForegroundColor Cyan
} else {
    Write-Host "[WARNING] Frontend Web App '$frontendName' not found" -ForegroundColor Yellow
    Write-Host "Attempting to create it..." -ForegroundColor Yellow
    
    # Try to use the same plan as backend
    $backendPlan = $backendList[0].appServicePlanId.Split('/')[-1]
    Write-Host "  Using App Service Plan: $backendPlan" -ForegroundColor Cyan
    
    az webapp create `
        --name $frontendName `
        --resource-group $backendRG `
        --plan $backendPlan `
        --runtime "NODE:18-lts" `
        --output none 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Frontend Web App created" -ForegroundColor Green
        $frontendRG = $backendRG
    } else {
        Write-Host "[ERROR] Failed to create frontend Web App" -ForegroundColor Red
        Write-Host "Please create it manually in Azure Portal:" -ForegroundColor Yellow
        Write-Host "  1. Go to Azure Portal" -ForegroundColor Yellow
        Write-Host "  2. Create Web App: $frontendName" -ForegroundColor Yellow
        Write-Host "  3. Use same App Service Plan as backend" -ForegroundColor Yellow
        Write-Host "  4. Runtime: Node 18 LTS" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Then run this script again" -ForegroundColor Yellow
        exit 1
    }
}

# Configure Web Apps
Write-Host "`n[5/5] Configuring Web Apps for Docker..." -ForegroundColor Yellow

# Configure backend
Write-Host "  Configuring backend..." -ForegroundColor Yellow
az webapp config container set `
    --name $backendName `
    --resource-group $backendRG `
    --container-image-name "$acrLoginServer/mediagenie-backend:latest" `
    --container-registry-url "https://$acrLoginServer" `
    --container-registry-user $acrUsername `
    --container-registry-password $acrPassword `
    --output none 2>$null

az webapp config appsettings set `
    --name $backendName `
    --resource-group $backendRG `
    --settings WEBSITES_PORT=8000 WEBSITES_ENABLE_APP_SERVICE_STORAGE=false `
    --output none 2>$null

Write-Host "[OK] Backend configured" -ForegroundColor Green

# Configure frontend
Write-Host "  Configuring frontend..." -ForegroundColor Yellow
az webapp config container set `
    --name $frontendName `
    --resource-group $frontendRG `
    --container-image-name "$acrLoginServer/mediagenie-frontend:latest" `
    --container-registry-url "https://$acrLoginServer" `
    --container-registry-user $acrUsername `
    --container-registry-password $acrPassword `
    --output none 2>$null

az webapp config appsettings set `
    --name $frontendName `
    --resource-group $frontendRG `
    --settings WEBSITES_PORT=8080 WEBSITES_ENABLE_APP_SERVICE_STORAGE=false `
    --output none 2>$null

Write-Host "[OK] Frontend configured" -ForegroundColor Green

# Get publish profiles
Write-Host "`n  Getting publish profiles..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles `
    --name $backendName `
    --resource-group $backendRG `
    --xml > backend-publish-profile.xml 2>$null

az webapp deployment list-publishing-profiles `
    --name $frontendName `
    --resource-group $frontendRG `
    --xml > frontend-publish-profile.xml 2>$null

Write-Host "[OK] Publish profiles saved" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n[GitHub Secrets]" -ForegroundColor Yellow
Write-Host "Add these to: https://github.com/wyzgz0528/mediagenie-demo/settings/secrets/actions" -ForegroundColor Cyan
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
Write-Host "   (Copy from: backend-publish-profile.xml)" -ForegroundColor White
Write-Host ""
Write-Host "5. AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   (Copy from: frontend-publish-profile.xml)" -ForegroundColor White

Write-Host "`n[Next Steps]" -ForegroundColor Yellow
Write-Host "1. Add the 5 secrets to GitHub" -ForegroundColor White
Write-Host "2. Go to: https://github.com/wyzgz0528/mediagenie-demo/actions" -ForegroundColor White
Write-Host "3. Run workflow: 'Deploy to Azure Web App'" -ForegroundColor White
Write-Host "4. Wait 5-10 minutes for deployment" -ForegroundColor White

Write-Host "`n[Application URLs]" -ForegroundColor Yellow
Write-Host "  Backend:  https://$backendName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  Frontend: https://$frontendName.azurewebsites.net" -ForegroundColor Cyan

Write-Host "`n[SUCCESS] Ready to deploy!" -ForegroundColor Green
Write-Host ""

