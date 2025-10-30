# Quick Deploy to Azure - Direct from source
# Usage: .\quick-deploy-to-azure.ps1

param(
    [string]$ResourceGroup = "mediagenie-rg",
    [string]$BackendAppName = "mediagenie-backend",
    [string]$FrontendAppName = "mediagenie-frontend"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Deploy to Azure" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Create backend ZIP
Write-Host "[1/4] Creating backend deployment package..." -ForegroundColor Yellow
$backendPath = ".\backend\media-service"
if (Test-Path "backend-quick.zip") {
    Remove-Item "backend-quick.zip" -Force
}

# Create ZIP with only necessary files
$backendFiles = @(
    "$backendPath\main.py",
    "$backendPath\config.py",
    "$backendPath\database.py",
    "$backendPath\models.py",
    "$backendPath\requirements.txt",
    "$backendPath\marketplace.py",
    "$backendPath\marketplace_webhook.py",
    "$backendPath\auth_middleware.py",
    "$backendPath\tenant_context.py",
    "$backendPath\db_service.py",
    "$backendPath\migrations"
)

# Create temp directory
$tempBackend = ".\temp-backend"
if (Test-Path $tempBackend) {
    Remove-Item $tempBackend -Recurse -Force
}
New-Item -ItemType Directory -Path $tempBackend | Out-Null

# Copy files
foreach ($file in $backendFiles) {
    if (Test-Path $file) {
        $dest = $file -replace "backend\\media-service\\", "$tempBackend\"
        $destDir = Split-Path $dest
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $file $dest -Force -Recurse
    }
}

# Create startup script
$startupScript = @"
#!/bin/bash
cd /home/site/wwwroot
pip install -r requirements.txt
python run_migration.py
gunicorn -w 4 -b 0.0.0.0:8000 main:app
"@
Set-Content -Path "$tempBackend\startup.sh" -Value $startupScript

# Create ZIP
Compress-Archive -Path "$tempBackend\*" -DestinationPath "backend-quick.zip" -Force
Remove-Item $tempBackend -Recurse -Force
Write-Host "OK: backend-quick.zip created" -ForegroundColor Green

# Step 2: Create frontend ZIP
Write-Host "[2/4] Creating frontend deployment package..." -ForegroundColor Yellow
$frontendPath = ".\frontend"
if (Test-Path "frontend-quick.zip") {
    Remove-Item "frontend-quick.zip" -Force
}

$tempFrontend = ".\temp-frontend"
if (Test-Path $tempFrontend) {
    Remove-Item $tempFrontend -Recurse -Force
}
New-Item -ItemType Directory -Path $tempFrontend | Out-Null

# Copy frontend (excluding node_modules)
Copy-Item "$frontendPath\public" "$tempFrontend\public" -Recurse -Force
Copy-Item "$frontendPath\src" "$tempFrontend\src" -Recurse -Force
Copy-Item "$frontendPath\package.json" "$tempFrontend\package.json" -Force
Copy-Item "$frontendPath\package-lock.json" "$tempFrontend\package-lock.json" -Force
Copy-Item "$frontendPath\tsconfig.json" "$tempFrontend\tsconfig.json" -Force
Copy-Item "$frontendPath\nginx.conf" "$tempFrontend\nginx.conf" -Force -ErrorAction SilentlyContinue

# Create startup script
$frontendStartup = @"
#!/bin/bash
cd /home/site/wwwroot
npm install
npm run build
"@
Set-Content -Path "$tempFrontend\startup.sh" -Value $frontendStartup

# Create ZIP
Compress-Archive -Path "$tempFrontend\*" -DestinationPath "frontend-quick.zip" -Force
Remove-Item $tempFrontend -Recurse -Force
Write-Host "OK: frontend-quick.zip created" -ForegroundColor Green

# Step 3: Deploy backend
Write-Host "[3/4] Deploying backend..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $BackendAppName `
    --src backend-quick.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Backend deployed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Backend deployment failed" -ForegroundColor Red
}

# Step 4: Deploy frontend
Write-Host "[4/4] Deploying frontend..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $FrontendAppName `
    --src frontend-quick.zip

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Frontend deployed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Frontend deployment failed" -ForegroundColor Red
}

# Restart apps
Write-Host "Restarting applications..." -ForegroundColor Yellow
az webapp restart --resource-group $ResourceGroup --name $BackendAppName
az webapp restart --resource-group $ResourceGroup --name $FrontendAppName

# Summary
Write-Host "" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend: https://$BackendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Wait 2-3 minutes for apps to start..." -ForegroundColor Yellow
Write-Host "" -ForegroundColor Cyan
Write-Host "Check status:" -ForegroundColor Yellow
Write-Host "Backend Health: https://$BackendAppName.azurewebsites.net/health" -ForegroundColor White
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White

