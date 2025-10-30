# MediaGenie Final Deployment Package Creator
# This script creates a complete deployment package with all necessary files

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "     MediaGenie Complete Deployment Package Creator                " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$packageName = "MediaGenie-Complete-Deploy"
$tempDir = "temp_final_package"
$outputZip = "$packageName.zip"

# Step 1: Clean up
Write-Host "[1/7] Cleaning up old files..." -ForegroundColor Yellow
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
if (Test-Path $outputZip) { Remove-Item -Force $outputZip }

# Step 2: Create temp directory
Write-Host "[2/7] Creating temp directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Step 3: Copy backend
Write-Host "[3/7] Copying backend code..." -ForegroundColor Yellow
$backendDir = Join-Path $tempDir "backend"
New-Item -ItemType Directory -Path $backendDir -Force | Out-Null

if (Test-Path "backend\media-service") {
    Copy-Item -Path "backend\media-service" -Destination $backendDir -Recurse -Force -Exclude @("__pycache__", "*.pyc", "*.log", "venv")
    Write-Host "  - Copied backend/media-service" -ForegroundColor Gray
    
    Get-ChildItem -Path "$backendDir\media-service" -Include "__pycache__","*.pyc","*.log" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "  - Cleaned cache files" -ForegroundColor Gray
} else {
    Write-Host "  - ERROR: backend\media-service not found!" -ForegroundColor Red
    exit 1
}

# Step 4: Copy frontend build
Write-Host "[4/7] Copying frontend build..." -ForegroundColor Yellow
$frontendDir = Join-Path $tempDir "frontend"
New-Item -ItemType Directory -Path $frontendDir -Force | Out-Null

if (Test-Path "frontend\build") {
    Copy-Item -Path "frontend\build" -Destination $frontendDir -Recurse -Force
    Write-Host "  - Copied frontend/build" -ForegroundColor Gray
    
    $buildFiles = Get-ChildItem -Path "$frontendDir\build" -Recurse -File
    $buildSize = ($buildFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  - Frontend build size: $([math]::Round($buildSize, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "  - ERROR: frontend\build not found! Run npm run build first" -ForegroundColor Red
    exit 1
}

# Step 5: Copy deployment files
Write-Host "[5/7] Copying deployment files..." -ForegroundColor Yellow

if (Test-Path "azuredeploy.json") {
    Copy-Item -Path "azuredeploy.json" -Destination $tempDir -Force
    Write-Host "  - Copied azuredeploy.json" -ForegroundColor Gray
}

if (Test-Path "Dockerfile") {
    Copy-Item -Path "Dockerfile" -Destination $tempDir -Force
    Write-Host "  - Copied Dockerfile" -ForegroundColor Gray
}

if (Test-Path "docker-compose.yml") {
    Copy-Item -Path "docker-compose.yml" -Destination $tempDir -Force
    Write-Host "  - Copied docker-compose.yml" -ForegroundColor Gray
}

if (Test-Path "README.md") {
    Copy-Item -Path "README.md" -Destination $tempDir -Force
    Write-Host "  - Copied README.md" -ForegroundColor Gray
}

# Step 6: Create deployment scripts
Write-Host "[6/7] Creating deployment scripts..." -ForegroundColor Yellow

# Create deploy-now.sh
$deployScript = @'
#!/bin/bash

# MediaGenie Deployment Script
# Supports Free Tier (F1) and Standard Tier (S1)

set -e

echo "===================================================================="
echo "              MediaGenie Azure Deployment                          "
echo "===================================================================="
echo ""

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed"
    exit 1
fi

# Check login
echo "[1/5] Checking Azure login..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "Using subscription: $SUBSCRIPTION_NAME"
echo ""

# Get API Keys
echo "[2/5] Please provide your Azure service credentials:"
echo ""
read -p "Azure OpenAI API Key: " OPENAI_KEY
read -p "Azure OpenAI Endpoint (e.g., https://your-openai.openai.azure.com/): " OPENAI_ENDPOINT
read -p "Azure Speech Key: " SPEECH_KEY
read -p "Azure Speech Region [eastus]: " SPEECH_REGION
SPEECH_REGION=${SPEECH_REGION:-eastus}

echo ""
read -p "Choose SKU (F1=Free, S1=Standard) [F1]: " SKU
SKU=${SKU:-F1}

# Configuration
RESOURCE_GROUP="MediaGenie-RG"
LOCATION="eastus"
APP_NAME="mediagenie-$(date +%s)"

echo ""
echo "Deployment Configuration:"
echo "  App Name:       $APP_NAME"
echo "  SKU:            $SKU"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location:       $LOCATION"
echo ""
read -p "Continue? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create resource group
echo ""
echo "[3/5] Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output none

# Deploy with ARM template
echo "[4/5] Deploying with ARM template..."
echo "This may take 5-10 minutes..."
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters \
    siteName=$APP_NAME \
    sku=$SKU \
    azureOpenAIKey="$OPENAI_KEY" \
    azureOpenAIEndpoint="$OPENAI_ENDPOINT" \
    azureSpeechKey="$SPEECH_KEY" \
    azureSpeechRegion="$SPEECH_REGION" \
  --query 'properties.outputs' \
  --output json)

# Deploy application code
echo ""
echo "[5/5] Deploying application code..."

# Create deployment zip
TEMP_ZIP=$(mktemp).zip
zip -r $TEMP_ZIP backend frontend > /dev/null 2>&1

# Deploy to Web App
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --src $TEMP_ZIP \
  --output none

rm -f $TEMP_ZIP

# Get URLs
WEBSITE_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.websiteUrl.value')

echo ""
echo "===================================================================="
echo "                    Deployment Complete!                           "
echo "===================================================================="
echo ""
echo "Application Info:"
echo "  Name:           $APP_NAME"
echo "  SKU:            $SKU"
echo "  Resource Group: $RESOURCE_GROUP"
echo ""
echo "Access URLs:"
echo "  Website:     $WEBSITE_URL"
echo "  API Docs:    $WEBSITE_URL/docs"
echo "  Health:      $WEBSITE_URL/health"
echo ""

if [ "$SKU" == "F1" ]; then
    echo "Note: Free tier (F1) limitations:"
    echo "  - 60 minutes/day compute time"
    echo "  - App sleeps after 20 minutes of inactivity"
    echo ""
    echo "To upgrade to Standard tier:"
    echo "  az appservice plan update \\"
    echo "    --name $APP_NAME-plan \\"
    echo "    --resource-group $RESOURCE_GROUP \\"
    echo "    --sku S1"
    echo ""
fi

echo "===================================================================="
echo ""
'@

$deployScript | Out-File -FilePath (Join-Path $tempDir "deploy-now.sh") -Encoding UTF8 -NoNewline
Write-Host "  - Created deploy-now.sh" -ForegroundColor Gray

# Create quick-deploy.sh (simplified version)
$quickDeploy = @'
#!/bin/bash

# Quick Deploy Script - Edit the variables below and run

# === EDIT THESE VALUES ===
OPENAI_KEY="your-openai-key-here"
OPENAI_ENDPOINT="https://your-openai.openai.azure.com/"
SPEECH_KEY="your-speech-key-here"
SPEECH_REGION="eastus"
SKU="F1"  # F1=Free, S1=Standard
# =========================

RESOURCE_GROUP="MediaGenie-RG"
APP_NAME="mediagenie-$(date +%s)"

echo "Deploying MediaGenie..."
echo "  SKU: $SKU"
echo "  App: $APP_NAME"
echo ""

# Create resource group
az group create --name $RESOURCE_GROUP --location eastus --output none

# Deploy
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters \
    siteName=$APP_NAME \
    sku=$SKU \
    azureOpenAIKey="$OPENAI_KEY" \
    azureOpenAIEndpoint="$OPENAI_ENDPOINT" \
    azureSpeechKey="$SPEECH_KEY" \
    azureSpeechRegion="$SPEECH_REGION"

echo ""
echo "Deployment complete!"
echo "Visit: https://$APP_NAME.azurewebsites.net"
'@

$quickDeploy | Out-File -FilePath (Join-Path $tempDir "quick-deploy.sh") -Encoding UTF8 -NoNewline
Write-Host "  - Created quick-deploy.sh" -ForegroundColor Gray

# Create .deployment file
$deploymentFile = Join-Path $tempDir ".deployment"
"[config]" | Out-File -FilePath $deploymentFile -Encoding ASCII
"SCM_DO_BUILD_DURING_DEPLOYMENT=true" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
"PROJECT=backend/media-service" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
Write-Host "  - Created .deployment" -ForegroundColor Gray

# Create README
$readmeContent = @"
# MediaGenie Azure Deployment Package

## Quick Start

### Method 1: Interactive Deployment (Recommended)

``````bash
chmod +x deploy-now.sh
./deploy-now.sh
``````

This script will:
- Guide you through entering API keys
- Let you choose SKU (F1=Free or S1=Standard)
- Deploy everything automatically

### Method 2: Quick Deployment (Edit and Run)

1. Edit ``quick-deploy.sh`` and update your API keys
2. Run:
   ``````bash
   chmod +x quick-deploy.sh
   ./quick-deploy.sh
   ``````

### Method 3: Manual ARM Template Deployment

``````bash
az deployment group create \
  --resource-group MediaGenie-RG \
  --template-file azuredeploy.json \
  --parameters \
    siteName=mediagenie-test \
    sku=F1 \
    azureOpenAIKey="your-key" \
    azureOpenAIEndpoint="https://your-endpoint.openai.azure.com/" \
    azureSpeechKey="your-key" \
    azureSpeechRegion="eastus"
``````

## SKU Options

- **F1 (Free)**: No quota issues, 60 min/day, free
- **S1 (Standard)**: No limitations, ~`$70/month
- **B1 (Basic)**: May need quota approval, ~`$13/month

## Package Contents

- ``backend/media-service/`` - Complete FastAPI backend
- ``frontend/build/`` - Production React build
- ``azuredeploy.json`` - ARM template (default: F1)
- ``deploy-now.sh`` - Interactive deployment script
- ``quick-deploy.sh`` - Quick deployment script
- ``.deployment`` - Kudu deployment config

## After Deployment

Visit:
- Application: https://your-app.azurewebsites.net/
- API Docs: https://your-app.azurewebsites.net/docs
- Health: https://your-app.azurewebsites.net/health

## Upgrade SKU

``````bash
az appservice plan update \
  --name your-app-plan \
  --resource-group MediaGenie-RG \
  --sku S1
``````

## Support

For issues, check:
- Azure Portal logs
- ``az webapp log tail --name your-app --resource-group MediaGenie-RG``
"@

$readmeContent | Out-File -FilePath (Join-Path $tempDir "DEPLOYMENT_README.md") -Encoding UTF8
Write-Host "  - Created DEPLOYMENT_README.md" -ForegroundColor Gray

# Step 7: Create ZIP
Write-Host "[7/7] Creating ZIP package..." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

$zipFile = Get-Item $outputZip
$zipSizeMB = [math]::Round($zipFile.Length / 1MB, 2)

# Clean up temp directory
Remove-Item -Recurse -Force $tempDir

# Done
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "                Package Created Successfully!                       " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package Info:" -ForegroundColor Cyan
Write-Host "  File: $outputZip" -ForegroundColor White
Write-Host "  Size: $zipSizeMB MB" -ForegroundColor White
Write-Host "  Path: $($zipFile.FullName)" -ForegroundColor White
Write-Host ""

# Verify contents
Write-Host "Package Contents:" -ForegroundColor Cyan
Expand-Archive -Path $outputZip -DestinationPath "temp_verify" -Force
$dirs = Get-ChildItem -Path "temp_verify" -Recurse -Directory | Select-Object -First 10
foreach ($dir in $dirs) {
    $relativePath = $dir.FullName.Replace((Get-Item "temp_verify").FullName, "").TrimStart("\")
    if ($relativePath) {
        Write-Host "  - $relativePath/" -ForegroundColor Gray
    }
}
$fileCount = (Get-ChildItem -Path "temp_verify" -Recurse -File).Count
Write-Host "  Total files: $fileCount" -ForegroundColor White

# Check for deployment scripts
$hasDeployNow = Test-Path "temp_verify\deploy-now.sh"
$hasQuickDeploy = Test-Path "temp_verify\quick-deploy.sh"
$hasArmTemplate = Test-Path "temp_verify\azuredeploy.json"

Write-Host ""
Write-Host "Deployment Scripts:" -ForegroundColor Cyan
Write-Host "  deploy-now.sh:     $(if($hasDeployNow){'âœ?Included'}else{'âœ?Missing'})" -ForegroundColor $(if($hasDeployNow){'Green'}else{'Red'})
Write-Host "  quick-deploy.sh:   $(if($hasQuickDeploy){'âœ?Included'}else{'âœ?Missing'})" -ForegroundColor $(if($hasQuickDeploy){'Green'}else{'Red'})
Write-Host "  azuredeploy.json:  $(if($hasArmTemplate){'âœ?Included'}else{'âœ?Missing'})" -ForegroundColor $(if($hasArmTemplate){'Green'}else{'Red'})

Remove-Item -Recurse -Force "temp_verify"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Upload $outputZip to Azure Cloud Shell" -ForegroundColor White
Write-Host "  2. Extract: unzip $outputZip -d mediagenie-deploy" -ForegroundColor White
Write-Host "  3. Deploy: cd mediagenie-deploy && chmod +x deploy-now.sh && ./deploy-now.sh" -ForegroundColor White
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

