# ============================================================================
# MediaGenie Azure Web App 一键部署脚本
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "B1",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateResources = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildFrontend = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$EnvSettingsFile = "env-settings.json"
)

$ErrorActionPreference = "Stop"

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           MediaGenie Azure Web App 部署工具                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n📋 部署配置:" -ForegroundColor Yellow
Write-Host "   资源组: $ResourceGroup" -ForegroundColor White
Write-Host "   应用名称: $WebAppName" -ForegroundColor White
Write-Host "   区域: $Location" -ForegroundColor White
Write-Host "   定价层: $Sku" -ForegroundColor White
Write-Host ""

# ============================================================================
# 步骤1: 检查Azure CLI
# ============================================================================
Write-Host "🔍 步骤 1/6: 检查Azure CLI..." -ForegroundColor Cyan
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✅ Azure CLI版本: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "❌ 未找到Azure CLI,请先安装: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}

# 检查登录状态
Write-Host "🔐 检查Azure登录状态..." -ForegroundColor Cyan
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ 已登录: $($account.user.name)" -ForegroundColor Green
    Write-Host "   订阅: $($account.name)" -ForegroundColor White
} catch {
    Write-Host "⚠️ 未登录Azure,正在打开登录窗口..." -ForegroundColor Yellow
    az login
}

# ============================================================================
# 步骤2: 创建Azure资源 (可选)
# ============================================================================
if ($CreateResources) {
    Write-Host "`n🏗️ 步骤 2/6: 创建Azure资源..." -ForegroundColor Cyan
    
    # 创建资源组
    Write-Host "📦 创建资源组: $ResourceGroup" -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
    
    # 创建App Service Plan
    $planName = "$WebAppName-plan"
    Write-Host "📦 创建App Service Plan: $planName" -ForegroundColor Yellow
    az appservice plan create `
        --name $planName `
        --resource-group $ResourceGroup `
        --location $Location `
        --is-linux `
        --sku $Sku
    
    # 创建Web App
    Write-Host "🌐 创建Web App: $WebAppName" -ForegroundColor Yellow
    az webapp create `
        --name $WebAppName `
        --resource-group $ResourceGroup `
        --plan $planName `
        --runtime "PYTHON:3.11"
    
    Write-Host "✅ Azure资源创建完成" -ForegroundColor Green
} else {
    Write-Host "`n⏭️ 步骤 2/6: 跳过资源创建 (使用现有资源)" -ForegroundColor Yellow
}

# ============================================================================
# 步骤3: 创建部署包
# ============================================================================
Write-Host "`n📦 步骤 3/6: 创建部署包..." -ForegroundColor Cyan

$deployDir = "azure-webapp-deploy"

# 调用部署包创建脚本
if ($BuildFrontend) {
    .\create_azure_deployment_package.ps1 -OutputDir $deployDir -BuildFrontend
} else {
    .\create_azure_deployment_package.ps1 -OutputDir $deployDir
}

if (-not (Test-Path $deployDir)) {
    Write-Host "❌ 部署包创建失败" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 部署包创建成功: $deployDir" -ForegroundColor Green

# ============================================================================
# 步骤4: 创建ZIP压缩包
# ============================================================================
Write-Host "`n📦 步骤 4/6: 创建ZIP压缩包..." -ForegroundColor Cyan

$zipFile = "mediagenie-webapp-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
$zipPath = Join-Path $PWD $zipFile

# 删除旧的ZIP文件
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# 创建ZIP包
Write-Host "压缩目录: $deployDir → $zipFile" -ForegroundColor Yellow
Compress-Archive -Path "$deployDir\*" -DestinationPath $zipPath -Force

if (-not (Test-Path $zipPath)) {
    Write-Host "❌ ZIP包创建失败" -ForegroundColor Red
    exit 1
}

$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "✅ ZIP包创建成功: $zipFile ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green

# ============================================================================
# 步骤5: 部署到Azure Web App
# ============================================================================
Write-Host "`n🚀 步骤 5/6: 部署到Azure Web App..." -ForegroundColor Cyan

Write-Host "上传并部署: $zipFile → $WebAppName" -ForegroundColor Yellow
Write-Host "⏳ 这可能需要几分钟时间,请耐心等待..." -ForegroundColor Yellow

try {
    az webapp deploy `
        --resource-group $ResourceGroup `
        --name $WebAppName `
        --src-path $zipPath `
        --type zip `
        --async false
    
    Write-Host "✅ 代码部署成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 部署失败: $_" -ForegroundColor Red
    Write-Host "请检查:" -ForegroundColor Yellow
    Write-Host "  1. 资源组和Web App名称是否正确" -ForegroundColor White
    Write-Host "  2. 是否有足够的权限" -ForegroundColor White
    Write-Host "  3. 查看日志: az webapp log tail --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor White
    exit 1
}

# ============================================================================
# 步骤6: 配置环境变量
# ============================================================================
Write-Host "`n⚙️ 步骤 6/6: 配置环境变量..." -ForegroundColor Cyan

if (Test-Path $EnvSettingsFile) {
    Write-Host "📝 从文件导入环境变量: $EnvSettingsFile" -ForegroundColor Yellow
    
    try {
        az webapp config appsettings set `
            --resource-group $ResourceGroup `
            --name $WebAppName `
            --settings "@$EnvSettingsFile"
        
        Write-Host "✅ 环境变量配置成功" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ 环境变量配置失败,请手动配置" -ForegroundColor Yellow
        Write-Host "使用命令: az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppName --settings @$EnvSettingsFile" -ForegroundColor White
    }
} else {
    Write-Host "⚠️ 未找到环境变量文件: $EnvSettingsFile" -ForegroundColor Yellow
    Write-Host "请手动配置环境变量:" -ForegroundColor Yellow
    Write-Host "  1. 复制 env-settings-template.json 为 env-settings.json" -ForegroundColor White
    Write-Host "  2. 填入实际的Azure服务密钥" -ForegroundColor White
    Write-Host "  3. 运行: az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppName --settings @env-settings.json" -ForegroundColor White
}

# 配置启动命令
Write-Host "🔧 配置启动命令..." -ForegroundColor Yellow
try {
    az webapp config set `
        --resource-group $ResourceGroup `
        --name $WebAppName `
        --startup-file "bash startup.sh"
    
    Write-Host "✅ 启动命令配置成功" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 启动命令配置失败,请在Azure Portal手动设置: bash startup.sh" -ForegroundColor Yellow
}

# 启用日志记录
Write-Host "📊 启用应用日志..." -ForegroundColor Yellow
try {
    az webapp log config `
        --resource-group $ResourceGroup `
        --name $WebAppName `
        --application-logging filesystem `
        --level information
    
    Write-Host "✅ 日志配置成功" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 日志配置失败" -ForegroundColor Yellow
}

# ============================================================================
# 完成
# ============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 部署完成!                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$appUrl = "https://$WebAppName.azurewebsites.net"
Write-Host "`n📋 部署信息:" -ForegroundColor Yellow
Write-Host "   应用URL: $appUrl" -ForegroundColor Cyan
Write-Host "   健康检查: $appUrl/health" -ForegroundColor Cyan
Write-Host "   部署包: $zipFile" -ForegroundColor White

Write-Host "`n🔍 验证部署:" -ForegroundColor Yellow
Write-Host "   1. 查看实时日志:" -ForegroundColor White
Write-Host "      az webapp log tail --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. 在浏览器访问:" -ForegroundColor White
Write-Host "      $appUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3. 测试健康检查:" -ForegroundColor White
Write-Host "      curl $appUrl/health" -ForegroundColor Cyan

Write-Host "`n⚠️ 重要提醒:" -ForegroundColor Yellow
Write-Host "   1. 确保已配置所有必需的环境变量" -ForegroundColor White
Write-Host "   2. 如果应用未启动,检查日志排查问题" -ForegroundColor White
Write-Host "   3. 首次部署可能需要5-10分钟完全启动" -ForegroundColor White

Write-Host "`n📚 更多帮助:" -ForegroundColor Yellow
Write-Host "   查看部署指南: cd $deployDir && cat DEPLOYMENT_GUIDE.md" -ForegroundColor White
Write-Host ""
