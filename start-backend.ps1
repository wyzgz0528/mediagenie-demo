# Start MediaGenie Backend Service
Write-Host "🚀 Starting MediaGenie Backend Service..." -ForegroundColor Green

# Change to backend directory
Set-Location backend/media-service

# Start uvicorn server
Write-Host "Starting uvicorn on port 9001..." -ForegroundColor Cyan
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload

