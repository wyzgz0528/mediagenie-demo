# MediaGenie Simple Deployment Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================"
Write-Host "MediaGenie Deployment Started"
Write-Host "========================================`n"

$startTime = Get-Date

# Step 1: Create Resource Group
Write-Host "Step 1/5: Creating Resource Group..."
az group create --name $ResourceGroupName --location $Location --output table

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "Resource Group Created Successfully`n" -ForegroundColor Green

# Step 2: Deploy ARM Template
Write-Host "Step 2/5: Deploying ARM Template..."
$deploymentName = "mediagenie-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --template-file arm-templates/azuredeploy.json `
    --parameters arm-templates/azuredeploy.parameters.json `
    --output table

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: ARM Template deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "ARM Template Deployed Successfully`n" -ForegroundColor Green

# Get Deployment Outputs
Write-Host "Getting deployment outputs..."

$marketplaceApp = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.marketplaceAppName.value -o tsv

$backendApp = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.backendAppName.value -o tsv

$storageAccount = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.storageAccountName.value -o tsv

$landingPageUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.landingPageUrl.value -o tsv

$webhookUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.webhookUrl.value -o tsv

$frontendUrl = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --query properties.outputs.frontendUrl.value -o tsv

# Step 3: Deploy Marketplace Portal
Write-Host "Step 3/5: Deploying Marketplace Portal..."
Push-Location marketplace-portal

if (Test-Path "../marketplace-portal.zip") {
    Remove-Item "../marketplace-portal.zip" -Force
}

Compress-Archive -Path * -DestinationPath ../marketplace-portal.zip -Force

az webapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $marketplaceApp `
    --src ../marketplace-portal.zip

Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "Marketplace Portal Deployed Successfully`n" -ForegroundColor Green
}

# Step 4: Deploy Backend API
Write-Host "Step 4/5: Deploying Backend API..."
Push-Location backend\media-service

if (Test-Path "..\..\backend-api.zip") {
    Remove-Item "..\..\backend-api.zip" -Force
}

Compress-Archive -Path * -DestinationPath ..\..\backend-api.zip -Force

az webapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $backendApp `
    --src ..\..\backend-api.zip

Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backend API Deployed Successfully`n" -ForegroundColor Green
}

# Step 5: Deploy Frontend (Optional)
Write-Host "Step 5/5: Deploying Frontend..."
Write-Host "Note: Frontend deployment requires Node.js" -ForegroundColor Yellow

try {
    node --version | Out-Null
    npm --version | Out-Null
    
    Push-Location frontend
    
    Write-Host "Installing dependencies..."
    npm install --legacy-peer-deps
    
    Write-Host "Building frontend..."
    $env:REACT_APP_MEDIA_SERVICE_URL = "https://$backendApp.azurewebsites.net"
    npm run build
    
    Write-Host "Configuring static website..."
    az storage blob service-properties update `
        --account-name $storageAccount `
        --static-website `
        --404-document index.html `
        --index-document index.html `
        --auth-mode login
    
    Write-Host "Uploading to Storage Account..."
    az storage blob upload-batch `
        --account-name $storageAccount `
        --destination '$web' `
        --source build/ `
        --overwrite `
        --auth-mode login
    
    Pop-Location
    Write-Host "Frontend Deployed Successfully`n" -ForegroundColor Green
} catch {
    Write-Host "Frontend deployment skipped (Node.js not found or error occurred)`n" -ForegroundColor Yellow
}

# Wait for services to start
Write-Host "Waiting for services to start (30 seconds)..."
Start-Sleep -Seconds 30

# Calculate duration
$endTime = Get-Date
$duration = $endTime - $startTime

# Save deployment info
$deploymentInfo = @"
MediaGenie Deployment Information

Deployment Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Resource Group: $ResourceGroupName
Location: $Location
Duration: $($duration.ToString())

Important URLs for Azure Marketplace:
- Landing Page URL: $landingPageUrl
- Webhook URL: $webhookUrl
- Frontend URL: $frontendUrl

Resource Names:
- Marketplace App: $marketplaceApp
- Backend App: $backendApp
- Storage Account: $storageAccount

Next Steps:
1. Visit Landing Page: $landingPageUrl
2. Submit to Azure Marketplace Partner Center:
   - Landing page URL: $landingPageUrl
   - Connection webhook: $webhookUrl
"@

$deploymentInfo | Out-File -FilePath "DEPLOYMENT_INFO.txt" -Encoding UTF8

# Display Summary
Write-Host "`n========================================"
Write-Host "Deployment Completed Successfully!"
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Important URLs (Azure Marketplace):" -ForegroundColor Yellow
Write-Host "  Landing Page URL: $landingPageUrl" -ForegroundColor Cyan
Write-Host "  Webhook URL:      $webhookUrl" -ForegroundColor Cyan
Write-Host "  Frontend URL:     $frontendUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "Resource Names:" -ForegroundColor Yellow
Write-Host "  Marketplace App: $marketplaceApp"
Write-Host "  Backend App:     $backendApp"
Write-Host "  Storage Account: $storageAccount"
Write-Host ""

Write-Host "Duration: $($duration.ToString('mm\:ss'))"
Write-Host ""

Write-Host "Deployment info saved to: DEPLOYMENT_INFO.txt" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Visit Landing Page: $landingPageUrl"
Write-Host "2. Submit to Partner Center: https://partner.microsoft.com/dashboard/marketplace-offers/overview"
Write-Host ""

Write-Host "========================================"
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================`n"
