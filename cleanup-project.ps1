# 清理 MediaGenie 项目 - 只保留核心代码
Write-Host "开始清理项目..." -ForegroundColor Green

# 1. 删除所有 .zip 文件
Write-Host "`n删除所有 .zip 压缩包..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.zip" -Recurse -File | Remove-Item -Force -Verbose

# 2. 删除所有 .md 文档（除了 README.md）
Write-Host "`n删除所有文档文件（保留 README.md）..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" } | Remove-Item -Force -Verbose

# 3. 删除所有部署脚本
Write-Host "`n删除所有部署脚本..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object { $_.Name -ne "cleanup-project.ps1" } | Remove-Item -Force -Verbose
Get-ChildItem -Path . -Filter "*.sh" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path . -Filter "*.bat" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path . -Filter "*.cmd" -File | Remove-Item -Force -Verbose

# 4. 删除临时文件夹
Write-Host "`n删除临时文件夹..." -ForegroundColor Yellow
$tempFolders = @(
    "arm-templates",
    "azure-marketplace",
    "deploy",
    "deployment-temp",
    "docs",
    "frontend-simple",
    "marketplace-portal",
    "marketplace-portal-simple",
    "mediagenie-complete-temp",
    "mediagenie-english-temp",
    "mediagenie-fixed-temp",
    "mediagenie-real-temp",
    "monitoring",
    "portal-build",
    "security",
    "simple-test-app",
    "temp-deploy",
    "verify-complete",
    "verify-package",
    "verify-real"
)

foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Write-Host "删除文件夹: $folder" -ForegroundColor Cyan
        Remove-Item -Path $folder -Recurse -Force
    }
}

# 5. 删除其他无用文件
Write-Host "`n删除其他无用文件..." -ForegroundColor Yellow

Get-ChildItem -Path . -File | Where-Object {
    $_.Name -match "\.json$" -and
    $_.Name -ne "package.json" -and
    $_.Name -ne "package-lock.json" -and
    $_.Name -ne "tsconfig.json"
} | Remove-Item -Force -Verbose

Get-ChildItem -Path . -Filter "*.txt" -File | Remove-Item -Force -Verbose

# 6. 清理 backend 文件夹
Write-Host "`n清理 backend 文件夹..." -ForegroundColor Yellow
if (Test-Path "backend/media-service/__pycache__") {
    Remove-Item -Path "backend/media-service/__pycache__" -Recurse -Force
}
if (Test-Path "backend/media-service/logs") {
    Remove-Item -Path "backend/media-service/logs" -Recurse -Force
}

Get-ChildItem -Path "backend/media-service" -Filter "test_*.py" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path "backend/media-service" -Filter "*.ps1" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path "backend/media-service" -Filter "*.txt" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path "backend/media-service" -Filter "diagnose_*.py" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path "backend/media-service" -Filter "quick_*.py" -File | Remove-Item -Force -Verbose
Get-ChildItem -Path "backend/media-service" -Filter "reset_*.py" -File | Remove-Item -Force -Verbose

# 7. 清理 frontend 文件夹
Write-Host "`n清理 frontend 文件夹..." -ForegroundColor Yellow
if (Test-Path "frontend/build.zip") {
    Remove-Item -Path "frontend/build.zip" -Force
}
if (Test-Path "frontend/deploy.cmd") {
    Remove-Item -Path "frontend/deploy.cmd" -Force
}
if (Test-Path "frontend/web.config") {
    Remove-Item -Path "frontend/web.config" -Force
}
if (Test-Path "frontend/package-production.json") {
    Remove-Item -Path "frontend/package-production.json" -Force
}

Write-Host "`n清理完成！" -ForegroundColor Green
Write-Host "`n保留的核心文件夹：" -ForegroundColor Cyan
Write-Host "  - backend/media-service/" -ForegroundColor White
Write-Host "  - frontend/" -ForegroundColor White
Write-Host "  - README.md" -ForegroundColor White

