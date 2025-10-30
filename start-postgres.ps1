# 启动 PostgreSQL Docker 容器用于测试

Write-Host "🐘 启动 PostgreSQL 容器..." -ForegroundColor Cyan

# 检查容器是否已存在
$containerExists = docker ps -a --filter "name=mediagenie-postgres" --format "{{.Names}}"

if ($containerExists -eq "mediagenie-postgres") {
    Write-Host "容器已存在，正在启动..." -ForegroundColor Yellow
    docker start mediagenie-postgres
} else {
    Write-Host "创建新容�?.." -ForegroundColor Green
    docker run -d `
        --name mediagenie-postgres `
        -e POSTGRES_USER=postgres `
        -e POSTGRES_PASSWORD=password `
        -e POSTGRES_DB=mediagenie `
        -p 5432:5432 `
        postgres:15-alpine
}

# 等待 PostgreSQL 启动
Write-Host "等待 PostgreSQL 启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 检查容器状�?$status = docker ps --filter "name=mediagenie-postgres" --format "{{.Status}}"

if ($status) {
    Write-Host "�?PostgreSQL 容器已启�? $status" -ForegroundColor Green
    Write-Host ""
    Write-Host "数据库连接信�?" -ForegroundColor Cyan
    Write-Host "  Host: localhost" -ForegroundColor White
    Write-Host "  Port: 5432" -ForegroundColor White
    Write-Host "  Database: mediagenie" -ForegroundColor White
    Write-Host "  User: postgres" -ForegroundColor White
    Write-Host "  Password: password" -ForegroundColor White
    Write-Host ""
    Write-Host "连接字符�?" -ForegroundColor Cyan
    Write-Host "  postgresql+asyncpg://postgres:password@localhost:5432/mediagenie" -ForegroundColor White
    Write-Host ""
    Write-Host "下一�?" -ForegroundColor Cyan
    Write-Host "  python backend/media-service/quick_test.py" -ForegroundColor White
} else {
    Write-Host "�?PostgreSQL 容器启动失败" -ForegroundColor Red
    Write-Host "请检�?Docker 是否正在运行" -ForegroundColor Yellow
}

