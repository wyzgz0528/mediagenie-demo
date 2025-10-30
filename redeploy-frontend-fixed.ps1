# MediaGenie 前端修复重新部署脚本
# 解决 Azure Web App 部署问题

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

Write-Host "🚀 MediaGenie 前端修复部署开�?.." -ForegroundColor Cyan
Write-Host "📋 资源�? $ResourceGroupName" -ForegroundColor Yellow
Write-Host "🌐 Web App: $WebAppName" -ForegroundColor Yellow

# 设置订阅
if ($SubscriptionId) {
    Write-Host "🔧 设置订阅: $SubscriptionId" -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
}

# 检查当前目�?$currentDir = Get-Location
Write-Host "📁 当前目录: $currentDir" -ForegroundColor Yellow

# 检查必要文�?$requiredFiles = @(
    "frontend/build/index.html",
    "frontend/server.js",
    "frontend/package-production.json",
    "frontend/web.config",
    "frontend/.deployment",
    "frontend/deploy.cmd"
)

Write-Host "🔍 检查必要文�?.." -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  �?$file" -ForegroundColor Green
    } else {
        Write-Host "  �?$file" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "�?缺少必要文件，请先运行修复脚�? -ForegroundColor Red
    exit 1
}

# 进入前端目录
Set-Location "frontend"

# 创建部署�?Write-Host "📦 创建部署�?.." -ForegroundColor Yellow

# 删除旧的部署�?if (Test-Path "frontend-production.zip") {
    Remove-Item "frontend-production.zip" -Force
}

# 创建新的部署包（排除不需要的文件�?$excludePatterns = @(
    "node_modules/*",
    "src/*", 
    "public/*",
    "*.log",
    "package.json",  # 使用 package-production.json
    "tsconfig.json",
    "*.md"
)

Write-Host "📋 包含的文�?" -ForegroundColor Yellow
Write-Host "  �?build/ (React构建文件)" -ForegroundColor Green
Write-Host "  �?server.js (Express服务�?" -ForegroundColor Green
Write-Host "  �?package-production.json (生产依赖)" -ForegroundColor Green
Write-Host "  �?web.config (IIS配置)" -ForegroundColor Green
Write-Host "  �?.deployment (Kudu配置)" -ForegroundColor Green
Write-Host "  �?deploy.cmd (部署脚本)" -ForegroundColor Green

# 使用 PowerShell 创建 ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipPath = Join-Path (Get-Location) "frontend-production.zip"
$sourceDir = Get-Location

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')

# 添加文件�?ZIP
$filesToInclude = @(
    "server.js",
    "package-production.json", 
    "web.config",
    ".deployment",
    "deploy.cmd"
)

foreach ($file in $filesToInclude) {
    if (Test-Path $file) {
        $entry = $zip.CreateEntry($file)
        $entryStream = $entry.Open()
        $fileStream = [System.IO.File]::OpenRead((Join-Path $sourceDir $file))
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
    }
}

# 添加 build 目录
if (Test-Path "build") {
    Get-ChildItem "build" -Recurse | ForEach-Object {
        if (-not $_.PSIsContainer) {
            $relativePath = $_.FullName.Substring($sourceDir.Path.Length + 1)
            $entry = $zip.CreateEntry($relativePath)
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::OpenRead($_.FullName)
            $fileStream.CopyTo($entryStream)
            $fileStream.Close()
            $entryStream.Close()
        }
    }
}

$zip.Dispose()

$zipSize = (Get-Item $zipPath).Length / 1KB
Write-Host "�?部署包创建完�? frontend-production.zip ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green

# 配置 Web App 设置
Write-Host "🔧 配置 Web App 设置..." -ForegroundColor Yellow

az webapp config appsettings set `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --settings `
        WEBSITE_NODE_DEFAULT_VERSION="18-lts" `
        SCM_DO_BUILD_DURING_DEPLOYMENT="false" `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "�?配置应用设置失败" -ForegroundColor Red
    exit 1
}

# 设置启动命令
Write-Host "🎯 设置启动命令..." -ForegroundColor Yellow
az webapp config set `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --startup-file "node server.js" `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "�?设置启动命令失败" -ForegroundColor Red
    exit 1
}

# 部署应用
Write-Host "🚀 部署�?Azure Web App..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --src $zipPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "�?部署失败" -ForegroundColor Red
    exit 1
}

# 等待部署完成
Write-Host "�?等待应用启动 (30�?..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 验证部署
$webAppUrl = "https://$WebAppName.azurewebsites.net"
$healthUrl = "$webAppUrl/health"

Write-Host "🔍 验证部署..." -ForegroundColor Yellow
Write-Host "🌐 应用 URL: $webAppUrl" -ForegroundColor Cyan
Write-Host "❤️ 健康检�? $healthUrl" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 30
    if ($response.status -eq "ok") {
        Write-Host "�?健康检查通过!" -ForegroundColor Green
        Write-Host "📊 服务状�? $($response.service)" -ForegroundColor Green
        Write-Host "🕐 时间�? $($response.timestamp)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 健康检查返回异常状�? -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ 健康检查失败，但应用可能仍在启动中" -ForegroundColor Yellow
    Write-Host "🔗 请手动访�? $webAppUrl" -ForegroundColor Cyan
}

# 返回原目�?Set-Location $currentDir

Write-Host "" -ForegroundColor White
Write-Host "🎉 部署完成!" -ForegroundColor Green
Write-Host "🔗 前端 URL: $webAppUrl" -ForegroundColor Cyan
Write-Host "❤️ 健康检�? $healthUrl" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "📋 下一�?" -ForegroundColor Yellow
Write-Host "  1. 访问前端 URL 验证页面加载" -ForegroundColor White
Write-Host "  2. 检查浏览器控制台是否有错误" -ForegroundColor White
Write-Host "  3. 测试后端 API 连接" -ForegroundColor White
Write-Host "  4. 如有问题，查�?Azure Portal 日志�? -ForegroundColor White
