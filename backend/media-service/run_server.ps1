# MediaGenie Backend Service Startup Script
# 启动 MediaGenie 后端服务

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "�?    🚀 MediaGenie Backend Service Startup                  �? -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检�?Python 是否已安�?Write-Host "🔍 检�?Python 环境..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "�?Python 已安�? $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "�?Python 未安装或不在 PATH �? -ForegroundColor Red
    exit 1
}

# 检�?FastAPI 是否已安�?Write-Host ""
Write-Host "🔍 检查依�?.." -ForegroundColor Yellow
python -c "import fastapi; import uvicorn; print('�?FastAPI �?uvicorn 已安�?)" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "�?缺少依赖，正在安�?.." -ForegroundColor Red
    pip install fastapi uvicorn
}

# 启动服务
Write-Host ""
Write-Host "🚀 启动 FastAPI 服务..." -ForegroundColor Green
Write-Host ""
Write-Host "📍 服务地址: http://0.0.0.0:9001" -ForegroundColor Cyan
Write-Host "📚 API 文档: http://localhost:9001/docs" -ForegroundColor Cyan
Write-Host "📖 ReDoc 文档: http://localhost:9001/redoc" -ForegroundColor Cyan
Write-Host ""
Write-Host "�?Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host ""

python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload

