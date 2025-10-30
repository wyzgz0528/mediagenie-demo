# MediaGenie Simple Package Creator
param(
    [switch]$Verbose
)

Write-Host "=== MediaGenie Package Creator ===" -ForegroundColor Cyan

# 1. Check files
Write-Host "Checking files..." -ForegroundColor Yellow
$missing = @()
if (-not (Test-Path "backend" -PathType Container)) { $missing += "backend/" }
if (-not (Test-Path "frontend" -PathType Container)) { $missing += "frontend/" }
if (-not (Test-Path "deploy-marketplace-complete.sh")) { $missing += "deploy-marketplace-complete.sh" }

if ($missing.Count -gt 0) {
    Write-Host "Missing: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "All files found" -ForegroundColor Green

# 2. Create package name
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$zipFile = "mediagenie-deploy-$timestamp.zip"

# 3. Remove old file
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
    Write-Host "Removed old package" -ForegroundColor Gray
}

# 4. Create package (with progress)
Write-Host "Creating package: $zipFile" -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds..." -ForegroundColor Gray

try {
    # Use Add-Type to load System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    # Create the zip file
    $zipPath = Join-Path (Get-Location) $zipFile
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
    
    # Add items
    $items = @('backend', 'frontend', 'deploy-marketplace-complete.sh')
    foreach ($item in $items) {
        Write-Host "  Adding: $item" -ForegroundColor White
        if (Test-Path $item -PathType Container) {
            # Add directory
            $files = Get-ChildItem $item -Recurse -File
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
                $entry = $zip.CreateEntry($relativePath)
                $entryStream = $entry.Open()
                $fileStream = [System.IO.File]::OpenRead($file.FullName)
                $fileStream.CopyTo($entryStream)
                $fileStream.Close()
                $entryStream.Close()
            }
        } else {
            # Add file
            $entry = $zip.CreateEntry($item)
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::OpenRead($item)
            $fileStream.CopyTo($entryStream)
            $fileStream.Close()
            $entryStream.Close()
        }
    }
    
    $zip.Dispose()
    
    # Show results
    $fileInfo = Get-Item $zipFile
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "File: $zipFile ($sizeMB MB)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next: Upload to Azure Cloud Shell PowerShell" -ForegroundColor Yellow
    Write-Host "1. Portal: https://portal.azure.com" -ForegroundColor White
    Write-Host "2. Cloud Shell > PowerShell mode" -ForegroundColor White
    Write-Host "3. Upload: $zipFile" -ForegroundColor Cyan
    Write-Host "4. Run in Cloud Shell:" -ForegroundColor White
    Write-Host "   New-Item ~/mediagenie -ItemType Directory -Force" -ForegroundColor Gray
    Write-Host "   Expand-Archive ~/$zipFile ~/mediagenie -Force" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}