# MediaGenie 后端启动脚本（简化版�?
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                  MediaGenie 后端服务启动                           " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 检�?Python
Write-Host "[1/3] 检�?Python 环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  OK - Python 已安�? $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  错误 - 未找�?Python！请先安�?Python 3.11+" -ForegroundColor Red
    exit 1
}

# 检查目�?Write-Host ""
Write-Host "[2/3] 检查项目目�?.." -ForegroundColor Yellow
if (Test-Path "backend\media-service\main.py") {
    Write-Host "  OK - 找到后端代码" -ForegroundColor Green
} else {
    Write-Host "  错误 - 未找�?backend\media-service\main.py" -ForegroundColor Red
    Write-Host "  请确保在项目根目录运行此脚本" -ForegroundColor Yellow
    exit 1
}

# 启动服务
Write-Host ""
Write-Host "[3/3] 启动 FastAPI 服务..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  服务地址:" -ForegroundColor Cyan
Write-Host "    - API 端点: http://localhost:9001" -ForegroundColor White
Write-Host "    - API 文档: http://localhost:9001/docs" -ForegroundColor White
Write-Host "    - 健康检�? http://localhost:9001/health" -ForegroundColor White
Write-Host ""
Write-Host "  �?Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 进入后端目录并启�?Set-Location backend\media-service
python -m uvicorn main:app --reload --port 9001 --host 0.0.0.0

