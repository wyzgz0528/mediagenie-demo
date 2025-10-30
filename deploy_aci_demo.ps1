# MediaGenie Azure Container Instances Deployment
# This script deploys MediaGenie to Azure Container Instances for demo purposes

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerGroupName = "mediagenie-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "mediagenie-demo:latest",
    
    [Parameter(Mandatory=$false)]
    [int]$CpuCores = 2,
    
    [Parameter(Mandatory=$false)]
    [double]$MemoryGb = 4.0,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "demo"
)

# Login to Azure (if not already logged in)
Write-Host "Checking Azure login status..."
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Azure first:"
    az login
}

# Create resource group if it doesn't exist
Write-Host "Creating resource group '$ResourceGroupName' in '$Location'..."
az group create --name $ResourceGroupName --location $Location

# Build and push Docker image (assuming Docker is installed)
Write-Host "Building Docker image..."
docker build -t $ImageName .

# Login to Azure Container Registry (if using ACR)
# az acr login --name yourregistry

# Push image to registry
# docker tag $ImageName yourregistry.azurecr.io/$ImageName
# docker push yourregistry.azurecr.io/$ImageName

# Deploy to Azure Container Instances
Write-Host "Deploying to Azure Container Instances..."

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

$envString = $envVars -join " --environment-variables "

$command = @"
az container create --resource-group $ResourceGroupName --name $ContainerGroupName --image $ImageName --cpu $CpuCores --memory $MemoryGb --ports 80 443 --environment-variables $envString --ip-address public --dns-name-label mediagenie-demo-$(Get-Random)
"@

Write-Host "Running deployment command..."
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment successful!"
    
    # Get the public IP
    $ip = az container show --resource-group $ResourceGroupName --name $ContainerGroupName --query ipAddress.ip --output tsv
    Write-Host "MediaGenie demo is running at: http://$ip"
    
    # Show logs
    Write-Host "Checking container logs..."
    az container logs --resource-group $ResourceGroupName --name $ContainerGroupName
} else {
    Write-Host "Deployment failed. Check the error messages above."
    exit 1
}

Write-Host @"

Deployment completed! 

To check status: az container show --resource-group $ResourceGroupName --name $ContainerGroupName
To view logs: az container logs --resource-group $ResourceGroupName --name $ContainerGroupName  
To delete: az container delete --resource-group $ResourceGroupName --name $ContainerGroupName

Monthly cost estimate: ~$10-15 (ACI) + ~$20 (PostgreSQL) = ~$30-35 total

"@