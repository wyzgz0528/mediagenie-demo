# MediaGenie Quick Deploy Script
# This script will automatically configure Azure resources and prepare GitHub Actions deployment

Write-Host "========================================" -ForegroundColor Green
Write-Host "   MediaGenie Quick Deploy Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check Azure CLI
Write-Host "[1/6] Checking Azure CLI..." -ForegroundColor Yellow
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Azure CLI not installed" -ForegroundColor Red
    Write-Host "Please visit: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Azure CLI installed" -ForegroundColor Green

# Check login status
Write-Host "`n[2/6] Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (!$account) {
    Write-Host "Not logged in to Azure, starting login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "  Subscription: $($account.name)" -ForegroundColor Cyan

# Create Resource Group
Write-Host "`n[3/6] Checking/Creating Resource Group..." -ForegroundColor Yellow
$resourceGroup = "mediagenie-rg"
$location = "eastus2"

Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Cyan
Write-Host "  Location: $location" -ForegroundColor Cyan

# Check if resource group exists
$rgExists = az group show --name $resourceGroup 2>$null
if ($rgExists) {
    Write-Host "[OK] Resource group already exists" -ForegroundColor Green
} else {
    Write-Host "  Creating resource group..." -ForegroundColor Yellow
    az group create --name $resourceGroup --location $location --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Resource group created successfully" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Resource group creation failed" -ForegroundColor Red
        exit 1
    }
}

# Create ACR
Write-Host "`n[4/6] Creating Azure Container Registry..." -ForegroundColor Yellow
$acrName = "mediageniecr"

Write-Host "  ACR Name: $acrName" -ForegroundColor Cyan

# Check if ACR already exists
$acrExists = az acr show --name $acrName --resource-group $resourceGroup 2>$null
if ($acrExists) {
    Write-Host "[OK] ACR already exists, skipping creation" -ForegroundColor Green
} else {
    Write-Host "  Creating ACR..." -ForegroundColor Yellow
    az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] ACR created successfully" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] ACR creation failed" -ForegroundColor Red
        exit 1
    }
}

# Enable admin account
Write-Host "  Enabling admin account..." -ForegroundColor Yellow
az acr update --name $acrName --admin-enabled true --output none
Write-Host "[OK] Admin account enabled" -ForegroundColor Green

# Get ACR credentials
Write-Host "`n[5/6] Getting ACR credentials..." -ForegroundColor Yellow
$acrCreds = az acr credential show --name $acrName | ConvertFrom-Json
$acrLoginServer = "$acrName.azurecr.io"
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "[OK] ACR credentials retrieved" -ForegroundColor Green
Write-Host "  Login Server: $acrLoginServer" -ForegroundColor Cyan
Write-Host "  Username: $acrUsername" -ForegroundColor Cyan
Write-Host "  Password: $acrPassword" -ForegroundColor Cyan

# Create Web Apps if they don't exist
Write-Host "`n[6/7] Checking/Creating Azure Web Apps..." -ForegroundColor Yellow

# Check backend web app
$backendExists = az webapp show --name mediagenie-backend --resource-group $resourceGroup 2>$null
if ($backendExists) {
    Write-Host "[OK] Backend Web App already exists" -ForegroundColor Green
} else {
    Write-Host "  Creating backend Web App..." -ForegroundColor Yellow
    # Create App Service Plan first
    $planExists = az appservice plan show --name mediagenie-plan --resource-group $resourceGroup 2>$null
    if (!$planExists) {
        Write-Host "  Creating App Service Plan..." -ForegroundColor Yellow
        az appservice plan create --name mediagenie-plan --resource-group $resourceGroup --location $location --sku B1 --is-linux --output none
    }
    # Create Web App
    az webapp create --name mediagenie-backend --resource-group $resourceGroup --plan mediagenie-plan --runtime "PYTHON:3.11" --output none
    Write-Host "[OK] Backend Web App created" -ForegroundColor Green
}

# Check frontend web app
$frontendExists = az webapp show --name mediagenie-frontend --resource-group $resourceGroup 2>$null
if ($frontendExists) {
    Write-Host "[OK] Frontend Web App already exists" -ForegroundColor Green
} else {
    Write-Host "  Creating frontend Web App..." -ForegroundColor Yellow
    # Create App Service Plan if not exists
    $planExists = az appservice plan show --name mediagenie-plan --resource-group $resourceGroup 2>$null
    if (!$planExists) {
        Write-Host "  Creating App Service Plan..." -ForegroundColor Yellow
        az appservice plan create --name mediagenie-plan --resource-group $resourceGroup --location $location --sku B1 --is-linux --output none
    }
    # Create Web App
    az webapp create --name mediagenie-frontend --resource-group $resourceGroup --plan mediagenie-plan --runtime "NODE:18-lts" --output none
    Write-Host "[OK] Frontend Web App created" -ForegroundColor Green
}

# Configure Web App
Write-Host "`n[7/8] Configuring Azure Web Apps for Docker..." -ForegroundColor Yellow

# Backend
Write-Host "  Configuring backend Web App..." -ForegroundColor Yellow
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

Write-Host "[OK] Backend configured" -ForegroundColor Green

# Frontend
Write-Host "  Configuring frontend Web App..." -ForegroundColor Yellow
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

Write-Host "[OK] Frontend configured" -ForegroundColor Green

# Get publish profiles
Write-Host "`n[8/8] Getting publish profiles..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles `
    --name mediagenie-backend `
    --resource-group $resourceGroup `
    --xml > backend-publish-profile.xml

az webapp deployment list-publishing-profiles `
    --name mediagenie-frontend `
    --resource-group $resourceGroup `
    --xml > frontend-publish-profile.xml

Write-Host "[OK] Publish profiles saved" -ForegroundColor Green
Write-Host "  Backend: backend-publish-profile.xml" -ForegroundColor Cyan
Write-Host "  Frontend: frontend-publish-profile.xml" -ForegroundColor Cyan

# Complete
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Deployment Preparation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n[GitHub Secrets Configuration]" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""
Write-Host "Please add the following Secrets to your GitHub repository:" -ForegroundColor White
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
Write-Host "   (Copy the complete content of backend-publish-profile.xml)" -ForegroundColor White
Write-Host ""
Write-Host "5. AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   (Copy the complete content of frontend-publish-profile.xml)" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Gray

Write-Host "`n[Next Steps]" -ForegroundColor Yellow
Write-Host "1. Open GitHub repository settings page" -ForegroundColor White
Write-Host "2. Add the 5 Secrets above" -ForegroundColor White
Write-Host "3. Go to Actions tab and manually trigger the workflow" -ForegroundColor White
Write-Host "4. Wait for deployment to complete (about 5-10 minutes)" -ForegroundColor White
Write-Host "5. Visit the application URLs to verify deployment" -ForegroundColor White

Write-Host "`n[Application URLs]" -ForegroundColor Yellow
Write-Host "  Backend:  https://mediagenie-backend.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  Frontend: https://mediagenie-frontend.azurewebsites.net" -ForegroundColor Cyan

Write-Host "`n[SUCCESS] Deployment preparation complete!" -ForegroundColor Green
Write-Host ""

