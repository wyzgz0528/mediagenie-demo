# MediaGenie Quick Deploy Script (Free Tier)
# This script uses Free F1 tier to avoid quota issues

Write-Host "========================================" -ForegroundColor Green
Write-Host "   MediaGenie Quick Deploy (Free Tier)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check Azure CLI
Write-Host "[1/8] Checking Azure CLI..." -ForegroundColor Yellow
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Azure CLI not installed" -ForegroundColor Red
    Write-Host "Please visit: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Azure CLI installed" -ForegroundColor Green

# Check login status
Write-Host "`n[2/8] Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (!$account) {
    Write-Host "Not logged in to Azure, starting login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "  Subscription: $($account.name)" -ForegroundColor Cyan

# Variables
$resourceGroup = "mediagenie-rg"
$location = "eastus2"
$acrName = "mediageniecr"
$planName = "mediagenie-free-plan"
$backendName = "mediagenie-backend"
$frontendName = "mediagenie-frontend"

# Check Resource Group
Write-Host "`n[3/8] Checking Resource Group..." -ForegroundColor Yellow
$rgExists = az group show --name $resourceGroup 2>$null
if ($rgExists) {
    Write-Host "[OK] Resource group exists" -ForegroundColor Green
} else {
    Write-Host "  Creating resource group..." -ForegroundColor Yellow
    az group create --name $resourceGroup --location $location --output none
    Write-Host "[OK] Resource group created" -ForegroundColor Green
}

# Check ACR
Write-Host "`n[4/8] Checking Azure Container Registry..." -ForegroundColor Yellow
$acrExists = az acr show --name $acrName --resource-group $resourceGroup 2>$null
if ($acrExists) {
    Write-Host "[OK] ACR exists" -ForegroundColor Green
} else {
    Write-Host "  Creating ACR..." -ForegroundColor Yellow
    az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location --output none
    Write-Host "[OK] ACR created" -ForegroundColor Green
}

# Enable admin account
Write-Host "  Enabling admin account..." -ForegroundColor Yellow
az acr update --name $acrName --admin-enabled true --output none
Write-Host "[OK] Admin account enabled" -ForegroundColor Green

# Get ACR credentials
Write-Host "`n[5/8] Getting ACR credentials..." -ForegroundColor Yellow
$acrCreds = az acr credential show --name $acrName | ConvertFrom-Json
$acrLoginServer = "$acrName.azurecr.io"
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "[OK] ACR credentials retrieved" -ForegroundColor Green
Write-Host "  Login Server: $acrLoginServer" -ForegroundColor Cyan
Write-Host "  Username: $acrUsername" -ForegroundColor Cyan
Write-Host "  Password: $acrPassword" -ForegroundColor Cyan

# Create App Service Plan (Free Tier)
Write-Host "`n[6/8] Checking/Creating App Service Plan (Free Tier)..." -ForegroundColor Yellow
$planExists = az appservice plan show --name $planName --resource-group $resourceGroup 2>$null
if ($planExists) {
    Write-Host "[OK] App Service Plan exists" -ForegroundColor Green
} else {
    Write-Host "  Creating Free tier App Service Plan..." -ForegroundColor Yellow
    Write-Host "  NOTE: Free tier has limitations (no custom domains, no SSL, limited resources)" -ForegroundColor Yellow
    az appservice plan create `
        --name $planName `
        --resource-group $resourceGroup `
        --location $location `
        --sku F1 `
        --is-linux `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] App Service Plan created (Free F1)" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to create App Service Plan" -ForegroundColor Red
        Write-Host "You may need to:" -ForegroundColor Yellow
        Write-Host "  1. Request quota increase from Azure Portal" -ForegroundColor Yellow
        Write-Host "  2. Or use existing Web Apps in different resource group" -ForegroundColor Yellow
        exit 1
    }
}

# Create Backend Web App
Write-Host "`n[7/8] Checking/Creating Web Apps..." -ForegroundColor Yellow
$backendExists = az webapp show --name $backendName --resource-group $resourceGroup 2>$null
if ($backendExists) {
    Write-Host "[OK] Backend Web App exists" -ForegroundColor Green
} else {
    Write-Host "  Creating backend Web App..." -ForegroundColor Yellow
    az webapp create `
        --name $backendName `
        --resource-group $resourceGroup `
        --plan $planName `
        --runtime "PYTHON:3.11" `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backend Web App created" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Backend Web App creation failed" -ForegroundColor Yellow
        Write-Host "Checking if it exists in another resource group..." -ForegroundColor Yellow
        $existingBackend = az webapp list --query "[?name=='$backendName']" | ConvertFrom-Json
        if ($existingBackend) {
            $existingRG = $existingBackend[0].resourceGroup
            Write-Host "[INFO] Found existing backend in resource group: $existingRG" -ForegroundColor Cyan
            Write-Host "[INFO] Will use existing Web App" -ForegroundColor Cyan
            $resourceGroup = $existingRG
        }
    }
}

# Create Frontend Web App
$frontendExists = az webapp show --name $frontendName --resource-group $resourceGroup 2>$null
if ($frontendExists) {
    Write-Host "[OK] Frontend Web App exists" -ForegroundColor Green
} else {
    Write-Host "  Creating frontend Web App..." -ForegroundColor Yellow
    az webapp create `
        --name $frontendName `
        --resource-group $resourceGroup `
        --plan $planName `
        --runtime "NODE:18-lts" `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Frontend Web App created" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Frontend Web App creation failed" -ForegroundColor Yellow
        Write-Host "You may need to create it manually in Azure Portal" -ForegroundColor Yellow
    }
}

# Configure Web Apps for Docker
Write-Host "`n[8/8] Configuring Web Apps for Docker..." -ForegroundColor Yellow

# Find backend resource group
$backendInfo = az webapp list --query "[?name=='$backendName']" | ConvertFrom-Json
if ($backendInfo) {
    $backendRG = $backendInfo[0].resourceGroup
    Write-Host "  Configuring backend (Resource Group: $backendRG)..." -ForegroundColor Yellow
    
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
        --settings WEBSITES_PORT=8000 `
        --output none 2>$null
    
    Write-Host "[OK] Backend configured" -ForegroundColor Green
    
    # Get backend publish profile
    Write-Host "  Getting backend publish profile..." -ForegroundColor Yellow
    az webapp deployment list-publishing-profiles `
        --name $backendName `
        --resource-group $backendRG `
        --xml > backend-publish-profile.xml 2>$null
    Write-Host "[OK] Backend publish profile saved" -ForegroundColor Green
}

# Find frontend resource group
$frontendInfo = az webapp list --query "[?name=='$frontendName']" | ConvertFrom-Json
if ($frontendInfo) {
    $frontendRG = $frontendInfo[0].resourceGroup
    Write-Host "  Configuring frontend (Resource Group: $frontendRG)..." -ForegroundColor Yellow
    
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
        --settings WEBSITES_PORT=8080 `
        --output none 2>$null
    
    Write-Host "[OK] Frontend configured" -ForegroundColor Green
    
    # Get frontend publish profile
    Write-Host "  Getting frontend publish profile..." -ForegroundColor Yellow
    az webapp deployment list-publishing-profiles `
        --name $frontendName `
        --resource-group $frontendRG `
        --xml > frontend-publish-profile.xml 2>$null
    Write-Host "[OK] Frontend publish profile saved" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Frontend Web App not found" -ForegroundColor Yellow
    Write-Host "Please create it manually in Azure Portal" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n[GitHub Secrets Configuration]" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""
Write-Host "Add these secrets to GitHub:" -ForegroundColor White
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
Write-Host "   (Copy content from: backend-publish-profile.xml)" -ForegroundColor White
Write-Host ""
Write-Host "5. AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   (Copy content from: frontend-publish-profile.xml)" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Gray

Write-Host "`n[Application URLs]" -ForegroundColor Yellow
Write-Host "  Backend:  https://$backendName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  Frontend: https://$frontendName.azurewebsites.net" -ForegroundColor Cyan

Write-Host "`n[SUCCESS] Configuration complete!" -ForegroundColor Green
Write-Host ""

