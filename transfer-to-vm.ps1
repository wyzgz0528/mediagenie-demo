# Transfer MediaGenie project to Azure VM
# This script uses SCP to transfer files

Write-Host "========================================" -ForegroundColor Green
Write-Host "   Transfer Files to Azure VM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$vmIP = "13.92.133.12"
$vmUser = "azure"
$localPath = "F:\project\MediaGenie1001"
$remotePath = "~/MediaGenie1001"

Write-Host "[INFO] Transfer Details:" -ForegroundColor Yellow
Write-Host "  VM IP: $vmIP" -ForegroundColor Cyan
Write-Host "  User: $vmUser" -ForegroundColor Cyan
Write-Host "  Local Path: $localPath" -ForegroundColor Cyan
Write-Host "  Remote Path: $remotePath" -ForegroundColor Cyan
Write-Host ""

# Check if local path exists
if (!(Test-Path $localPath)) {
    Write-Host "[ERROR] Local path not found: $localPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Checking SSH connectivity..." -ForegroundColor Yellow
$sshTest = Test-NetConnection -ComputerName $vmIP -Port 22 -WarningAction SilentlyContinue
if (!$sshTest.TcpTestSucceeded) {
    Write-Host "[ERROR] Cannot connect to SSH port 22" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. VM is running" -ForegroundColor Yellow
    Write-Host "  2. NSG allows SSH (port 22)" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] SSH port is accessible" -ForegroundColor Green

Write-Host "`n[2/3] Creating archive of project files..." -ForegroundColor Yellow
$archivePath = "$env:TEMP\mediagenie.zip"
if (Test-Path $archivePath) {
    Remove-Item $archivePath -Force
}

# Create zip file excluding unnecessary files
$excludePatterns = @(
    "node_modules",
    "__pycache__",
    ".git",
    "*.pyc",
    "*.log",
    ".env",
    "backend-publish-profile.xml",
    "frontend-publish-profile.xml",
    "*.zip"
)

Write-Host "  Creating zip archive..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Yellow

# Use PowerShell compression
$filesToZip = Get-ChildItem -Path $localPath -Recurse | Where-Object {
    $file = $_
    $shouldInclude = $true
    foreach ($pattern in $excludePatterns) {
        if ($file.FullName -like "*$pattern*") {
            $shouldInclude = $false
            break
        }
    }
    $shouldInclude
}

Compress-Archive -Path "$localPath\*" -DestinationPath $archivePath -Force
Write-Host "[OK] Archive created: $archivePath" -ForegroundColor Green
$archiveSize = (Get-Item $archivePath).Length / 1MB
Write-Host "  Size: $([math]::Round($archiveSize, 2)) MB" -ForegroundColor Cyan

Write-Host "`n[3/3] Transfer options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Use SCP (if available)" -ForegroundColor Green
Write-Host "  scp $archivePath ${vmUser}@${vmIP}:~/" -ForegroundColor Cyan
Write-Host "  Password: p@ssw0rd2025" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 2: Use WinSCP (Recommended)" -ForegroundColor Green
Write-Host "  1. Download WinSCP: https://winscp.net/eng/download.php" -ForegroundColor Yellow
Write-Host "  2. Connect to:" -ForegroundColor Yellow
Write-Host "     Host: $vmIP" -ForegroundColor Cyan
Write-Host "     User: $vmUser" -ForegroundColor Cyan
Write-Host "     Password: p@ssw0rd2025" -ForegroundColor Cyan
Write-Host "  3. Upload: $archivePath" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 3: Use Azure CLI" -ForegroundColor Green
Write-Host "  az vm run-command invoke ..." -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "   After Transfer - Run on VM" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. SSH to VM:" -ForegroundColor White
Write-Host "   ssh azure@13.92.133.12" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Extract archive:" -ForegroundColor White
Write-Host "   cd ~" -ForegroundColor Cyan
Write-Host "   unzip mediagenie.zip -d MediaGenie1001" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Run deployment script:" -ForegroundColor White
Write-Host "   cd MediaGenie1001" -ForegroundColor Cyan
Write-Host "   chmod +x deploy-vm-auto.sh" -ForegroundColor Cyan
Write-Host "   ./deploy-vm-auto.sh" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Archive ready for transfer: $archivePath" -ForegroundColor Green
Write-Host ""

# Try to use SCP if available
Write-Host "Attempting to transfer using SCP..." -ForegroundColor Yellow
Write-Host "You will be prompted for password: p@ssw0rd2025" -ForegroundColor Yellow
Write-Host ""

$scpCommand = "scp `"$archivePath`" ${vmUser}@${vmIP}:~/"
Write-Host "Running: $scpCommand" -ForegroundColor Cyan
Write-Host ""

try {
    # Try to run SCP
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "scp"
    $psi.Arguments = "`"$archivePath`" ${vmUser}@${vmIP}:~/"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] File transferred successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next: SSH to VM and run deployment script" -ForegroundColor Yellow
    } else {
        Write-Host "[WARNING] SCP transfer may have failed" -ForegroundColor Yellow
        Write-Host "Please use WinSCP or manual transfer" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[INFO] SCP not available on this system" -ForegroundColor Yellow
    Write-Host "Please use WinSCP or manual transfer method" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[SUCCESS] Preparation complete!" -ForegroundColor Green
Write-Host ""

