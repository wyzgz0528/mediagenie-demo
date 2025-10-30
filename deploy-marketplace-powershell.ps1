# ============================================================================
# MediaGenie Azure Marketplace Deployment Script (Cloud Shell PowerShell)
# ============================================================================
# 用�? �?Azure Cloud Shell PowerShell 中部�?MediaGenie
# 要求: 已解压部署包，设置好环境变量
# ============================================================================

param(
    [string]$ResourceGroup = "",
    [string]$Location = "East US"
)

Write-Host "╔═══════════════════════════════════════════════════════════════�? -ForegroundColor Cyan
Write-Host "�?           MediaGenie Azure Marketplace 部署工具              �? -ForegroundColor Cyan  
Write-Host "�?                  (Cloud Shell PowerShell)                   �? -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════�? -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 1. 环境检�?
# ============================================================================
Write-Host "━━�?步骤 1: 环境检�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# 检�?Azure CLI
Write-Host "检�?Azure CLI..." -ForegroundColor White
try {
    $azVersion = az version --output tsv --query '"azure-cli"' 2>$null
    Write-Host "�?Azure CLI 版本: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "�?Azure CLI 未安装或无法访问" -ForegroundColor Red
    exit 1
}

# 检查登录状�?
Write-Host "检�?Azure 登录状�?.." -ForegroundColor White
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    Write-Host "�?已登录账�? $($account.user.name)" -ForegroundColor Green
    Write-Host "�?订阅: $($account.name) ($($account.id))" -ForegroundColor Green
} catch {
    Write-Host "�?未登�?Azure，请先运�?'az login'" -ForegroundColor Red
    exit 1
}

# 检查必需的环境变�?
Write-Host "检查环境变�?.." -ForegroundColor White
$requiredEnvs = @(
    "AZURE_OPENAI_KEY",
    "AZURE_OPENAI_ENDPOINT", 
    "AZURE_SPEECH_KEY",
    "AZURE_SPEECH_REGION"
)

$missingEnvs = @()
foreach ($env in $requiredEnvs) {
    $value = [System.Environment]::GetEnvironmentVariable($env)
    if ([string]::IsNullOrEmpty($value)) {
        $missingEnvs += $env
        Write-Host "�?缺少环境变量: $env" -ForegroundColor Red
    } else {
        Write-Host "�?$env = $($value.Substring(0, [Math]::Min(20, $value.Length)))..." -ForegroundColor Green
    }
}

if ($missingEnvs.Count -gt 0) {
    Write-Host ""
    Write-Host "请先设置环境变量:" -ForegroundColor Yellow
    foreach ($env in $missingEnvs) {
        Write-Host "  `$env:$env = 'your-value'" -ForegroundColor Gray
    }
    Write-Host ""
    exit 1
}

# 检查必需文件
Write-Host "检查部署文�?.." -ForegroundColor White
$requiredFiles = @("backend", "frontend", "deploy-marketplace-complete.sh")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "�?找到: $file" -ForegroundColor Green
    } else {
        Write-Host "�?缺少: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "请确保已正确解压部署�? -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# 2. 资源组配�?
# ============================================================================
Write-Host "━━�?步骤 2: 资源组配�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

if ([string]::IsNullOrEmpty($ResourceGroup)) {
    $timestamp = Get-Date -Format "MMddHHmm"
    $ResourceGroup = "mediagenie-rg-$timestamp"
    Write-Host "自动生成资源组名�? $ResourceGroup" -ForegroundColor Cyan
} else {
    Write-Host "使用指定资源�? $ResourceGroup" -ForegroundColor Cyan
}

# 检查资源组是否存在
$rgExists = az group exists --name $ResourceGroup --output tsv
if ($rgExists -eq "true") {
    Write-Host "�?资源组已存在: $ResourceGroup" -ForegroundColor Green
} else {
    Write-Host "创建资源�? $ResourceGroup (位置: $Location)" -ForegroundColor White
    az group create --name $ResourceGroup --location $Location --output table
    if ($LASTEXITCODE -ne 0) {
        Write-Host "�?创建资源组失�? -ForegroundColor Red
        exit 1
    }
    Write-Host "�?资源组创建成�? -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# 3. 构建前端
# ============================================================================
Write-Host "━━�?步骤 3: 构建前端 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

Set-Location frontend
Write-Host "当前目录: $(Get-Location)" -ForegroundColor Gray

# 检�?Node.js
try {
    $nodeVersion = node --version
    Write-Host "�?Node.js 版本: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "�?Node.js 未安�? -ForegroundColor Red
    Set-Location ..
    exit 1
}

# 安装依赖
Write-Host "安装前端依赖..." -ForegroundColor White
npm install --production
if ($LASTEXITCODE -ne 0) {
    Write-Host "�?依赖安装失败" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# 构建
Write-Host "构建前端..." -ForegroundColor White
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "�?前端构建失败" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "�?前端构建完成" -ForegroundColor Green
Set-Location ..

Write-Host ""

# ============================================================================
# 4. 执行 Azure 部署
# ============================================================================
Write-Host "━━�?步骤 4: 执行 Azure 部署 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

# 设置环境变量�?bash 脚本使用
$env:RESOURCE_GROUP = $ResourceGroup

# 运行原始�?bash 部署脚本
Write-Host "运行部署脚本..." -ForegroundColor White
Write-Host "资源�? $ResourceGroup" -ForegroundColor Cyan

# 给脚本执行权�?(如果需�?
if (Get-Command chmod -ErrorAction SilentlyContinue) {
    chmod +x deploy-marketplace-complete.sh
}

# 执行 bash 脚本
bash ./deploy-marketplace-complete.sh
$deployResult = $LASTEXITCODE

if ($deployResult -ne 0) {
    Write-Host ""
    Write-Host "�?部署失败，退出代�? $deployResult" -ForegroundColor Red
    exit $deployResult
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "🎉 部署完成�? -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

# ============================================================================
# 5. 获取部署结果
# ============================================================================
Write-Host ""
Write-Host "━━�?获取部署结果 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

try {
    # 获取 Web App 信息
    $webApps = az webapp list --resource-group $ResourceGroup --output json | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "🔗 部署的服�?" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    foreach ($app in $webApps) {
        $url = "https://$($app.defaultHostName)"
        if ($app.name -like "*-web-*") {
            Write-Host "📱 前端应用: $url" -ForegroundColor Green
        } elseif ($app.name -like "*-api-*") {
            Write-Host "🔧 后端 API: $url" -ForegroundColor Green
            Write-Host "🏪 Landing Page: $url/marketplace/landing" -ForegroundColor Yellow
            Write-Host "🔗 Webhook: $url/marketplace/webhook" -ForegroundColor Yellow
            Write-Host "💓 Health: $url/marketplace/health" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "📋 下一�? Partner Center 配置" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "�?Partner Center 技术配置中填入:" -ForegroundColor White
    $apiApp = $webApps | Where-Object { $_.name -like "*-api-*" } | Select-Object -First 1
    if ($apiApp) {
        $baseUrl = "https://$($apiApp.defaultHostName)"
        Write-Host "  Landing page URL: $baseUrl/marketplace/landing" -ForegroundColor Cyan
        Write-Host "  Connection webhook: $baseUrl/marketplace/webhook" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "⚠️  无法获取部署详情，但部署可能已成�? -ForegroundColor Yellow
    Write-Host "请到 Azure Portal 检查资源组: $ResourceGroup" -ForegroundColor Gray
}

Write-Host ""
Write-Host "�?部署流程完成�? -ForegroundColor Green