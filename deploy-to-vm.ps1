# Deploy MediaGenie to Azure VM
# VM IP: 13.92.133.12
# User: azure
# Password: p@ssw0rd2025

Write-Host "========================================" -ForegroundColor Green
Write-Host "   Deploy MediaGenie to Azure VM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$vmIP = "13.92.133.12"
$vmUser = "azure"
$vmPassword = "p@ssw0rd2025"

Write-Host "[INFO] VM Details:" -ForegroundColor Yellow
Write-Host "  IP: $vmIP" -ForegroundColor Cyan
Write-Host "  User: $vmUser" -ForegroundColor Cyan
Write-Host "  OS: Ubuntu 24.04" -ForegroundColor Cyan
Write-Host ""

# Check if SSH is available
Write-Host "[1/8] Checking SSH connectivity..." -ForegroundColor Yellow
$sshTest = Test-NetConnection -ComputerName $vmIP -Port 22 -WarningAction SilentlyContinue
if ($sshTest.TcpTestSucceeded) {
    Write-Host "[OK] SSH port 22 is open" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Cannot connect to SSH port 22" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. VM is running" -ForegroundColor Yellow
    Write-Host "  2. NSG allows SSH (port 22)" -ForegroundColor Yellow
    Write-Host "  3. Public IP is correct" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "   Manual Deployment Steps" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Since PowerShell SSH is complex, please follow these manual steps:" -ForegroundColor White
Write-Host ""

Write-Host "[Step 1] Connect to VM via SSH" -ForegroundColor Green
Write-Host "Run this command in a new terminal:" -ForegroundColor White
Write-Host ""
Write-Host "  ssh azure@13.92.133.12" -ForegroundColor Cyan
Write-Host ""
Write-Host "Password: p@ssw0rd2025" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 2] Install Docker on VM" -ForegroundColor Green
Write-Host "Run these commands on the VM:" -ForegroundColor White
Write-Host ""
Write-Host @"
# Update system
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io docker-compose

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker azure

# Verify installation
docker --version
docker-compose --version
"@ -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 3] Transfer project files to VM" -ForegroundColor Green
Write-Host "Run this command from your local machine (in a new PowerShell window):" -ForegroundColor White
Write-Host ""
Write-Host "  scp -r F:\project\MediaGenie1001 azure@13.92.133.12:~/" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or use WinSCP/FileZilla to transfer files" -ForegroundColor Yellow
Write-Host ""

Write-Host "[Step 4] Create .env file on VM" -ForegroundColor Green
Write-Host "On the VM, create .env file:" -ForegroundColor White
Write-Host ""
Write-Host @"
cd ~/MediaGenie1001
nano .env

# Add these lines:
DATABASE_URL=postgresql+asyncpg://dbadmin:YOUR_PASSWORD@mediagenie-db-5428.postgres.database.azure.com:5432/mediagenie
ENVIRONMENT=production
DEBUG=false
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000

# Save and exit (Ctrl+X, Y, Enter)
"@ -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 5] Build and run Docker containers" -ForegroundColor Green
Write-Host "On the VM, run:" -ForegroundColor White
Write-Host ""
Write-Host @"
cd ~/MediaGenie1001

# Build and start containers
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
"@ -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 6] Configure firewall" -ForegroundColor Green
Write-Host "On the VM, open ports:" -ForegroundColor White
Write-Host ""
Write-Host @"
# Allow HTTP traffic
sudo ufw allow 8000/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
"@ -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 7] Configure Azure NSG" -ForegroundColor Green
Write-Host "In Azure Portal:" -ForegroundColor White
Write-Host "  1. Go to your VM's Network Security Group" -ForegroundColor Yellow
Write-Host "  2. Add inbound rules:" -ForegroundColor Yellow
Write-Host "     - Port 8000 (Backend API)" -ForegroundColor Yellow
Write-Host "     - Port 8080 (Frontend)" -ForegroundColor Yellow
Write-Host "     - Port 80 (HTTP)" -ForegroundColor Yellow
Write-Host "     - Port 443 (HTTPS)" -ForegroundColor Yellow
Write-Host ""

Write-Host "[Step 8] Access the application" -ForegroundColor Green
Write-Host "  Backend API:  http://13.92.133.12:8000" -ForegroundColor Cyan
Write-Host "  Backend Docs: http://13.92.133.12:8000/docs" -ForegroundColor Cyan
Write-Host "  Frontend:     http://13.92.133.12:8080" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "   Alternative: Automated Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "I can create an automated deployment script." -ForegroundColor White
Write-Host "Would you like me to create it? (Y/N)" -ForegroundColor Yellow
Write-Host ""

