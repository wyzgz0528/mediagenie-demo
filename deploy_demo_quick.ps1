# MediaGenie Quick Demo Deployment Script
# This script provides a simplified way to deploy MediaGenie for demo purposes

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "mediagenie-demo-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerGroupName = "mediagenie-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "demo"
)

Write-Host "=== MediaGenie Demo Deployment ===" -ForegroundColor Green
Write-Host "This will deploy MediaGenie to Azure Container Instances for demo purposes."
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if Docker is installed and running
try {
    $dockerVersion = docker --version 2>$null
    Write-Host "‚ú?Docker found: $dockerVersion" -ForegroundColor Green
    
    # Check if Docker daemon is running
    try {
        $dockerInfo = docker info 2>$null
        Write-Host "‚ú?Docker daemon is running" -ForegroundColor Green
    } catch {
        Write-Host "‚ú?Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
        Write-Host ""
        Write-Host "To fix this:" -ForegroundColor Yellow
        Write-Host "1. Open Docker Desktop" -ForegroundColor White
        Write-Host "2. Wait for Docker to fully start (whale icon in system tray should be steady)" -ForegroundColor White
        Write-Host "3. Try running this script again" -ForegroundColor White
        Write-Host ""
        Write-Host "Alternative: Use Azure Container Registry build (see AZURE_DEMO_DEPLOYMENT.md)" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "‚ú?Docker not found. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host ""
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "Alternative: Use Azure Container Registry build (see AZURE_DEMO_DEPLOYMENT.md)" -ForegroundColor Cyan
    exit 1
}

# Check if Azure CLI is installed
try {
    $azVersion = az --version 2>$null | Select-Object -First 1
    Write-Host "‚ú?Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "‚ú?Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
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

# Build Docker image
Write-Host "Building MediaGenie demo image..." -ForegroundColor Yellow
docker build -f Dockerfile.demo -t mediagenie-demo:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "‚ú?Docker build failed. Check the build output above." -ForegroundColor Red
    exit 1
}

# Deploy to ACI
Write-Host "Deploying to Azure Container Instances..." -ForegroundColor Yellow

$deployCommand = @"
az container create --resource-group $ResourceGroupName --name $ContainerGroupName --image mediagenie-demo:latest --cpu 2 --memory 4 --ports 80 --ip-address public --dns-name-label mediagenie-demo-$((Get-Random -Maximum 9999).ToString('0000')) --output none
"@

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
Write-Host ""
Write-Host "‚ö†Ô∏è  Important Notes:" -ForegroundColor Yellow
Write-Host "‚Ä?This is a demo deployment with limited resources"
Write-Host "‚Ä?Configure your .env file with actual Azure service credentials"
Write-Host "‚Ä?Monthly cost: ~$30-35 (ACI + PostgreSQL)"
Write-Host "‚Ä?Demo environment expires after 30 days of inactivity"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Set up Azure Database for PostgreSQL"
Write-Host "2. Configure Azure AD application"
Write-Host "3. Set up Azure Cognitive Services"
Write-Host "4. Update environment variables in the container"
Write-Host ""
Write-Host "Happy demoing! üöÄ" -ForegroundColor Green