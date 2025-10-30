# MediaGenie Backend 快速重新部署脚�?
Write-Host "🚀 MediaGenie Backend 快速重新部署开�?.." -ForegroundColor Cyan

# 检查Azure CLI
try {
    az --version | Out-Null
    Write-Host "�?Azure CLI 已安�? -ForegroundColor Green
} catch {
    Write-Host "�?请先安装 Azure CLI" -ForegroundColor Red
    Write-Host "下载地址: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# 设置变量
$resourceGroup = "mediagenie"
$webAppName = "mediagenie-backend"
$subscriptionId = "296c69fb-e5f2-4063-b505-16b606eced30"

Write-Host "📋 部署配置:" -ForegroundColor Yellow
Write-Host "  资源�? $resourceGroup" -ForegroundColor White
Write-Host "  应用�? $webAppName" -ForegroundColor White
Write-Host "  订阅ID: $subscriptionId" -ForegroundColor White

# 登录Azure (如果需�?
Write-Host "🔐 检查Azure登录状�?.." -ForegroundColor Yellow
$loginStatus = az account show 2>$null
if (-not $loginStatus) {
    Write-Host "请登录Azure..." -ForegroundColor Yellow
    az login
}

# 设置订阅
Write-Host "🎯 设置订阅..." -ForegroundColor Yellow
az account set --subscription $subscriptionId

# 检查Web App是否存在
Write-Host "🔍 检查Web App是否存在..." -ForegroundColor Yellow
$webAppExists = az webapp show --name $webAppName --resource-group $resourceGroup 2>$null
if (-not $webAppExists) {
    Write-Host "�?Web App '$webAppName' 不存在，请先通过VS Code创建" -ForegroundColor Red
    exit 1
}

Write-Host "�?Web App 存在，继续部�?.." -ForegroundColor Green

# 进入后端目录
$backendPath = "backend\media-service"
if (-not (Test-Path $backendPath)) {
    Write-Host "�?后端目录不存�? $backendPath" -ForegroundColor Red
    exit 1
}

Set-Location $backendPath

# 创建部署�?Write-Host "📦 创建部署�?.." -ForegroundColor Yellow
$zipFile = "mediagenie-backend-deploy.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

# 压缩文件 (排除不必要的文件)
$excludePatterns = @(
    "__pycache__",
    "*.pyc",
    ".env.local",
    ".git",
    "*.log",
    "requirements-*.txt"
)

Write-Host "🗜�?压缩应用文件..." -ForegroundColor Yellow
Compress-Archive -Path "*.py", "*.txt", "*.json", "*.md" -DestinationPath $zipFile -Force

$zipSize = (Get-Item $zipFile).Length / 1MB
Write-Host "�?部署包创建完�? $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green

# 配置Web App设置
Write-Host "⚙️ 配置Web App设置..." -ForegroundColor Yellow
az webapp config appsettings set --name $webAppName --resource-group $resourceGroup --settings `
    "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS=3" `
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false"

# 设置启动命令
Write-Host "🚀 设置启动命令..." -ForegroundColor Yellow
$startupCommand = Get-Content "startup.txt" -Raw
az webapp config set --name $webAppName --resource-group $resourceGroup --startup-file $startupCommand.Trim()

# 部署应用
Write-Host "🚀 开始部�?.." -ForegroundColor Yellow
az webapp deployment source config-zip --name $webAppName --resource-group $resourceGroup --src $zipFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "�?部署成功!" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
    Write-Host "🔗 应用URL:" -ForegroundColor Yellow
    Write-Host "  主页: https://$webAppName.azurewebsites.net" -ForegroundColor White
    Write-Host "  健康检�? https://$webAppName.azurewebsites.net/health" -ForegroundColor White
    Write-Host "  API文档: https://$webAppName.azurewebsites.net/docs" -ForegroundColor White
    
    # 等待应用启动
    Write-Host "�?等待应用启动 (30�?..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # 健康检�?    Write-Host "🔍 执行健康检�?.." -ForegroundColor Yellow
    try {
        $healthUrl = "https://$webAppName.azurewebsites.net/health"
        $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 30
        Write-Host "�?健康检查通过!" -ForegroundColor Green
        Write-Host "📊 响应: $($response | ConvertTo-Json -Compress)" -ForegroundColor White
    } catch {
        Write-Host "⚠️ 健康检查失败，请查看Azure Portal日志" -ForegroundColor Yellow
        Write-Host "🔗 日志地址: https://portal.azure.com" -ForegroundColor White
    }
} else {
    Write-Host "�?部署失败!" -ForegroundColor Red
    Write-Host "请查看Azure Portal中的部署日志" -ForegroundColor Yellow
}

# 清理
Remove-Item $zipFile -Force -ErrorAction SilentlyContinue

# 返回原目�?Set-Location ..\..

Write-Host "🎉 脚本执行完成!" -ForegroundColor Cyan
