# MediaGenie 精简部署包创建工�?
# 只打包必需文件，排�?node_modules 等大文件

Write-Host "=== MediaGenie 精简打包工具 ===" -ForegroundColor Cyan

# 1. 检查必需文件
Write-Host "检查必需文件..." -ForegroundColor Yellow
$missing = @()
if (-not (Test-Path "backend" -PathType Container)) { $missing += "backend/" }
if (-not (Test-Path "frontend" -PathType Container)) { $missing += "frontend/" }
if (-not (Test-Path "deploy-marketplace-complete.sh")) { $missing += "deploy-marketplace-complete.sh" }

if ($missing.Count -gt 0) {
    Write-Host "缺少文件: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "�?基础文件检查通过" -ForegroundColor Green

# 2. 创建临时目录
$tempDir = "temp_deploy_$(Get-Date -Format 'HHmmss')"
Write-Host "创建临时目录: $tempDir" -ForegroundColor Gray
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

try {
    # 3. 复制后端文件 (排除不必要的文件)
    Write-Host "复制后端文件..." -ForegroundColor White
    $backendDest = Join-Path $tempDir "backend"
    New-Item -Path $backendDest -ItemType Directory -Force | Out-Null
    
    # 复制后端 Python 文件
    Get-ChildItem "backend" -Include "*.py", "*.txt", "*.json", "*.md", "*.sh" -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring((Resolve-Path "backend").Path.Length + 1)
        $destPath = Join-Path $backendDest $relativePath
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item $_.FullName $destPath -Force
    }
    Write-Host "  �?后端文件已复�?(只包�?.py, .txt, .json �?" -ForegroundColor Green

    # 4. 复制前端源码 (排除 node_modules �?build)
    Write-Host "复制前端源码..." -ForegroundColor White
    $frontendDest = Join-Path $tempDir "frontend" 
    New-Item -Path $frontendDest -ItemType Directory -Force | Out-Null
    
    # 定义要包含的前端文件
    $frontendIncludes = @("*.json", "*.js", "*.ts", "*.tsx", "*.html", "*.css", "*.md", "*.yml", "*.yaml")
    $frontendExcludes = @("node_modules", "build", "dist", ".git", "coverage", ".nyc_output")
    
    Get-ChildItem "frontend" -Recurse | Where-Object {
        $exclude = $false
        foreach ($excludePattern in $frontendExcludes) {
            if ($_.FullName -like "*\$excludePattern\*") {
                $exclude = $true
                break
            }
        }
        if (-not $exclude) {
            foreach ($includePattern in $frontendIncludes) {
                if ($_.Name -like $includePattern -or $_.PSIsContainer) {
                    return $true
                }
            }
        }
        return $false
    } | ForEach-Object {
        if (-not $_.PSIsContainer) {
            $relativePath = $_.FullName.Substring((Resolve-Path "frontend").Path.Length + 1)
            $destPath = Join-Path $frontendDest $relativePath
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item $_.FullName $destPath -Force
        }
    }
    Write-Host "  �?前端源码已复�?(排除 node_modules, build �?" -ForegroundColor Green

    # 5. 复制部署脚本
    Write-Host "复制部署脚本..." -ForegroundColor White
    Copy-Item "deploy-marketplace-complete.sh" $tempDir -Force
    Copy-Item "deploy-marketplace-powershell.ps1" $tempDir -Force -ErrorAction SilentlyContinue
    Write-Host "  �?部署脚本已复�? -ForegroundColor Green

    # 6. 创建精简�?
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $zipFile = "mediagenie-slim-$timestamp.zip"
    
    Write-Host "创建精简�? $zipFile" -ForegroundColor Yellow
    Write-Host "正在压缩..." -ForegroundColor Gray
    
    # 使用 Compress-Archive 压缩临时目录内容
    $tempItems = Get-ChildItem $tempDir
    Compress-Archive -Path $tempItems.FullName -DestinationPath $zipFile -CompressionLevel Optimal -Force
    
    # 7. 显示结果
    $fileInfo = Get-Item $zipFile
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    $sizeKB = [math]::Round($fileInfo.Length / 1KB, 0)
    
    Write-Host ""
    Write-Host "�?精简包创建成�?" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Gray
    Write-Host "📦 文件: $zipFile" -ForegroundColor Cyan
    Write-Host "📊 大小: $sizeMB MB ($sizeKB KB)" -ForegroundColor Cyan
    Write-Host "🎯 优化: 排除�?node_modules, build, .git 等大文件" -ForegroundColor Green
    Write-Host ""
    
    # 8. 显示包含内容
    Write-Host "📋 包含内容:" -ForegroundColor Yellow
    Write-Host "  📁 backend/ (Python 文件: *.py, *.txt, *.json)" -ForegroundColor White
    Write-Host "  📁 frontend/ (源码: *.js, *.ts, *.tsx, *.json, *.html, *.css)" -ForegroundColor White
    Write-Host "  📄 deploy-marketplace-complete.sh" -ForegroundColor White
    Write-Host "  📄 deploy-marketplace-powershell.ps1" -ForegroundColor White
    Write-Host ""
    
    # 9. Cloud Shell 操作指南
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Gray
    Write-Host "🚀 Cloud Shell 操作指南" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Gray
    Write-Host ""
    Write-Host "1️⃣  上传精简�?(现在只有 $sizeMB MB，上传更�?" -ForegroundColor White
    Write-Host "     Portal: https://portal.azure.com" -ForegroundColor Gray
    Write-Host "     Cloud Shell > PowerShell 模式 > 上传 $zipFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2️⃣  解压并安装依�?" -ForegroundColor White
    Write-Host "     New-Item ~/mediagenie -ItemType Directory -Force" -ForegroundColor Gray
    Write-Host "     Expand-Archive ~/$zipFile ~/mediagenie -Force" -ForegroundColor Gray
    Write-Host "     Set-Location ~/mediagenie" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3️⃣  设置环境变量:" -ForegroundColor White
    Write-Host "     `$env:AZURE_OPENAI_KEY = 'your-key'" -ForegroundColor Gray
    Write-Host "     `$env:AZURE_OPENAI_ENDPOINT = 'https://...'" -ForegroundColor Gray
    Write-Host "     `$env:AZURE_SPEECH_KEY = 'your-key'" -ForegroundColor Gray
    Write-Host "     `$env:AZURE_SPEECH_REGION = 'eastus'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4️⃣  安装前端依赖并构�?" -ForegroundColor White
    Write-Host "     Set-Location frontend" -ForegroundColor Gray
    Write-Host "     npm install" -ForegroundColor Gray
    Write-Host "     npm run build" -ForegroundColor Gray
    Write-Host "     Set-Location .." -ForegroundColor Gray
    Write-Host ""
    Write-Host "5️⃣  部署:" -ForegroundColor White
    Write-Host "     .\deploy-marketplace-powershell.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 优势: 上传更快，在 Cloud Shell 中安装依赖更稳定" -ForegroundColor Yellow

} finally {
    # 清理临时目录
    Write-Host ""
    Write-Host "清理临时文件..." -ForegroundColor Gray
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "�?精简打包完成！上传会更快�? -ForegroundColor Green