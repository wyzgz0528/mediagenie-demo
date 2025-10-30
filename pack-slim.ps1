# MediaGenie Slim Package Creator
Write-Host "MediaGenie Slim Package Creator" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check files
if (-not (Test-Path "backend")) { Write-Host "Missing backend folder" -ForegroundColor Red; exit 1 }
if (-not (Test-Path "frontend")) { Write-Host "Missing frontend folder" -ForegroundColor Red; exit 1 }
if (-not (Test-Path "deploy-marketplace-complete.sh")) { Write-Host "Missing deploy script" -ForegroundColor Red; exit 1 }

Write-Host "Creating slim package (excluding node_modules, build, etc.)" -ForegroundColor Yellow

# Create temp directory
$temp = "temp_slim"
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item $temp -ItemType Directory | Out-Null

# Copy backend (Python files only)
Write-Host "Copying backend..." -ForegroundColor White
$backendDest = "$temp\backend"
robocopy backend $backendDest *.py *.txt *.json *.md /S /NFL /NDL /NC /NS /NP

# Copy frontend source (no node_modules, no build)
Write-Host "Copying frontend source..." -ForegroundColor White  
$frontendDest = "$temp\frontend"
robocopy frontend $frontendDest *.json *.js *.ts *.tsx *.html *.css *.md /S /XD node_modules build dist .git coverage /NFL /NDL /NC /NS /NP

# Copy deploy scripts
Write-Host "Copying deploy scripts..." -ForegroundColor White
Copy-Item "deploy-marketplace-complete.sh" $temp
if (Test-Path "deploy-marketplace-powershell.ps1") {
    Copy-Item "deploy-marketplace-powershell.ps1" $temp
}
if (Test-Path "deploy-quota-friendly.sh") {
    Copy-Item "deploy-quota-friendly.sh" $temp
}
if (Test-Path "deploy-quota-friendly-powershell.ps1") {
    Copy-Item "deploy-quota-friendly-powershell.ps1" $temp
}
if (Test-Path "diagnose-quota.ps1") {
    Copy-Item "diagnose-quota.ps1" $temp
}

# Create slim zip
$zipName = "mediagenie-slim-$(Get-Date -Format 'yyyyMMdd-HHmm').zip"
Write-Host "Creating zip: $zipName" -ForegroundColor Yellow

Compress-Archive -Path "$temp\*" -DestinationPath $zipName -CompressionLevel Optimal -Force

# Show results
$size = Get-Item $zipName
$sizeMB = [math]::Round($size.Length / 1MB, 2)
$sizeKB = [math]::Round($size.Length / 1KB, 0)

Write-Host ""
Write-Host "SUCCESS!" -ForegroundColor Green
Write-Host "File: $zipName" -ForegroundColor Cyan
Write-Host "Size: $sizeMB MB ($sizeKB KB)" -ForegroundColor Cyan
Write-Host ""
Write-Host "What's included:" -ForegroundColor Yellow
Write-Host "- backend/ (Python files only)" -ForegroundColor White
Write-Host "- frontend/ (source code, NO node_modules)" -ForegroundColor White  
Write-Host "- deploy scripts" -ForegroundColor White
Write-Host ""
Write-Host "Cloud Shell Steps:" -ForegroundColor Yellow
Write-Host "1. Upload: $zipName" -ForegroundColor Gray
Write-Host "2. Extract: Expand-Archive ~/$zipName ~/mediagenie -Force" -ForegroundColor Gray
Write-Host "3. Install: cd ~/mediagenie/frontend && npm install && npm run build" -ForegroundColor Gray
Write-Host "4. Deploy: cd ~/mediagenie && ./deploy-marketplace-powershell.ps1" -ForegroundColor Gray

# Cleanup
Remove-Item $temp -Recurse -Force
Write-Host ""
Write-Host "Slim package ready for upload!" -ForegroundColor Green