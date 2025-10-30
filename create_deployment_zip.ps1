# Create MediaGenie Deployment ZIP for Azure App Service

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "mediagenie-deployment.zip"
)

Write-Host "=== Creating MediaGenie Deployment ZIP ===" -ForegroundColor Green
Write-Host "This will create a ZIP file for Azure App Service deployment."
Write-Host ""

# Files and directories to include
$includePaths = @(
    "backend/media-service",
    "marketplace-portal",
    "frontend/build",
    "nginx-demo.conf",
    "supervisord-demo.conf",
    "Dockerfile.demo",
    "requirements.txt",
    "package.json",
    "README.md",
    "AZURE_DEMO_DEPLOYMENT.md"
)

# Files to exclude (patterns)
$excludePatterns = @(
    "*.git*",
    "*node_modules*",
    "*__pycache__*",
    "*.env*",
    "*logs*",
    "*.log",
    "*.tmp",
    "*.swp",
    "*.DS_Store",
    "*Thumbs.db"
)

Write-Host "Creating deployment ZIP file..." -ForegroundColor Yellow

# Remove existing ZIP if it exists
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

# Create a temporary directory for staging
$tempDir = "$env:TEMP\mediagenie-deploy-temp"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy files to temp directory
foreach ($path in $includePaths) {
    if (Test-Path $path) {
        $destination = Join-Path $tempDir (Split-Path $path -Leaf)
        if (Test-Path $path -PathType Container) {
            Copy-Item $path $destination -Recurse -Force
        } else {
            Copy-Item $path $destination -Force
        }
        Write-Host "âœ?Copied: $path" -ForegroundColor Green
    } else {
        Write-Host "âš?Skipped (not found): $path" -ForegroundColor Yellow
    }
}

# Clean up unwanted files from temp directory
Get-ChildItem $tempDir -Recurse | Where-Object {
    $fileName = $_.Name
    $excludePatterns | Where-Object { $fileName -like $_ }
} | Remove-Item -Force -Recurse

# Create ZIP file
Compress-Archive -Path "$tempDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

# Get ZIP file info
$zipInfo = Get-Item $OutputPath
$zipSizeMB = [math]::Round($zipInfo.Length / 1MB, 2)

Write-Host ""
Write-Host "ðŸŽ‰ Deployment ZIP created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "ZIP File Details:" -ForegroundColor Cyan
Write-Host "â€?File: $OutputPath" -ForegroundColor White
Write-Host "â€?Size: $zipSizeMB MB" -ForegroundColor White
Write-Host "â€?Created: $($zipInfo.CreationTime)" -ForegroundColor White
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Get-ChildItem $tempDir -Recurse -File | Select-Object FullName | Out-Null  # This was just to populate tempDir, but we already cleaned it up
Write-Host "â€?backend/media-service/ (Python FastAPI app)" -ForegroundColor White
Write-Host "â€?marketplace-portal/ (Flask marketplace portal)" -ForegroundColor White
Write-Host "â€?frontend/build/ (React app build files)" -ForegroundColor White
Write-Host "â€?nginx-demo.conf (Web server config)" -ForegroundColor White
Write-Host "â€?supervisord-demo.conf (Process manager config)" -ForegroundColor White
Write-Host "â€?Dockerfile.demo (Container definition)" -ForegroundColor White
Write-Host "â€?requirements.txt (Python dependencies)" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Upload '$OutputPath' to Azure App Service" -ForegroundColor White
Write-Host "2. Set environment variables in App Service settings" -ForegroundColor White
Write-Host "3. Access your app at the provided URL" -ForegroundColor White
Write-Host ""
Write-Host "Happy deploying! ðŸš€" -ForegroundColor Green