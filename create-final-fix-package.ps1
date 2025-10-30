# MediaGenie FINAL Working Package Creator
# This version fixes the BOM encoding issue in startup.txt

$ErrorActionPreference = "Stop"

# Generate timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "mediagenie-final-$timestamp"
$tempDir = "temp_$packageName"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MediaGenie FINAL Package Creator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # [1/8] Create directory structure
    Write-Host "[1/8] Creating directories..." -NoNewline
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$tempDir/backend" | Out-Null
    New-Item -ItemType Directory -Force -Path "$tempDir/frontend" | Out-Null
    New-Item -ItemType Directory -Force -Path "$tempDir/scripts" | Out-Null
    Write-Host " OK" -ForegroundColor Green

    # [2/8] Copy backend files
    Write-Host "[2/8] Copying backend files..." -NoNewline
    Copy-Item "backend/media-service/main.py" "$tempDir/backend/main.py" -Force
    Copy-Item "backend/media-service/marketplace.py" "$tempDir/backend/marketplace.py" -Force
    Copy-Item "backend/media-service/.env" "$tempDir/backend/.env" -Force
    Write-Host " OK" -ForegroundColor Green

    # [3/8] Create requirements.txt
    Write-Host "[3/8] Creating requirements.txt..." -NoNewline
    $requirementsContent = @"
fastapi>=0.104.0
uvicorn[standard]>=0.23.0
gunicorn>=21.2.0
python-multipart>=0.0.6
azure-cognitiveservices-speech>=1.30.0
azure-cognitiveservices-vision-computervision>=0.9.0
azure-storage-blob>=12.0.0
azure-identity>=1.14.0
openai>=1.0.0
pydantic>=2.0.0
python-dotenv>=1.0.0
requests>=2.31.0
pillow>=10.0.0
numpy>=1.24.0
"@
    # CRITICAL: Use UTF8 without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText("$tempDir/backend/requirements.txt", $requirementsContent, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [4/8] Create startup.txt WITHOUT BOM
    Write-Host "[4/8] Creating startup.txt (UTF-8 NO BOM)..." -NoNewline
    $startupContent = "gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 --timeout 600 main:app"
    # CRITICAL: Use UTF8 without BOM
    [System.IO.File]::WriteAllText("$tempDir/backend/startup.txt", $startupContent, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [5/8] Copy frontend build
    Write-Host "[5/8] Copying frontend build..." -NoNewline
    $frontendBuildPath = "frontend/build"
    if (Test-Path $frontendBuildPath) {
        Copy-Item -Path "$frontendBuildPath/*" -Destination "$tempDir/frontend" -Recurse -Force
        $fileCount = (Get-ChildItem $tempDir/frontend -Recurse | Measure-Object).Count
        Write-Host " OK ($fileCount files)" -ForegroundColor Green
    } else {
        Write-Host " WARNING: React build not found" -ForegroundColor Yellow
    }

    # [6/8] Create frontend configuration
    Write-Host "[6/8] Creating frontend config..." -NoNewline
    
    # Create package.json
    $packageJson = @"
{
  "name": "mediagenie-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "express": "^4.18.2"
  },
  "scripts": {
    "start": "node server.js"
  }
}
"@
    [System.IO.File]::WriteAllText("$tempDir/frontend/package.json", $packageJson, $utf8NoBom)
    
    # Create server.js
    $serverJs = @"
const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 8080;

app.use(express.static(path.join(__dirname)));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(port, '0.0.0.0', () => {
  console.log('Frontend server listening on port ' + port);
});
"@
    [System.IO.File]::WriteAllText("$tempDir/frontend/server.js", $serverJs, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [7/8] Create deployment script
    Write-Host "[7/8] Creating deployment script..." -NoNewline
    $deployScript = @"
#!/bin/bash
set -e

echo "=================================="
echo "MediaGenie FINAL Deployment"
echo "=================================="
echo ""

TIMESTAMP=`$(date +%Y%m%d%H%M%S)
RESOURCE_GROUP="mediagenie-rg-final-`$TIMESTAMP"
LOCATION="eastus"
BACKEND_NAME="mediagenie-api-final-`$TIMESTAMP"

echo "[1/5] Creating resource group..."
az group create --name `$RESOURCE_GROUP --location `$LOCATION --output table

echo "[2/5] Creating App Service Plan (B1)..."
az appservice plan create \
  --name "`$RESOURCE_GROUP-plan" \
  --resource-group `$RESOURCE_GROUP \
  --sku B1 \
  --is-linux \
  --output table

echo "[3/5] Creating backend web app (Python 3.10)..."
az webapp create \
  --resource-group `$RESOURCE_GROUP \
  --plan "`$RESOURCE_GROUP-plan" \
  --name `$BACKEND_NAME \
  --runtime "PYTHON:3.10" \
  --output table

echo "[4/5] Configuring backend app settings..."
az webapp config appsettings set \
  --name `$BACKEND_NAME \
  --resource-group `$RESOURCE_GROUP \
  --settings \
    SCM_DO_BUILD_DURING_DEPLOYMENT=true \
    ENABLE_ORYX_BUILD=true \
  --output table

echo "[5/5] Setting startup command..."
az webapp config set \
  --name `$BACKEND_NAME \
  --resource-group `$RESOURCE_GROUP \
  --startup-file "startup.txt" \
  --output table

echo ""
echo "Deploying backend (5-10 minutes)..."
cd backend
zip -r ../backend.zip . -q
cd ..
az webapp deployment source config-zip \
  --resource-group `$RESOURCE_GROUP \
  --name `$BACKEND_NAME \
  --src backend.zip \
  --timeout 600

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Backend URL: https://`$BACKEND_NAME.azurewebsites.net"
echo "API Docs: https://`$BACKEND_NAME.azurewebsites.net/docs"
echo "Health Check: https://`$BACKEND_NAME.azurewebsites.net/health"
echo ""
echo "Waiting 90 seconds for app to start..."
sleep 90
echo ""
echo "Testing health endpoint..."
curl -f "https://`$BACKEND_NAME.azurewebsites.net/health" && echo "" && echo "SUCCESS!" || echo "FAILED - check logs"
echo ""
"@
    [System.IO.File]::WriteAllText("$tempDir/scripts/deploy.sh", $deployScript, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [8/8] Create ZIP package
    Write-Host "[8/8] Creating ZIP package..." -NoNewline
    $zipPath = "$packageName.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path "$tempDir/*" -DestinationPath $zipPath -Force
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
    Write-Host " OK ($zipSize KB)" -ForegroundColor Green

    # Cleanup
    Remove-Item -Path $tempDir -Recurse -Force

    # Summary
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "FINAL PACKAGE CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    Write-Host "Package: $zipPath ($zipSize KB)" -ForegroundColor Cyan
    Write-Host "`nCRITICAL FIX:" -ForegroundColor Yellow
    Write-Host "  - Fixed BOM encoding issue in startup.txt" -ForegroundColor White
    Write-Host "  - All files now use UTF-8 without BOM" -ForegroundColor White
    Write-Host "  - This was causing 'gunicorn: not found' error" -ForegroundColor White
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Upload $zipPath to Cloud Shell" -ForegroundColor White
    Write-Host "  2. Extract: unzip $zipPath -d deploy" -ForegroundColor White
    Write-Host "  3. Deploy: cd deploy && chmod +x scripts/deploy.sh && bash scripts/deploy.sh" -ForegroundColor White
    Write-Host "  4. Wait for success message!" -ForegroundColor White
    Write-Host "`n" -ForegroundColor White

} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    exit 1
}
