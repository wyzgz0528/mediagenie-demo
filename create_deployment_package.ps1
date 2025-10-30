# MediaGenie Azure 部署包创建脚�?# 创建一个完整的、可直接上传�?Azure Cloud Shell 的部署包

param(
    [string]$OutputName = "MediaGenie-Azure-Deploy",
    [switch]$IncludeFrontend = $false
)

Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "�?     MediaGenie - Azure Deployment Package Creator                �? -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 创建临时目录
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempDir = ".\temp_deploy_$timestamp"
$outputZip = "$OutputName.zip"

Write-Host "📦 创建部署�? $outputZip" -ForegroundColor Green
Write-Host ""

# 创建临时目录
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# ============================================================================
# 1. 复制后端代码
# ============================================================================
Write-Host "📁 复制后端代码..." -ForegroundColor Yellow

$backendDir = Join-Path $tempDir "backend"
New-Item -ItemType Directory -Path $backendDir -Force | Out-Null

# 复制 media-service
if (Test-Path "backend\media-service") {
    Copy-Item -Path "backend\media-service" -Destination $backendDir -Recurse -Force
    Write-Host "  �?已复�?backend/media-service" -ForegroundColor Gray
    
    # 清理后端日志
    $logsPath = Join-Path $backendDir "media-service\logs"
    if (Test-Path $logsPath) {
        Remove-Item "$logsPath\*.log" -Force -ErrorAction SilentlyContinue
        Write-Host "  �?已清理后端日�? -ForegroundColor Gray
    }
}

# ============================================================================
# 2. 复制前端代码（如果需要）
# ============================================================================
if ($IncludeFrontend) {
    Write-Host "📁 复制前端代码..." -ForegroundColor Yellow
    
    $frontendDir = Join-Path $tempDir "frontend"
    New-Item -ItemType Directory -Path $frontendDir -Force | Out-Null
    
    # 只复制构建后的文件和必要配置
    if (Test-Path "frontend\build") {
        Copy-Item -Path "frontend\build" -Destination $frontendDir -Recurse -Force
        Write-Host "  �?已复�?frontend/build" -ForegroundColor Gray
    }
    
    if (Test-Path "frontend\package.json") {
        Copy-Item -Path "frontend\package.json" -Destination $frontendDir -Force
        Write-Host "  �?已复�?frontend/package.json" -ForegroundColor Gray
    }
    
    if (Test-Path "frontend\nginx.conf") {
        Copy-Item -Path "frontend\nginx.conf" -Destination $frontendDir -Force
        Write-Host "  �?已复�?frontend/nginx.conf" -ForegroundColor Gray
    }
}

# ============================================================================
# 3. 复制部署脚本和配�?# ============================================================================
Write-Host "📁 复制部署脚本和配�?.." -ForegroundColor Yellow

# 部署脚本
if (Test-Path "deploy-cloudshell.sh") {
    Copy-Item -Path "deploy-cloudshell.sh" -Destination $tempDir -Force
    Write-Host "  �?已复�?deploy-cloudshell.sh" -ForegroundColor Gray
}

# ARM 模板
if (Test-Path "azuredeploy.json") {
    Copy-Item -Path "azuredeploy.json" -Destination $tempDir -Force
    Write-Host "  �?已复�?azuredeploy.json" -ForegroundColor Gray
}

if (Test-Path "azuredeploy.parameters.json") {
    Copy-Item -Path "azuredeploy.parameters.json" -Destination $tempDir -Force
    Write-Host "  �?已复�?azuredeploy.parameters.json" -ForegroundColor Gray
}

# Docker 配置
if (Test-Path "docker-compose.yml") {
    Copy-Item -Path "docker-compose.yml" -Destination $tempDir -Force
    Write-Host "  �?已复�?docker-compose.yml" -ForegroundColor Gray
}

if (Test-Path "Dockerfile") {
    Copy-Item -Path "Dockerfile" -Destination $tempDir -Force
    Write-Host "  �?已复�?Dockerfile" -ForegroundColor Gray
}

# Azure 部署配置
if (Test-Path "azure-deploy") {
    Copy-Item -Path "azure-deploy" -Destination $tempDir -Recurse -Force
    Write-Host "  �?已复�?azure-deploy/" -ForegroundColor Gray
}

if (Test-Path "azure-marketplace") {
    Copy-Item -Path "azure-marketplace" -Destination $tempDir -Recurse -Force
    Write-Host "  �?已复�?azure-marketplace/" -ForegroundColor Gray
}

# ============================================================================
# 4. 复制文档
# ============================================================================
Write-Host "📁 复制文档..." -ForegroundColor Yellow

$docs = @(
    "README.md",
    "README_MARKETPLACE.md",
    "MARKETPLACE_DEPLOYMENT_GUIDE.md",
    "AZURE_DEPLOYMENT_INSTRUCTIONS.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Copy-Item -Path $doc -Destination $tempDir -Force
        Write-Host "  �?已复�?$doc" -ForegroundColor Gray
    }
}

# ============================================================================
# 5. 创建部署说明文件
# ============================================================================
Write-Host "📝 创建部署说明..." -ForegroundColor Yellow

$deployReadme = @"
# MediaGenie Azure 部署�?
## 快速开�?
### 方法 1: Azure Cloud Shell 部署（推荐）

1. 上传�?zip 文件�?Azure Cloud Shell
2. 解压: ``unzip $outputZip``
3. 进入目录: ``cd ${OutputName}``
4. 编辑配置: ``code deploy-cloudshell.sh``
   - 替换 AZURE_OPENAI_KEY
   - 替换 AZURE_OPENAI_ENDPOINT
   - 替换 AZURE_SPEECH_KEY
   - 替换 AZURE_SPEECH_REGION
5. 执行部署: ``chmod +x deploy-cloudshell.sh && ./deploy-cloudshell.sh``

### 方法 2: 本地 Azure CLI 部署

1. 确保已安�?Azure CLI
2. 登录: ``az login``
3. 解压此文�?4. 编辑 ``deploy-cloudshell.sh`` 配置
5. 运行: ``bash deploy-cloudshell.sh``

## 部署时间

- 预计部署时间: 5-10 分钟
- 首次启动可能需要额�?2-3 分钟

## 部署后验�?
访问以下 URL 验证部署:
- 健康检�? ``https://your-app-name.azurewebsites.net/health``
- API 文档: ``https://your-app-name.azurewebsites.net/docs``

## 需要的 Azure 服务

在部署前，请确保已创�?
1. �?Azure OpenAI Service (GPT-4)
2. �?Azure Speech Services
3. ⚠️ Azure Computer Vision (可�?

## 成本估算

- App Service (B1): ~`$13 USD/�?- Storage: ~`$1 USD/�?- Azure 认知服务: 按使用量计费

## 获取帮助

详细文档请查�?
- AZURE_DEPLOYMENT_INSTRUCTIONS.md
- MARKETPLACE_DEPLOYMENT_GUIDE.md

技术支�? support@smartwebco.com

---
生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$deployReadme | Out-File -FilePath (Join-Path $tempDir "DEPLOY_README.txt") -Encoding UTF8
Write-Host "  �?已创�?DEPLOY_README.txt" -ForegroundColor Gray

# ============================================================================
# 6. 创建环境变量模板
# ============================================================================
Write-Host "📝 创建环境变量模板..." -ForegroundColor Yellow

$envTemplate = @"
# MediaGenie Azure 环境变量配置模板
# 请将此文件重命名�?.env 并填写实际�?
# ============================================================================
# Azure OpenAI 配置
# ============================================================================
AZURE_OPENAI_KEY=your-openai-api-key-here
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ============================================================================
# Azure Speech Services 配置
# ============================================================================
AZURE_SPEECH_KEY=your-speech-api-key-here
AZURE_SPEECH_REGION=eastus

# ============================================================================
# Azure Computer Vision 配置（可选）
# ============================================================================
AZURE_VISION_KEY=your-vision-api-key-here
AZURE_VISION_ENDPOINT=https://your-vision.cognitiveservices.azure.com/

# ============================================================================
# Azure Storage 配置（可选）
# ============================================================================
AZURE_STORAGE_CONNECTION_STRING=your-storage-connection-string-here

# ============================================================================
# 应用配置
# ============================================================================
PORT=8000
ENVIRONMENT=production
LOG_LEVEL=INFO
"@

$envTemplate | Out-File -FilePath (Join-Path $tempDir ".env.template") -Encoding UTF8
Write-Host "  �?已创�?.env.template" -ForegroundColor Gray

# ============================================================================
# 7. 创建 ZIP �?# ============================================================================
Write-Host ""
Write-Host "📦 创建 ZIP 压缩�?.." -ForegroundColor Yellow

# 删除旧的 zip 文件
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# 创建 zip
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

# 获取文件大小
$zipSize = (Get-Item $outputZip).Length / 1MB
$zipSizeFormatted = "{0:N2}" -f $zipSize

Write-Host "  �?已创�? $outputZip ($zipSizeFormatted MB)" -ForegroundColor Green

# ============================================================================
# 8. 清理临时文件
# ============================================================================
Write-Host ""
Write-Host "🧹 清理临时文件..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force
Write-Host "  �?已清理临时目�? -ForegroundColor Gray

# ============================================================================
# 完成
# ============================================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "�?                   �?部署包创建完�?                              �? -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📦 部署包信�?" -ForegroundColor Cyan
Write-Host "  文件�? $outputZip" -ForegroundColor White
Write-Host "  大小: $zipSizeFormatted MB" -ForegroundColor White
Write-Host "  位置: $(Get-Location)\$outputZip" -ForegroundColor White
Write-Host ""
Write-Host "📋 下一步操�?" -ForegroundColor Cyan
Write-Host "  1. 打开 Azure Cloud Shell: https://shell.azure.com" -ForegroundColor White
Write-Host "  2. 上传 $outputZip" -ForegroundColor White
Write-Host "  3. 解压: unzip $outputZip" -ForegroundColor White
Write-Host "  4. 进入目录: cd $OutputName" -ForegroundColor White
Write-Host "  5. 编辑配置: code deploy-cloudshell.sh" -ForegroundColor White
Write-Host "  6. 执行部署: chmod +x deploy-cloudshell.sh && ./deploy-cloudshell.sh" -ForegroundColor White
Write-Host ""
Write-Host "📚 详细文档请查看包内的 AZURE_DEPLOYMENT_INSTRUCTIONS.md" -ForegroundColor Yellow
Write-Host ""

