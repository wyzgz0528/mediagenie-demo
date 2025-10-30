# MediaGenie 部署前构建脚�?
Write-Host "🚀 MediaGenie 部署前构建开�?.." -ForegroundColor Cyan

# 检查当前目�?$currentDir = Get-Location
Write-Host "📁 当前目录: $currentDir" -ForegroundColor Yellow

# 检查前端目�?if (-not (Test-Path "frontend")) {
    Write-Host "�?前端目录不存�? -ForegroundColor Red
    exit 1
}

# 进入前端目录
Set-Location "frontend"

Write-Host "📦 安装前端依赖..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "�?依赖安装失败" -ForegroundColor Red
    exit 1
}

Write-Host "🔨 构建前端应用..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "�?前端构建失败" -ForegroundColor Red
    exit 1
}

# 检查构建结�?if (Test-Path "build") {
    $buildSize = (Get-ChildItem "build" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "�?前端构建成功!" -ForegroundColor Green
    Write-Host "📊 构建大小: $([math]::Round($buildSize, 2)) MB" -ForegroundColor Green
    
    # 列出构建文件
    Write-Host "📋 构建文件:" -ForegroundColor Yellow
    Get-ChildItem "build" | ForEach-Object {
        Write-Host "  📄 $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "�?构建目录不存�? -ForegroundColor Red
    exit 1
}

# 返回原目�?Set-Location $currentDir

Write-Host "" -ForegroundColor White
Write-Host "🎉 构建完成!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "📋 下一�?" -ForegroundColor Yellow
Write-Host "  1. 在VS Code中打开Azure扩展" -ForegroundColor White
Write-Host "  2. 右键点击 backend/media-service 文件�? -ForegroundColor White
Write-Host "  3. 选择 'Deploy to Web App...'" -ForegroundColor White
Write-Host "  4. 配置后端Web App (mediagenie-backend-prod)" -ForegroundColor White
Write-Host "  5. 右键点击 frontend 文件�? -ForegroundColor White
Write-Host "  6. 选择 'Deploy to Web App...'" -ForegroundColor White
Write-Host "  7. 配置前端Web App (mediagenie-frontend-prod)" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "📖 详细步骤请查�? VSCODE_DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan
