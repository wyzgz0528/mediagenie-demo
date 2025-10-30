# Simple MediaGenie Deployment Package Creator

$OutputName = "MediaGenie-Azure-Deploy"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempDir = ".\temp_deploy_$timestamp"
$outputZip = "$OutputName.zip"

Write-Host "Creating deployment package: $outputZip" -ForegroundColor Green

# Create temp directory
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy backend
Write-Host "Copying backend..." -ForegroundColor Yellow
$backendDir = Join-Path $tempDir "backend"
New-Item -ItemType Directory -Path $backendDir -Force | Out-Null

if (Test-Path "backend\media-service") {
    Copy-Item -Path "backend\media-service" -Destination $backendDir -Recurse -Force -Exclude @("__pycache__", "*.pyc", "*.log", "venv", "node_modules")
    Write-Host "  - Copied backend/media-service" -ForegroundColor Gray

    # Clean up pycache and logs in the copied directory
    Get-ChildItem -Path "$backendDir\media-service" -Include "__pycache__","*.pyc","*.log" -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "  - Cleaned up cache and logs" -ForegroundColor Gray
}

# Copy frontend build if exists
if (Test-Path "frontend\build") {
    Write-Host "Copying frontend build..." -ForegroundColor Yellow
    $frontendDir = Join-Path $tempDir "frontend"
    New-Item -ItemType Directory -Path $frontendDir -Force | Out-Null
    Copy-Item -Path "frontend\build" -Destination $frontendDir -Recurse -Force
    Write-Host "  - Copied frontend/build" -ForegroundColor Gray
}

# Copy deployment scripts
Write-Host "Copying deployment scripts..." -ForegroundColor Yellow

$filesToCopy = @(
    "deploy-cloudshell.sh",
    "azuredeploy.json",
    "azuredeploy.parameters.json",
    "docker-compose.yml",
    "Dockerfile",
    "README.md",
    "README_MARKETPLACE.md",
    "MARKETPLACE_DEPLOYMENT_GUIDE.md",
    "AZURE_DEPLOYMENT_INSTRUCTIONS.md"
)

foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination $tempDir -Force
        Write-Host "  - Copied $file" -ForegroundColor Gray
    }
}

# Copy directories
$dirsToCopy = @("azure-deploy", "azure-marketplace")
foreach ($dir in $dirsToCopy) {
    if (Test-Path $dir) {
        Copy-Item -Path $dir -Destination $tempDir -Recurse -Force
        Write-Host "  - Copied $dir/" -ForegroundColor Gray
    }
}

# Create README
Write-Host "Creating deployment README..." -ForegroundColor Yellow
$readme = @"
MediaGenie Azure Deployment Package

Quick Start:
1. Upload this zip to Azure Cloud Shell
2. Unzip: unzip $outputZip
3. Edit config: code deploy-cloudshell.sh
4. Deploy: chmod +x deploy-cloudshell.sh && ./deploy-cloudshell.sh

See AZURE_DEPLOYMENT_INSTRUCTIONS.md for details.
"@

$readme | Out-File -FilePath (Join-Path $tempDir "DEPLOY_README.txt") -Encoding UTF8

# Create ZIP
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

$zipSize = (Get-Item $outputZip).Length / 1MB
$zipSizeStr = "{0:N2}" -f $zipSize

Write-Host "Created: $outputZip ($zipSizeStr MB)" -ForegroundColor Green

# Cleanup
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "Deployment package ready!" -ForegroundColor Green
Write-Host "File: $outputZip" -ForegroundColor White
Write-Host "Size: $zipSizeStr MB" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open Azure Cloud Shell: https://shell.azure.com" -ForegroundColor White
Write-Host "2. Upload $outputZip" -ForegroundColor White
Write-Host "3. Follow instructions in DEPLOY_README.txt" -ForegroundColor White

