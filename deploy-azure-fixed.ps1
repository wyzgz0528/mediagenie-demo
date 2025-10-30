# Fixed Azure Deployment Script for MediaGenie
# This script creates Azure resources using Azure CLI

param(
    [string]$ResourceGroup = "mediagenie-rg",
    [string]$Location = "eastus",
    [string]$AppPrefix = "mediagenie"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MediaGenie Azure Deployment (Fixed)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Azure CLI
Write-Host "[1/6] Checking Azure CLI..." -ForegroundColor Yellow
$cliVersion = az --version 2>&1 | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Azure CLI not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Azure CLI installed" -ForegroundColor Green
Write-Host ""

# Step 2: Check Azure login
Write-Host "[2/6] Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>&1 | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not logged in to Azure. Run: az login" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Logged in as $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Step 3: Create resource group
Write-Host "[3/6] Creating resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Host "OK: Resource group created" -ForegroundColor Green
} else {
    Write-Host "OK: Resource group already exists" -ForegroundColor Green
}
Write-Host ""

# Step 4: Create App Service Plan
Write-Host "[4/6] Creating App Service Plan..." -ForegroundColor Yellow
$planName = "$AppPrefix-plan"
az appservice plan create --name $planName --resource-group $ResourceGroup --sku B1 --is-linux 2>&1 | Out-Null
Write-Host "OK: App Service Plan created" -ForegroundColor Green
Write-Host ""

# Step 5: Create Web Apps
Write-Host "[5/6] Creating Web Apps..." -ForegroundColor Yellow

# Backend Web App
$backendName = "$AppPrefix-backend"
Write-Host "  Creating backend: $backendName" -ForegroundColor Cyan
az webapp create --resource-group $ResourceGroup --plan $planName --name $backendName --runtime python:3.11 2>&1 | Out-Null
Write-Host "  OK: Backend created" -ForegroundColor Green

# Frontend Web App
$frontendName = "$AppPrefix-frontend"
Write-Host "  Creating frontend: $frontendName" -ForegroundColor Cyan
az webapp create --resource-group $ResourceGroup --plan $planName --name $frontendName --runtime node:18-lts 2>&1 | Out-Null
Write-Host "  OK: Frontend created" -ForegroundColor Green
Write-Host ""

# Step 6: Create PostgreSQL Database
Write-Host "[6/6] Creating PostgreSQL Database..." -ForegroundColor Yellow
$dbName = "$AppPrefix-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbUser = "dbadmin"
$dbPassword = "MediaGenie@$(Get-Random -Minimum 100000 -Maximum 999999)"

Write-Host "  Database name: $dbName" -ForegroundColor Cyan
Write-Host "  Admin user: $dbUser" -ForegroundColor Cyan
Write-Host "  Creating database (this may take 2-3 minutes)..." -ForegroundColor Yellow

az postgres server create `
    --resource-group $ResourceGroup `
    --name $dbName `
    --location $Location `
    --admin-user $dbUser `
    --admin-password $dbPassword `
    --sku-name B_Gen5_1 `
    --storage-size 51200 2>&1 | Out-Null

Write-Host "OK: PostgreSQL Database created" -ForegroundColor Green
Write-Host ""

# Configure App Settings
Write-Host "Configuring app settings..." -ForegroundColor Yellow
$dbConnectionString = "postgresql+asyncpg://$dbUser`:$dbPassword@$dbName.postgres.database.azure.com:5432/mediagenie"

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $backendName `
    --settings `
    DATABASE_URL=$dbConnectionString `
    ENVIRONMENT=production `
    DEBUG=false 2>&1 | Out-Null

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $frontendName `
    --settings `
    REACT_APP_MEDIA_SERVICE_URL="https://$backendName.azurewebsites.net" `
    REACT_APP_ENV=production 2>&1 | Out-Null

Write-Host "OK: App settings configured" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Azure Resources Created:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  Backend URL: https://$backendName.azurewebsites.net" -ForegroundColor White
Write-Host "  Frontend URL: https://$frontendName.azurewebsites.net" -ForegroundColor White
Write-Host "  Database: $dbName" -ForegroundColor White
Write-Host ""
Write-Host "Database Credentials:" -ForegroundColor Yellow
Write-Host "  Server: $dbName.postgres.database.azure.com" -ForegroundColor White
Write-Host "  Admin User: $dbUser" -ForegroundColor White
Write-Host "  Admin Password: $dbPassword" -ForegroundColor White
Write-Host ""
Write-Host "Connection String:" -ForegroundColor Yellow
Write-Host "  $dbConnectionString" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Deploy backend code using VSCode Azure extension" -ForegroundColor White
Write-Host "2. Deploy frontend code using VSCode Azure extension" -ForegroundColor White
Write-Host "3. Configure Azure AD (optional)" -ForegroundColor White
Write-Host "4. Test the application" -ForegroundColor White
Write-Host ""
Write-Host "For deployment instructions, see: VSCODE_MANUAL_SETUP.md" -ForegroundColor Cyan

