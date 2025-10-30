# MediaGenie Azure Marketplace 部署包创建脚�?# 此脚本创建符�?Azure Marketplace 要求的完整部署包

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "        MediaGenie Azure Marketplace 部署包创�?                    " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 配置
$packageName = "MediaGenie-Marketplace-Deploy"
$tempDir = "temp_marketplace_package"
$outputZip = "$packageName.zip"

# 清理旧文�?Write-Host "[1/6] 清理旧文�?.." -ForegroundColor Yellow
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
if (Test-Path $outputZip) {
    Remove-Item -Force $outputZip
}

# 创建临时目录
Write-Host "[2/6] 创建临时目录..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# 复制后端代码
Write-Host "[3/6] 复制后端代码..." -ForegroundColor Yellow
$backendDir = Join-Path $tempDir "backend"
New-Item -ItemType Directory -Path $backendDir -Force | Out-Null

if (Test-Path "backend\media-service") {
    Copy-Item -Path "backend\media-service" -Destination $backendDir -Recurse -Force -Exclude @("__pycache__", "*.pyc", "*.log", "venv", "node_modules", ".env")
    Write-Host "  - 复制 backend/media-service" -ForegroundColor Gray
    
    # 清理缓存
    Get-ChildItem -Path "$backendDir\media-service" -Include "__pycache__","*.pyc","*.log" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "  - 清理缓存和日�? -ForegroundColor Gray
} else {
    Write-Host "  - 错误: backend\media-service 不存�?" -ForegroundColor Red
    exit 1
}

# 复制前端构建
Write-Host "[4/6] 复制前端构建..." -ForegroundColor Yellow
$frontendDir = Join-Path $tempDir "frontend"
New-Item -ItemType Directory -Path $frontendDir -Force | Out-Null

if (Test-Path "frontend\build") {
    Copy-Item -Path "frontend\build" -Destination $frontendDir -Recurse -Force
    Write-Host "  - 复制 frontend/build" -ForegroundColor Gray
    
    # 验证构建内容
    $buildFiles = Get-ChildItem -Path "$frontendDir\build" -Recurse -File
    $buildSize = ($buildFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  - 前端构建大小: $([math]::Round($buildSize, 2)) MB" -ForegroundColor Gray
    
    if ($buildSize -lt 0.5) {
        Write-Host "  - 警告: 前端构建文件太小，可能不完整!" -ForegroundColor Yellow
    }
} else {
    Write-Host "  - 错误: frontend\build 不存�? 请先运行 npm run build" -ForegroundColor Red
    exit 1
}

# 复制部署文件
Write-Host "[5/6] 复制部署文件..." -ForegroundColor Yellow

# ARM 模板
if (Test-Path "azuredeploy.json") {
    Copy-Item -Path "azuredeploy.json" -Destination $tempDir -Force
    Write-Host "  - 复制 azuredeploy.json" -ForegroundColor Gray
}

# UI 定义（如果存在）
if (Test-Path "createUiDefinition.json") {
    Copy-Item -Path "createUiDefinition.json" -Destination $tempDir -Force
    Write-Host "  - 复制 createUiDefinition.json" -ForegroundColor Gray
}

# 部署脚本
if (Test-Path "deploy-cloudshell.sh") {
    Copy-Item -Path "deploy-cloudshell.sh" -Destination $tempDir -Force
    Write-Host "  - 复制 deploy-cloudshell.sh" -ForegroundColor Gray
}

# Docker 文件
if (Test-Path "Dockerfile") {
    Copy-Item -Path "Dockerfile" -Destination $tempDir -Force
    Write-Host "  - 复制 Dockerfile" -ForegroundColor Gray
}

if (Test-Path "docker-compose.yml") {
    Copy-Item -Path "docker-compose.yml" -Destination $tempDir -Force
    Write-Host "  - 复制 docker-compose.yml" -ForegroundColor Gray
}

# .deployment file (Kudu deployment config)
$deploymentFile = Join-Path $tempDir ".deployment"
"[config]" | Out-File -FilePath $deploymentFile -Encoding ASCII
"SCM_DO_BUILD_DURING_DEPLOYMENT=true" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
"PROJECT=backend/media-service" | Out-File -FilePath $deploymentFile -Append -Encoding ASCII
Write-Host "  - Created .deployment" -ForegroundColor Gray

# README
if (Test-Path "README.md") {
    Copy-Item -Path "README.md" -Destination $tempDir -Force
    Write-Host "  - 复制 README.md" -ForegroundColor Gray
}

# Create deployment instructions
$instructionsFile = Join-Path $tempDir "DEPLOY_INSTRUCTIONS.md"
$instructions = "# MediaGenie Azure Marketplace Deploy Package`n`n"
$instructions += "## Contents`n`n"
$instructions += "- backend/media-service/ - Complete FastAPI backend`n"
$instructions += "- frontend/build/ - Optimized production build`n"
$instructions += "- azuredeploy.json - ARM template`n"
$instructions += "- deploy-cloudshell.sh - Cloud Shell deployment script`n"
$instructions | Out-File -FilePath $instructionsFile -Encoding UTF8
Write-Host "  - Created DEPLOY_INSTRUCTIONS.md" -ForegroundColor Gray

# 创建压缩�?Write-Host "[6/6] 创建压缩�?.." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

# 获取文件信息
$zipFile = Get-Item $outputZip
$zipSizeMB = [math]::Round($zipFile.Length / 1MB, 2)

# 清理临时目录
Remove-Item -Recurse -Force $tempDir

# 完成
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "                    部署包创建成�?                                  " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "文件信息:" -ForegroundColor Cyan
Write-Host "  文件�? $outputZip" -ForegroundColor White
Write-Host "  大小: $zipSizeMB MB" -ForegroundColor White
Write-Host "  位置: $($zipFile.FullName)" -ForegroundColor White
Write-Host ""

# 验证内容
Write-Host "包含内容:" -ForegroundColor Cyan
Expand-Archive -Path $outputZip -DestinationPath "temp_verify" -Force
Get-ChildItem -Path "temp_verify" -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Replace((Get-Item "temp_verify").FullName, "").TrimStart("\")
    if ($relativePath) {
        Write-Host "  - $relativePath/" -ForegroundColor Gray
    }
}
$fileCount = (Get-ChildItem -Path "temp_verify" -Recurse -File).Count
Write-Host "  总文件数: $fileCount" -ForegroundColor White
Remove-Item -Recurse -Force "temp_verify"

Write-Host ""
Write-Host "下一�?" -ForegroundColor Yellow
Write-Host "  1. 上传 $outputZip �?Azure Cloud Shell" -ForegroundColor White
Write-Host "  2. 解压并运行部署脚�? -ForegroundColor White
Write-Host "  3. 或使�?ARM 模板�?Azure Portal 中部�? -ForegroundColor White
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

