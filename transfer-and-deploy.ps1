# MediaGenie - Transfer and Deploy Script
# This script transfers your .env file and deployment script to the VM

$VM_IP = "13.92.133.12"
$VM_USER = "azure"
$VM_PASSWORD = "p@ssw0rd2025"

Write-Host "=========================================="
Write-Host "MediaGenie - Transfer and Deploy"
Write-Host "=========================================="
Write-Host ""

# Check if .env file exists
if (-not (Test-Path "backend\media-service\.env")) {
    Write-Host "ERROR: backend\media-service\.env file not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure your .env file exists at:"
    Write-Host "  backend\media-service\.env"
    Write-Host ""
    exit 1
}

Write-Host "[1/4] Found .env file with API keys" -ForegroundColor Green
Write-Host ""

# Transfer .env file
Write-Host "[2/4] Transferring .env file to VM..." -ForegroundColor Yellow
Write-Host "Command: scp backend\media-service\.env ${VM_USER}@${VM_IP}:~/backend.env"
Write-Host ""
Write-Host "When prompted, enter password: $VM_PASSWORD"
Write-Host ""

scp backend\media-service\.env ${VM_USER}@${VM_IP}:~/backend.env

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to transfer .env file" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure:"
    Write-Host "  1. You can SSH to the VM: ssh ${VM_USER}@${VM_IP}"
    Write-Host "  2. The password is correct: $VM_PASSWORD"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "[3/4] Transferring deployment script..." -ForegroundColor Yellow

scp deploy-complete.sh ${VM_USER}@${VM_IP}:~/MediaGenie1001/deploy-complete.sh

Write-Host ""
Write-Host "[4/4] Files transferred successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "=========================================="
Write-Host "Next Steps"
Write-Host "=========================================="
Write-Host ""
Write-Host "1. SSH to the VM:"
Write-Host "   ssh ${VM_USER}@${VM_IP}"
Write-Host "   Password: $VM_PASSWORD"
Write-Host ""
Write-Host "2. Run the deployment script:"
Write-Host "   cd ~/MediaGenie1001"
Write-Host "   mv ~/backend.env backend/media-service/.env"
Write-Host "   chmod +x deploy-complete.sh"
Write-Host "   ./deploy-complete.sh"
Write-Host ""
Write-Host "3. Choose deployment method:"
Write-Host "   Option 1: Direct (No Docker) - RECOMMENDED"
Write-Host "   Option 2: Docker"
Write-Host ""
Write-Host "=========================================="
Write-Host ""

# Ask if user wants to open SSH
$response = Read-Host "Do you want to open SSH connection now? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "Opening SSH connection..."
    Write-Host "Password: $VM_PASSWORD"
    Write-Host ""
    ssh ${VM_USER}@${VM_IP}
}

