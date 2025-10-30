# MediaGenie Backend Startup Script

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "           MediaGenie Backend Service Startup                       " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "üîç Checking Python..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ‚ú?Python found: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  ‚ú?Python not found! Please install Python 3.11+" -ForegroundColor Red
    exit 1
}

# Check if backend directory exists
if (-not (Test-Path "backend\media-service")) {
    Write-Host "  ‚ú?Backend directory not found!" -ForegroundColor Red
    Write-Host "  Please run this script from the project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "üì¶ Checking dependencies..." -ForegroundColor Yellow

# Check if requirements are installed
$fastapi = pip show fastapi 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ‚ö†Ô∏è  Dependencies not installed. Installing now..." -ForegroundColor Yellow
    Set-Location backend\media-service
    pip install -r requirements.txt
    Set-Location ..\..
    Write-Host "  ‚ú?Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  ‚ú?Dependencies already installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "üöÄ Starting backend service..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Service will be available at:" -ForegroundColor Cyan
Write-Host "    ‚Ä?API: http://localhost:9001" -ForegroundColor White
Write-Host "    ‚Ä?Docs: http://localhost:9001/docs" -ForegroundColor White
Write-Host "    ‚Ä?Health: http://localhost:9001/health" -ForegroundColor White
Write-Host ""
Write-Host "  Press Ctrl+C to stop the service" -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Change to backend directory and start service
Set-Location backend\media-service
python -m uvicorn main:app --reload --port 9001 --host 0.0.0.0

