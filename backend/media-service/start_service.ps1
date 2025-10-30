# MediaGenie Backend Service Startup Script
# 启动 MediaGenie 后端服务

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "�?    MediaGenie Backend Service Startup                     �? -ForegroundColor Cyan
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

# 检�?uvicorn 是否已安�?Write-Host ""
Write-Host "🔍 检�?uvicorn..." -ForegroundColor Yellow
python -c "import uvicorn; print(f'�?uvicorn 已安�? {uvicorn.__version__}')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "�?uvicorn 未安装，正在安装..." -ForegroundColor Red
    pip install uvicorn
}

# 检�?FastAPI 是否已安�?Write-Host ""
Write-Host "🔍 检�?FastAPI..." -ForegroundColor Yellow
python -c "import fastapi; print(f'�?FastAPI 已安�? {fastapi.__version__}')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "�?FastAPI 未安装，正在安装..." -ForegroundColor Red
    pip install fastapi
}

# 检查数据库连接
Write-Host ""
Write-Host "🔍 检查数据库连接..." -ForegroundColor Yellow
python -c "
import asyncio
from database import check_db_connection
try:
    result = asyncio.run(check_db_connection())
    if result:
        print('�?数据库连接正�?)
    else:
        print('⚠️  数据库连接检查失�?)
except Exception as e:
    print(f'⚠️  数据库连接错�? {e}')
" 2>&1

# 启动服务
Write-Host ""
Write-Host "🚀 启动 FastAPI 服务..." -ForegroundColor Green
Write-Host "📍 服务地址: http://0.0.0.0:9001" -ForegroundColor Cyan
Write-Host "📚 API 文档: http://localhost:9001/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "�?Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host ""

python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload

