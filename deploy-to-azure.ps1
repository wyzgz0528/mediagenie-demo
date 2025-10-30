# Azure Deployment Script for MediaGenie
# Usage: .\deploy-to-azure.ps1

param(
    [string]$ResourceGroup = "mediagenie-rg",
    [string]$Location = "eastus",
    [string]$AppPrefix = "mediagenie"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MediaGenie Azure Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Check Azure CLI
Write-Host "[1/8] Checking Azure CLI..." -ForegroundColor Yellow
az --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Azure CLI not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Azure CLI installed" -ForegroundColor Green

# Step 2: Check Azure login
Write-Host "[2/8] Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>&1 | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not logged in to Azure. Run: az login" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Logged in as $($account.user.name)" -ForegroundColor Green

# Step 3: Create resource group
Write-Host "[3/8] Creating resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    az group create --name $ResourceGroup --location $Location
    Write-Host "OK: Resource group created" -ForegroundColor Green
} else {
    Write-Host "OK: Resource group already exists" -ForegroundColor Green
}

# Step 4: Create App Service Plan
Write-Host "[4/8] Creating App Service Plan..." -ForegroundColor Yellow
$planName = "$AppPrefix-plan"
$existingPlan = az appservice plan list --resource-group $ResourceGroup --query "[?name=='$planName']" 2>&1
if ($existingPlan -eq "[]") {
    az appservice plan create --name $planName --resource-group $ResourceGroup --sku B1 --is-linux
    Write-Host "OK: App Service Plan created" -ForegroundColor Green
} else {
    Write-Host "OK: App Service Plan already exists" -ForegroundColor Green
}

# Step 5: Create Backend Web App
Write-Host "[5/8] Creating Backend Web App..." -ForegroundColor Yellow
$backendName = "$AppPrefix-backend"
$existingBackend = az webapp list --resource-group $ResourceGroup --query "[?name=='$backendName']" 2>&1
if ($existingBackend -eq "[]") {
    az webapp create --resource-group $ResourceGroup --plan $planName --name $backendName --runtime python:3.11
    Write-Host "OK: Backend Web App created" -ForegroundColor Green
} else {
    Write-Host "OK: Backend Web App already exists" -ForegroundColor Green
}

# Step 6: Create Frontend Web App
Write-Host "[6/8] Creating Frontend Web App..." -ForegroundColor Yellow
$frontendName = "$AppPrefix-frontend"
$existingFrontend = az webapp list --resource-group $ResourceGroup --query "[?name=='$frontendName']" 2>&1
if ($existingFrontend -eq "[]") {
    az webapp create --resource-group $ResourceGroup --plan $planName --name $frontendName --runtime node:18-lts
    Write-Host "OK: Frontend Web App created" -ForegroundColor Green
} else {
    Write-Host "OK: Frontend Web App already exists" -ForegroundColor Green
}

# Step 7: Create PostgreSQL Database
Write-Host "[7/8] Creating PostgreSQL Database..." -ForegroundColor Yellow
$dbName = "$AppPrefix-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbUser = "dbadmin"
$dbPassword = "MediaGenie@$(Get-Random -Minimum 100000 -Maximum 999999)"

$existingDb = az postgres server list --resource-group $ResourceGroup --query "[?name=='$dbName']" 2>&1
if ($existingDb -eq "[]") {
    az postgres server create `
        --resource-group $ResourceGroup `
        --name $dbName `
        --location $Location `
        --admin-user $dbUser `
        --admin-password $dbPassword `
        --sku-name B_Gen5_1 `
        --storage-size 51200
    Write-Host "OK: PostgreSQL Database created" -ForegroundColor Green
} else {
    Write-Host "OK: PostgreSQL Database already exists" -ForegroundColor Green
}

# Step 8: Configure App Settings
Write-Host "[8/8] Configuring App Settings..." -ForegroundColor Yellow
$dbConnectionString = "postgresql+asyncpg://$dbUser`:$dbPassword@$dbName.postgres.database.azure.com:5432/mediagenie"

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $backendName `
    --settings `
    DATABASE_URL=$dbConnectionString `
    ENVIRONMENT=production `
    DEBUG=false

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $frontendName `
    --settings `
    REACT_APP_MEDIA_SERVICE_URL="https://$backendName.azurewebsites.net" `
    REACT_APP_ENV=production

Write-Host "OK: App Settings configured" -ForegroundColor Green

# Summary
Write-Host "" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Backend URL: https://$backendName.azurewebsites.net" -ForegroundColor White
Write-Host "Frontend URL: https://$frontendName.azurewebsites.net" -ForegroundColor White
Write-Host "Database: $dbName" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Deploy backend code: az webapp deployment source config-zip --resource-group $ResourceGroup --name $backendName --src backend.zip" -ForegroundColor White
Write-Host "2. Deploy frontend code: az webapp deployment source config-zip --resource-group $ResourceGroup --name $frontendName --src frontend.zip" -ForegroundColor White
Write-Host "3. Run database migrations" -ForegroundColor White
Write-Host "4. Configure Azure AD" -ForegroundColor White
Write-Host "5. Test the application" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Database Connection String:" -ForegroundColor Yellow
Write-Host $dbConnectionString -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Database Admin Password:" -ForegroundColor Yellow
Write-Host $dbPassword -ForegroundColor White

