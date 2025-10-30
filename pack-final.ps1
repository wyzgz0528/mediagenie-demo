# MediaGenie Final Package Creator
Write-Host "MediaGenie Final Auto-Deploy Package Creator" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Check files
if (-not (Test-Path "backend")) { Write-Host "Missing backend folder" -ForegroundColor Red; exit 1 }
if (-not (Test-Path "frontend")) { Write-Host "Missing frontend folder" -ForegroundColor Red; exit 1 }
if (-not (Test-Path "deploy-auto.sh")) { Write-Host "Missing auto deploy script" -ForegroundColor Red; exit 1 }

Write-Host "Creating final auto-deploy package..." -ForegroundColor Yellow

# Create temp directory
$temp = "temp_final"
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

# Copy ALL deploy scripts
Write-Host "Copying all deploy scripts..." -ForegroundColor White
Copy-Item "deploy-auto.sh" $temp
Copy-Item "deploy-marketplace-complete.sh" $temp -ErrorAction SilentlyContinue
Copy-Item "VSCode-Azure扩展部署指南.md" $temp -ErrorAction SilentlyContinue

# Create final zip
$zipName = "mediagenie-final-$(Get-Date -Format 'yyyyMMdd-HHmm').zip"
Write-Host "Creating final package: $zipName" -ForegroundColor Yellow

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
Write-Host "- backend/ (Python source only)" -ForegroundColor White
Write-Host "- frontend/ (source code, NO node_modules)" -ForegroundColor White  
Write-Host "- deploy-auto.sh (FULLY AUTOMATED)" -ForegroundColor Green
Write-Host "- VSCode deployment guide" -ForegroundColor White
Write-Host ""
Write-Host "3 Deployment Options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1 - FULLY AUTOMATED (Recommended):" -ForegroundColor Green
Write-Host "1. Upload: $zipName to Cloud Shell" -ForegroundColor Gray
Write-Host "2. Extract: unzip $zipName" -ForegroundColor Gray
Write-Host "3. Switch to Bash mode in Cloud Shell" -ForegroundColor Gray
Write-Host "4. Run: chmod +x deploy-auto.sh && ./deploy-auto.sh" -ForegroundColor Gray
Write-Host "   (No interaction needed! All keys pre-configured)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 2 - VS Code Extensions:" -ForegroundColor Green  
Write-Host "1. Install Azure Tools extension pack" -ForegroundColor Gray
Write-Host "2. Follow VSCode-Azure扩展部署指南.md" -ForegroundColor Gray
Write-Host "3. Deploy with GUI clicks" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3 - Manual Cloud Shell:" -ForegroundColor Green
Write-Host "1. Use deploy-marketplace-complete.sh" -ForegroundColor Gray
Write-Host "2. Set environment variables manually" -ForegroundColor Gray
Write-Host ""

# Cleanup
Remove-Item $temp -Recurse -Force
Write-Host "Final auto-deploy package ready!" -ForegroundColor Green