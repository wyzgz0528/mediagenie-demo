# MediaGenie ACR-based Demo Deployment Script
# This script builds and deploys using Azure Container Registry (no local Docker needed)

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "mediagenie-demo-rg",

    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory=$false)]
    [string]$ContainerGroupName = "mediagenie-demo",

    [Parameter(Mandatory=$false)]
    [string]$AcrName = "mediageniedemoacr",

    [Parameter(Mandatory=$false)]
    [string]$ImageName = "mediagenie-demo",

    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",

    [Parameter(Mandatory=$false)]
    [string]$Environment = "demo"
)

Write-Host "=== MediaGenie ACR Demo Deployment ===" -ForegroundColor Green
Write-Host "This will build and deploy MediaGenie using Azure Container Registry."
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

# Create Azure Container Registry
Write-Host "Creating Azure Container Registry '$AcrName'..." -ForegroundColor Yellow
az acr create --resource-group $ResourceGroupName --name $AcrName --sku Basic --output none

# Enable admin user for ACR
Write-Host "Enabling admin user for ACR..." -ForegroundColor Yellow
az acr update --name $AcrName --admin-enabled true --output none

# Get ACR login server
$acrLoginServer = az acr show --name $AcrName --query loginServer -o tsv
Write-Host "ACR Login Server: $acrLoginServer" -ForegroundColor Cyan

# Build and push image using ACR tasks (no local Docker needed)
Write-Host "Building and pushing image using ACR Tasks..." -ForegroundColor Yellow

$buildCommand = @"
az acr build --registry $AcrName --image ${ImageName}:${ImageTag} --file Dockerfile.demo .
"@

Write-Host "Running: $buildCommand" -ForegroundColor Gray
Invoke-Expression $buildCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "‚ú?ACR build failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

# Deploy to ACI
Write-Host "Deploying to Azure Container Instances..." -ForegroundColor Yellow

$fullImageName = "${acrLoginServer}/${ImageName}:${ImageTag}"

# Get ACR password
$acrPassword = az acr credential show --name $AcrName --query 'passwords[0].value' -o tsv

$deployCommand = @"
az container create --resource-group $ResourceGroupName --name $ContainerGroupName --image $fullImageName --cpu 2 --memory 4 --ports 80 --ip-address public --dns-name-label mediagenie-demo-$((Get-Random -Maximum 9999).ToString('0000')) --registry-login-server $acrLoginServer --registry-username $AcrName --registry-password $acrPassword --os-type Linux --output none
"@

Write-Host "Running deployment command..." -ForegroundColor Gray
Invoke-Expression $deployCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "‚ú?Deployment failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

# Get deployment info
Write-Host "Getting deployment information..." -ForegroundColor Yellow
$containerInfo = az container show --resource-group $ResourceGroupName --name $ContainerGroupName --output json | ConvertFrom-Json
$publicIp = $containerInfo.ipAddress.ip
$dnsName = $containerInfo.ipAddress.fqdn

Write-Host ""
Write-Host "üéâ Deployment successful!" -ForegroundColor Green
Write-Host ""
Write-Host "MediaGenie Demo URLs:" -ForegroundColor Cyan
Write-Host "‚Ä?Frontend:     http://$publicIp"
Write-Host "‚Ä?API:          http://$publicIp/api"
Write-Host "‚Ä?Marketplace:  http://$publicIp/marketplace"
Write-Host "‚Ä?Health Check: http://$publicIp/health"
Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Yellow
Write-Host "‚Ä?Check status:  az container show --resource-group $ResourceGroupName --name $ContainerGroupName"
Write-Host "‚Ä?View logs:     az container logs --resource-group $ResourceGroupName --name $ContainerGroupName"
Write-Host "‚Ä?Delete demo:   az container delete --resource-group $ResourceGroupName --name $ContainerGroupName --yes"
Write-Host "‚Ä?Delete ACR:    az acr delete --name $AcrName --resource-group $ResourceGroupName --yes"
Write-Host ""
Write-Host "‚ö†Ô∏è  Important Notes:" -ForegroundColor Yellow
Write-Host "‚Ä?This deployment includes ACR storage costs (~$5/month)"
Write-Host "‚Ä?Configure your .env file with actual Azure service credentials"
Write-Host "‚Ä?Monthly cost: ~$30-40 (ACI $10-15 + PostgreSQL $15-20 + ACR $5)"
Write-Host "‚Ä?Demo environment expires after 30 days of inactivity"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Set up Azure Database for PostgreSQL"
Write-Host "2. Configure Azure AD application"
Write-Host "3. Set up Azure Cognitive Services"
Write-Host "4. Update environment variables in the container"
Write-Host ""
Write-Host "Happy demoing! üöÄ" -ForegroundColor Green