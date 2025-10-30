# Prepare deployment packages for Azure
# This script creates ZIP files for backend and frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Preparing Deployment Packages" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Create temp directories
$tempDir = ".\deployment-temp"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# ============================================================================
# Prepare Backend Package
# ============================================================================
Write-Host "[1/4] Preparing Backend Package..." -ForegroundColor Yellow

$backendSrc = ".\backend\media-service"
$backendDest = "$tempDir\backend"

if (Test-Path $backendSrc) {
    Copy-Item $backendSrc $backendDest -Recurse -Force
    
    # Remove unnecessary files
    Remove-Item "$backendDest\__pycache__" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$backendDest\.pytest_cache" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$backendDest\*.pyc" -Force -ErrorAction SilentlyContinue
    Remove-Item "$backendDest\logs" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Create startup script for Azure
    $startupScript = @"
#!/bin/bash
pip install -r requirements.txt
python run_migration.py
gunicorn -w 4 -b 0.0.0.0:8000 main:app
"@
    Set-Content -Path "$backendDest\startup.sh" -Value $startupScript
    
    Write-Host "OK: Backend package prepared" -ForegroundColor Green
} else {
    Write-Host "ERROR: Backend source not found" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Prepare Frontend Package
# ============================================================================
Write-Host "[2/4] Preparing Frontend Package..." -ForegroundColor Yellow

$frontendSrc = ".\frontend"
$frontendDest = "$tempDir\frontend"

if (Test-Path $frontendSrc) {
    Copy-Item $frontendSrc $frontendDest -Recurse -Force
    
    # Remove unnecessary files
    Remove-Item "$frontendDest\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$frontendDest\.git" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$frontendDest\.env" -Force -ErrorAction SilentlyContinue
    Remove-Item "$frontendDest\.env.local" -Force -ErrorAction SilentlyContinue
    
    Write-Host "OK: Frontend package prepared" -ForegroundColor Green
} else {
    Write-Host "ERROR: Frontend source not found" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Create ZIP files
# ============================================================================
Write-Host "[3/4] Creating ZIP files..." -ForegroundColor Yellow

# Backend ZIP
if (Test-Path "backend-deploy.zip") {
    Remove-Item "backend-deploy.zip" -Force
}
Compress-Archive -Path "$backendDest\*" -DestinationPath "backend-deploy.zip"
Write-Host "OK: backend-deploy.zip created" -ForegroundColor Green

# Frontend ZIP
if (Test-Path "frontend-deploy.zip") {
    Remove-Item "frontend-deploy.zip" -Force
}
Compress-Archive -Path "$frontendDest\*" -DestinationPath "frontend-deploy.zip"
Write-Host "OK: frontend-deploy.zip created" -ForegroundColor Green

# ============================================================================
# Cleanup
# ============================================================================
Write-Host "[4/4] Cleaning up..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force
Write-Host "OK: Cleanup complete" -ForegroundColor Green

# Summary
Write-Host "" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Packages Ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend Package: backend-deploy.zip" -ForegroundColor White
Write-Host "Frontend Package: frontend-deploy.zip" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "Next: Run deploy-code-to-azure.ps1" -ForegroundColor Yellow

