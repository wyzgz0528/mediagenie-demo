# MediaGenie FINAL FIXED Package Creator
# This version fixes BOTH startup.txt AND deploy.sh line ending issues

$ErrorActionPreference = "Stop"

# Generate timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "mediagenie-v2-$timestamp"
$tempDir = "temp_$packageName"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MediaGenie V2 Package Creator" -ForegroundColor Cyan
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

    # [3/8] Create requirements.txt (UTF-8 no BOM)
    Write-Host "[3/8] Creating requirements.txt..." -NoNewline
    $requirementsContent = "fastapi>=0.104.0`nuvicorn[standard]>=0.23.0`ngunicorn>=21.2.0`npython-multipart>=0.0.6`nazure-cognitiveservices-speech>=1.30.0`nazure-cognitiveservices-vision-computervision>=0.9.0`nazure-storage-blob>=12.0.0`nazure-identity>=1.14.0`nopenai>=1.0.0`npydantic>=2.0.0`npython-dotenv>=1.0.0`nrequests>=2.31.0`npillow>=10.0.0`nnumpy>=1.24.0`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText("$tempDir/backend/requirements.txt", $requirementsContent, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [4/8] Create startup.txt (UTF-8 no BOM, Unix LF)
    Write-Host "[4/8] Creating startup.txt (Unix LF)..." -NoNewline
    $startupContent = "gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 --timeout 600 main:app`n"
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
    
    $packageJson = "{`n  `"name`": `"mediagenie-frontend`",`n  `"version`": `"1.0.0`",`n  `"private`": true,`n  `"dependencies`": {`n    `"express`": `"^4.18.2`"`n  },`n  `"scripts`": {`n    `"start`": `"node server.js`"`n  }`n}`n"
    [System.IO.File]::WriteAllText("$tempDir/frontend/package.json", $packageJson, $utf8NoBom)
    
    $serverJs = "const express = require('express');`nconst path = require('path');`nconst app = express();`nconst port = process.env.PORT || 8080;`n`napp.use(express.static(path.join(__dirname)));`napp.get('*', (req, res) => {`n  res.sendFile(path.join(__dirname, 'index.html'));`n});`n`napp.listen(port, '0.0.0.0', () => {`n  console.log('Frontend server listening on port ' + port);`n});`n"
    [System.IO.File]::WriteAllText("$tempDir/frontend/server.js", $serverJs, $utf8NoBom)
    Write-Host " OK" -ForegroundColor Green

    # [7/8] Create deployment script (CRITICAL: Unix LF only!)
    Write-Host "[7/8] Creating deployment script (Unix LF)..." -NoNewline
    $deployScript = "#!/bin/bash`nset -e`n`necho `"==================================`"`necho `"MediaGenie V2 Deployment`"`necho `"==================================`"`necho `"`"`n`nTIMESTAMP=`$(date +%Y%m%d%H%M%S)`nRESOURCE_GROUP=`"mediagenie-rg-v2-`$TIMESTAMP`"`nLOCATION=`"eastus`"`nBACKEND_NAME=`"mediagenie-api-v2-`$TIMESTAMP`"`n`necho `"[1/5] Creating resource group...`"`naz group create --name `$RESOURCE_GROUP --location `$LOCATION --output table`n`necho `"[2/5] Creating App Service Plan (B1)...`"`naz appservice plan create --name `"`$RESOURCE_GROUP-plan`" --resource-group `$RESOURCE_GROUP --sku B1 --is-linux --output table`n`necho `"[3/5] Creating backend web app (Python 3.10)...`"`naz webapp create --resource-group `$RESOURCE_GROUP --plan `"`$RESOURCE_GROUP-plan`" --name `$BACKEND_NAME --runtime `"PYTHON:3.10`" --output table`n`necho `"[4/5] Configuring backend app settings...`"`naz webapp config appsettings set --name `$BACKEND_NAME --resource-group `$RESOURCE_GROUP --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true ENABLE_ORYX_BUILD=true --output table`n`necho `"[5/5] Setting startup command...`"`naz webapp config set --name `$BACKEND_NAME --resource-group `$RESOURCE_GROUP --startup-file `"startup.txt`" --output table`n`necho `"`"`necho `"Deploying backend (5-10 minutes)...`"`ncd backend`nzip -r ../backend.zip . -q`ncd ..`naz webapp deployment source config-zip --resource-group `$RESOURCE_GROUP --name `$BACKEND_NAME --src backend.zip --timeout 600`n`necho `"`"`necho `"==================================`"`necho `"Deployment Complete!`"`necho `"==================================`"`necho `"`"`necho `"Backend URL: https://`$BACKEND_NAME.azurewebsites.net`"`necho `"API Docs: https://`$BACKEND_NAME.azurewebsites.net/docs`"`necho `"Health Check: https://`$BACKEND_NAME.azurewebsites.net/health`"`necho `"`"`necho `"Waiting 90 seconds for app to start...`"`nsleep 90`necho `"`"`necho `"Testing health endpoint...`"`ncurl -f `"https://`$BACKEND_NAME.azurewebsites.net/health`" && echo `"`" && echo `"SUCCESS!`" || echo `"FAILED - check logs`"`necho `"`"`n"
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
    Write-Host "V2 PACKAGE CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    Write-Host "Package: $zipPath ($zipSize KB)" -ForegroundColor Cyan
    Write-Host "`nCRITICAL FIXES:" -ForegroundColor Yellow
    Write-Host "  1. startup.txt: UTF-8 no BOM, Unix LF" -ForegroundColor White
    Write-Host "  2. deploy.sh: Unix LF line endings" -ForegroundColor White
    Write-Host "  3. All text files: Unix LF format" -ForegroundColor White
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Upload $zipPath to Cloud Shell" -ForegroundColor White
    Write-Host "  2. rm -rf deploy && unzip $zipPath -d deploy" -ForegroundColor White
    Write-Host "  3. cd deploy && chmod +x scripts/deploy.sh && bash scripts/deploy.sh" -ForegroundColor White
    Write-Host "`n" -ForegroundColor White

} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    exit 1
}
