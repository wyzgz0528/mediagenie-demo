# VSCode Azure Extensions Installation Script
# For VSCode (not Cursor)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VSCode Azure Extensions Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if VSCode is installed
Write-Host "Checking if VSCode is installed..." -ForegroundColor Yellow
$codeExists = Get-Command code -ErrorAction SilentlyContinue
if (-not $codeExists) {
    Write-Host "ERROR: VSCode is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install VSCode first: https://code.visualstudio.com/" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: VSCode is installed" -ForegroundColor Green
Write-Host ""

# List of extensions to install for VSCode
$extensions = @(
    "ms-vscode.azure-account",
    "ms-azuretools.vscode-azureappservice",
    "ms-azuretools.vscode-azureresourcegroups",
    "ms-azuretools.vscode-azuredatabases",
    "ms-azuretools.vscode-azurestorage"
)

Write-Host "Starting Azure extensions installation..." -ForegroundColor Yellow
Write-Host ""

$installed = 0
$failed = 0

foreach ($extension in $extensions) {
    Write-Host "Installing: $extension" -ForegroundColor Cyan
    
    try {
        $output = code --install-extension $extension 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "OK: Installed $extension" -ForegroundColor Green
            $installed++
        }
        else {
            Write-Host "ERROR: Failed to install $extension" -ForegroundColor Red
            Write-Host "Output: $output" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "ERROR: Exception installing $extension" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $failed++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed: $installed extensions" -ForegroundColor Green
Write-Host "Failed: $failed extensions" -ForegroundColor Yellow
Write-Host ""

if ($failed -eq 0) {
    Write-Host "OK: All extensions installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart VSCode" -ForegroundColor White
    Write-Host "2. Press Ctrl + Shift + P to open command palette" -ForegroundColor White
    Write-Host "3. Type 'Azure: Sign In' and press Enter" -ForegroundColor White
    Write-Host "4. Sign in with wangyizhe@intellnet.cn in the browser" -ForegroundColor White
    Write-Host "5. Authorize VSCode to access your Azure account" -ForegroundColor White
}
else {
    Write-Host "WARNING: Some extensions failed to install. Please check the errors above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "For more information, see: VSCODE_AZURE_DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan

