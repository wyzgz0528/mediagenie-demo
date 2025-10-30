# 本地开发环境验证脚�?# 用�? 验证所有服务是否正常运�?
Write-Host "🔍 开始验证本地开发环�?.." -ForegroundColor Green
Write-Host ""

# 1. 检�?Docker 容器
Write-Host "1️⃣  检�?PostgreSQL 容器..." -ForegroundColor Cyan
$postgresContainer = docker ps | Select-String "mediagenie-postgres"
if ($postgresContainer) {
    Write-Host "�?PostgreSQL 容器正在运行" -ForegroundColor Green
} else {
    Write-Host "�?PostgreSQL 容器未运�? -ForegroundColor Red
    Write-Host "   启动命令: docker start mediagenie-postgres" -ForegroundColor Yellow
}
Write-Host ""

# 2. 检查后端服�?Write-Host "2️⃣  检查后�?API 服务..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9001/health" -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "�?后端 API 服务正在运行 (端口 9001)" -ForegroundColor Green
    }
} catch {
    Write-Host "�?后端 API 服务未运�? -ForegroundColor Red
    Write-Host "   启动命令: cd backend/media-service; python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload" -ForegroundColor Yellow
}
Write-Host ""

# 3. 检查前端应�?Write-Host "3️⃣  检查前端应�?.." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "�?前端应用正在运行 (端口 3000)" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  前端应用未运行或未响�? -ForegroundColor Yellow
    Write-Host "   启动命令: cd frontend; npm start" -ForegroundColor Yellow
}
Write-Host ""

# 4. 检�?Marketplace Portal
Write-Host "4️⃣  检�?Marketplace Portal..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000" -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "�?Marketplace Portal 正在运行 (端口 5000)" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Marketplace Portal 未运行或未响�? -ForegroundColor Yellow
    Write-Host "   启动命令: cd marketplace-portal; python app.py" -ForegroundColor Yellow
}
Write-Host ""

# 总结
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "�?本地开发环境验证完成！" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "📍 访问地址:" -ForegroundColor Cyan
Write-Host "   后端 API: http://localhost:9001/docs" -ForegroundColor White
Write-Host "   前端应用: http://localhost:3000" -ForegroundColor White
Write-Host "   Marketplace: http://localhost:5000" -ForegroundColor White
Write-Host ""

