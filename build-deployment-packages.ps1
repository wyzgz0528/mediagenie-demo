# MediaGenie Deployment Package Builder
# Generates all required deployment files, bypassing Cloud Shell timeouts

param(
    [string]$OutputDir = "deploy",
    [switch]$SkipFrontendBuild,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDirFull = Join-Path $ScriptRoot $OutputDir

function Write-Step {
    param([string]$Message)
    Write-Host "`n==========  $Message  ==========" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Format-SizeMB {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return "0.00"
    }

    $sizeMb = (Get-Item $Path).Length / 1MB
    return "{0:F2}" -f $sizeMb
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# ====================================
# 1. Environment Check
# ====================================
Write-Step "Checking Build Environment"

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python: $pythonVersion"
} catch {
    Write-Error-Custom "Python not found, please install Python 3.9+"
    exit 1
}

# Check Node.js (if frontend build needed)
if (-not $SkipFrontendBuild) {
    try {
        $nodeVersion = node --version 2>&1
        Write-Success "Node.js: $nodeVersion"
    } catch {
        Write-Error-Custom "Node.js not found, please install or use -SkipFrontendBuild"
        exit 1
    }
}

# Create output directory
if (Test-Path $OutputDirFull) {
    Write-Info "Cleaning old deployment files..."
    Remove-Item $OutputDirFull -Recurse -Force
}
Ensure-Directory $OutputDirFull
Write-Success "Output directory: $OutputDirFull"

# ====================================
# 2. Package Marketplace Portal
# ====================================
Write-Step "Packaging Marketplace Portal"

Push-Location marketplace-portal

# Create virtual environment and install dependencies
Write-Info "Installing Python dependencies to .python_packages..."
if (Test-Path ".venv") { Remove-Item ".venv" -Recurse -Force }
if (Test-Path ".python_packages") { Remove-Item ".python_packages" -Recurse -Force }

python -m venv .venv
& .\.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt `
    --target ".python_packages/lib/site-packages" --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Dependency installation failed"
    Pop-Location
    exit 1
}

# Package
Write-Info "Creating ZIP package..."
$exclude = @('.venv', '__pycache__', '*.pyc', 'logs')
$files = Get-ChildItem -Force | Where-Object {
    $name = $_.Name
    $exclude -notcontains $name -and $name -notlike '*.pyc'
}

$portalZip = Join-Path $OutputDirFull "marketplace-portal.zip"
Compress-Archive -Path $files.FullName -DestinationPath $portalZip -Force

# Cleanup
Remove-Item ".venv" -Recurse -Force -ErrorAction SilentlyContinue

Pop-Location
$portalSize = Format-SizeMB $portalZip
Write-Success "Marketplace Portal: $portalZip"
Write-Info "   Size: $portalSize MB"

# ====================================
# 3. Package Backend API
# ====================================
Write-Step "Packaging Backend API"

Push-Location backend/media-service

# Install dependencies
Write-Info "Installing Python dependencies to .python_packages..."
if (Test-Path ".venv") { Remove-Item ".venv" -Recurse -Force }
if (Test-Path ".python_packages") { Remove-Item ".python_packages" -Recurse -Force }

python -m venv .venv
& .\.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt `
    --target ".python_packages/lib/site-packages" --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Dependency installation failed"
    Pop-Location
    exit 1
}

# Package
Write-Info "Creating ZIP package..."
$exclude = @('.venv', '__pycache__', '*.pyc', 'logs')
$files = Get-ChildItem -Force | Where-Object {
    $name = $_.Name
    $exclude -notcontains $name -and $name -notlike '*.pyc'
}

$backendZip = Join-Path $OutputDirFull "backend-api.zip"
Compress-Archive -Path $files.FullName -DestinationPath $backendZip -Force

# Cleanup
Remove-Item ".venv" -Recurse -Force -ErrorAction SilentlyContinue

Pop-Location
$backendSize = Format-SizeMB $backendZip
Write-Success "Backend API: $backendZip"
Write-Info "   Size: $backendSize MB"

# ====================================
# 4. Build and Package Frontend
# ====================================
if (-not $SkipFrontendBuild) {
    Write-Step "Building Frontend Application"
    
    Push-Location frontend
    
    # Install dependencies
    Write-Info "Installing Node.js dependencies..."
    npm install --silent
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "npm install failed"
        Pop-Location
        exit 1
    }
    
    # Production build
    Write-Info "Running production build..."
    npm run build --silent
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Build failed"
        Pop-Location
        exit 1
    }
    
    # Package
    Write-Info "Creating ZIP package..."
    $frontendZip = Join-Path $OutputDirFull "frontend-build.zip"
    Compress-Archive -Path build/* -DestinationPath $frontendZip -Force
    
    Pop-Location
    $frontendSize = Format-SizeMB $frontendZip
    Write-Success "Frontend: $frontendZip"
    Write-Info "   Size: $frontendSize MB"
} else {
    Write-Info 'Skipping frontend build (-SkipFrontendBuild)'
}

# ====================================
# 5. Copy ARM Templates
# ====================================
Write-Step "Preparing ARM Templates"

Copy-Item (Join-Path $ScriptRoot "arm-templates/azuredeploy.json") (Join-Path $OutputDirFull "azuredeploy-optimized.json")
Copy-Item (Join-Path $ScriptRoot "arm-templates/azuredeploy.parameters.json") (Join-Path $OutputDirFull "azuredeploy.parameters.json") -ErrorAction SilentlyContinue
Copy-Item (Join-Path $ScriptRoot "arm-templates/createUiDefinition.json") (Join-Path $OutputDirFull "createUiDefinition.json") -ErrorAction SilentlyContinue

Write-Success "ARM templates copied"

# ====================================
# 6. Generate Deployment Manifest
# ====================================
Write-Step "Generating Deployment Manifest"

Ensure-Directory $OutputDirFull

$manifest = @"
# MediaGenie Deployment Manifest
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Package Contents
- marketplace-portal.zip  (Marketplace Landing Page + Webhook)
- backend-api.zip         (FastAPI Media Processing Service)
- frontend-build.zip      (React Frontend Production Build)
- azuredeploy-optimized.json (ARM Template)

## Next Steps
Please refer to MANUAL_DEPLOYMENT_GUIDE.md for deployment instructions

## Quick Deployment Commands
```bash
# 1. Deploy Infrastructure
az deployment group create \
  --resource-group MediaGenie-Marketplace-RG \
  --template-file deploy/azuredeploy-optimized.json \
  --parameters appNamePrefix=mediagenie

# 2. Deploy Applications
az webapp deploy --resource-group MediaGenie-Marketplace-RG \
  --name <marketplace-app-name> \
  --src-path deploy/marketplace-portal.zip \
  --type zip

az webapp deploy --resource-group MediaGenie-Marketplace-RG \
  --name <backend-app-name> \
  --src-path deploy/backend-api.zip \
  --type zip

# 3. Deploy Frontend
az storage blob upload-batch \
  --account-name <storage-account-name> \
  --destination '\$web' \
  --source deploy/frontend-build
```

## Verification
- Marketplace Portal: https://<marketplace-app>.azurewebsites.net
- Backend API: https://<backend-app>.azurewebsites.net/health
- Frontend: https://<storage-account>.z1.web.core.windows.net

"@

$manifest | Out-File -FilePath (Join-Path $OutputDirFull "DEPLOYMENT_MANIFEST.md") -Encoding utf8

# ====================================
# 7. Summary
# ====================================
Write-Step "Build Complete"

Write-Host "`n[PACKAGES] Deployment packages generated:" -ForegroundColor Green
Get-ChildItem $OutputDirFull | ForEach-Object {
    $size = if ($_.PSIsContainer) { "Directory" } else { "$([math]::Round($_.Length / 1MB, 2)) MB" }
    Write-Host "   - $($_.Name) ($size)"
}

# Copy .env.template to deploy folder for reference
if (Test-Path (Join-Path $ScriptRoot ".env.template")) {
    Copy-Item (Join-Path $ScriptRoot ".env.template") (Join-Path $OutputDirFull ".env.template") -Force
    Write-Info "Copied .env.template to deploy folder"
}

# Copy deploy script to deploy folder
if (Test-Path (Join-Path $ScriptRoot "deploy-to-azure.sh")) {
    Copy-Item (Join-Path $ScriptRoot "deploy-to-azure.sh") (Join-Path $OutputDirFull "deploy-to-azure.sh") -Force
    Write-Info "Copied deploy-to-azure.sh to deploy folder"
}

Write-Host "`n[NEXT STEPS]:" -ForegroundColor Yellow
Write-Host "   1. Copy .env.template to .env and fill in your Azure credentials"
Write-Host "   2. Upload deploy folder (with .env) to Azure Cloud Shell"
Write-Host "   3. Run: chmod +x deploy-to-azure.sh && ./deploy-to-azure.sh"
Write-Host "`n[SUCCESS] Deployment ready!`n" -ForegroundColor Cyan
