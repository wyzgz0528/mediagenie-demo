# MediaGenie Docker Troubleshooting Script
# This script helps diagnose and fix Docker-related issues

Write-Host "=== MediaGenie Docker Troubleshooting ===" -ForegroundColor Green
Write-Host ""

# Check Docker status
Write-Host "1. Checking Docker status..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    Write-Host "âœ?Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "âœ?Docker not installed. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Check Docker daemon
Write-Host "2. Checking Docker daemon..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>$null
    Write-Host "âœ?Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "âœ?Docker daemon is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Open Docker Desktop" -ForegroundColor White
    Write-Host "2. Wait for it to fully start (whale icon should be steady)" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    exit 1
}

# Test network connectivity
Write-Host "3. Testing network connectivity..." -ForegroundColor Yellow
try {
    $testResult = docker run --rm hello-world 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "âœ?Docker network is working" -ForegroundColor Green
    } else {
        Write-Host "âœ?Docker network test failed" -ForegroundColor Red
        Write-Host "This might be a proxy or firewall issue" -ForegroundColor Yellow
    }
} catch {
    Write-Host "âœ?Docker network test failed" -ForegroundColor Red
}

# Try building with timeout
Write-Host "4. Attempting Docker build..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Cyan

try {
    $buildResult = docker build -f Dockerfile.demo -t mediagenie-demo:latest . 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "âœ?Docker build successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run the deployment script:" -ForegroundColor Cyan
        Write-Host ".\deploy_demo_quick.ps1" -ForegroundColor White
    } else {
        Write-Host "âœ?Docker build failed" -ForegroundColor Red
        Write-Host "Build output:" -ForegroundColor Yellow
        Write-Host $buildResult -ForegroundColor Gray
    }
} catch {
    Write-Host "âœ?Docker build failed with exception" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "For more help, see: AZURE_DEMO_DEPLOYMENT.md" -ForegroundColor Gray