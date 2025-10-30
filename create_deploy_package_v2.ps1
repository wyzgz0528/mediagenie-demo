# MediaGenie Azure Marketplace Deploy Package Creator

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "        MediaGenie Azure Marketplace Package Creator                " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$packageName = "MediaGenie-Marketplace-Deploy"
$tempDir = "temp_marketplace"
$outputZip = "$packageName.zip"

# Step 1: Clean up
Write-Host "[1/6] Cleaning up old files..." -ForegroundColor Yellow
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
if (Test-Path $outputZip) { Remove-Item -Force $outputZip }

# Step 2: Create temp directory
Write-Host "[2/6] Creating temp directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Step 3: Copy backend
Write-Host "[3/6] Copying backend code..." -ForegroundColor Yellow
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
Write-Host "[4/6] Copying frontend build..." -ForegroundColor Yellow
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
Write-Host "[5/6] Copying deployment files..." -ForegroundColor Yellow

if (Test-Path "azuredeploy.json") {
    Copy-Item -Path "azuredeploy.json" -Destination $tempDir -Force
    Write-Host "  - Copied azuredeploy.json" -ForegroundColor Gray
}

if (Test-Path "deploy-cloudshell.sh") {
    Copy-Item -Path "deploy-cloudshell.sh" -Destination $tempDir -Force
    Write-Host "  - Copied deploy-cloudshell.sh" -ForegroundColor Gray
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

# Create .deployment file
$deploymentFile = Join-Path $tempDir ".deployment"
"[config]" | Out-File -FilePath $deploymentFile -Encoding ASCII
"SCM_DO_BUILD_DURING_DEPLOYMENT=true" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
"PROJECT=backend/media-service" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
Write-Host "  - Created .deployment" -ForegroundColor Gray

# Step 6: Create ZIP
Write-Host "[6/6] Creating ZIP package..." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

$zipFile = Get-Item $outputZip
$zipSizeMB = [math]::Round($zipFile.Length / 1MB, 2)

# Clean up temp directory
Remove-Item -Recurse -Force $tempDir

# Done
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "                    Package Created Successfully!                   " -ForegroundColor Green
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
Get-ChildItem -Path "temp_verify" -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Replace((Get-Item "temp_verify").FullName, "").TrimStart("\")
    if ($relativePath) {
        Write-Host "  - $relativePath/" -ForegroundColor Gray
    }
}
$fileCount = (Get-ChildItem -Path "temp_verify" -Recurse -File).Count
Write-Host "  Total files: $fileCount" -ForegroundColor White
Remove-Item -Recurse -Force "temp_verify"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Upload $outputZip to Azure Cloud Shell" -ForegroundColor White
Write-Host "  2. Extract and run deployment script" -ForegroundColor White
Write-Host "  3. Or use ARM template in Azure Portal" -ForegroundColor White
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

