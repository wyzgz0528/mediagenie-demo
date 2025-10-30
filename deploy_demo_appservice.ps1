# MediaGenie Simple App Service Deployment
# This script deploys MediaGenie to Azure App Service (simplest option)

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "mediagenie-demo-rg",

    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory=$false)]
    [string]$AppName = "mediagenie-demo",

    [Parameter(Mandatory=$false)]
    [string]$Environment = "demo"
)

Write-Host "=== MediaGenie App Service Demo Deployment ===" -ForegroundColor Green
Write-Host "This will deploy MediaGenie to Azure App Service (simplest option)."
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if Azure CLI is installed
try {
    $azVersion = az --version 2>$null | Select-Object -First 1
    Write-Host "‚ú?Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "‚ú?Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Login to Azure
Write-Host "Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Azure:" -ForegroundColor Yellow
    az login --use-device-code
}

# Create resource group
Write-Host "Creating resource group '$ResourceGroupName'..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output none

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create --name "${AppName}-plan" --resource-group $ResourceGroupName --sku B1 --is-linux --output none

# Create Web App
Write-Host "Creating Web App..." -ForegroundColor Yellow
az webapp create --name $AppName --resource-group $ResourceGroupName --plan "${AppName}-plan" --runtime "PYTHON:3.11" --output none

# Configure environment variables
Write-Host "Configuring environment variables..." -ForegroundColor Yellow

$envVars = @(
    "ENVIRONMENT=$Environment",
    "AZURE_CLIENT_ID=$env:AZURE_CLIENT_ID",
    "AZURE_CLIENT_SECRET=$env:AZURE_CLIENT_SECRET",
    "AZURE_TENANT_ID=$env:AZURE_TENANT_ID",
    "AZURE_SUBSCRIPTION_ID=$env:AZURE_SUBSCRIPTION_ID",
    "AZURE_COGNITIVE_SERVICES_KEY=$env:AZURE_COGNITIVE_SERVICES_KEY",
    "AZURE_COGNITIVE_SERVICES_ENDPOINT=$env:AZURE_COGNITIVE_SERVICES_ENDPOINT",
    "DATABASE_URL=$env:DATABASE_URL",
    "JWT_SECRET_KEY=$env:JWT_SECRET_KEY",
    "AZURE_MARKETPLACE_CLIENT_ID=$env:AZURE_MARKETPLACE_CLIENT_ID",
    "AZURE_MARKETPLACE_CLIENT_SECRET=$env:AZURE_MARKETPLACE_CLIENT_SECRET",
    "AZURE_MARKETPLACE_TENANT_ID=$env:AZURE_MARKETPLACE_TENANT_ID"
)

foreach ($envVar in $envVars) {
    $keyValue = $envVar -split "="
    if ($keyValue.Length -eq 2) {
        $key = $keyValue[0]
        $value = $keyValue[1]
        if ($value -and $value -ne "`$env:AZURE_CLIENT_ID") {  # Skip if value is empty or placeholder
            az webapp config appsettings set --name $AppName --resource-group $ResourceGroupName --setting "$key=$value" --output none
        }
    }
}

# Deploy code using ZIP deploy
Write-Host "Deploying application code..." -ForegroundColor Yellow

# Create deployment ZIP (excluding unnecessary files)
$tempZip = "$env:TEMP\mediagenie-deploy.zip"
if (Test-Path $tempZip) { Remove-Item $tempZip }

# Create ZIP with required files
Compress-Archive -Path @(
    "backend\media-service\*",
    "marketplace-portal\*",
    "frontend\build\*",
    "nginx-demo.conf",
    "supervisord-demo.conf",
    "Dockerfile.demo"
) -DestinationPath $tempZip -CompressionLevel Optimal

# Deploy to App Service
az webapp deployment source config-zip --name $AppName --resource-group $ResourceGroupName --src $tempZip --output none

# Clean up
Remove-Item $tempZip

# Get deployment URL
Write-Host "Getting deployment information..." -ForegroundColor Yellow
$appUrl = az webapp show --name $AppName --resource-group $ResourceGroupName --query "defaultHostName" -o tsv

Write-Host ""
Write-Host "üéâ Deployment successful!" -ForegroundColor Green
Write-Host ""
Write-Host "MediaGenie Demo URLs:" -ForegroundColor Cyan
Write-Host "‚Ä?Frontend:     https://$appUrl"
Write-Host "‚Ä?API:          https://$appUrl/api"
Write-Host "‚Ä?Marketplace:  https://$appUrl/marketplace"
Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Yellow
Write-Host "‚Ä?Check status:  az webapp show --name $AppName --resource-group $ResourceGroupName"
Write-Host "‚Ä?View logs:     az webapp log tail --name $AppName --resource-group $ResourceGroupName"
Write-Host "‚Ä?Delete demo:   az group delete --name $ResourceGroupName --yes --no-wait"
Write-Host ""
Write-Host "‚ö†Ô∏è  Important Notes:" -ForegroundColor Yellow
Write-Host "‚Ä?This deployment uses Azure App Service (B1 plan)"
Write-Host "‚Ä?Monthly cost: ~$15-25 (App Service) + ~$20 (PostgreSQL) = ~$35-45 total"
Write-Host "‚Ä?Configure your .env file with actual Azure service credentials"
Write-Host "‚Ä?Demo environment expires after 30 days of inactivity"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Set up Azure Database for PostgreSQL"
Write-Host "2. Configure Azure AD application"
Write-Host "3. Set up Azure Cognitive Services"
Write-Host "4. Update environment variables in App Service settings"
Write-Host ""
Write-Host "Happy demoing! üöÄ" -ForegroundColor Green