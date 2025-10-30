# 自动配置 Azure Web App 环境变量
# �?.env 文件读取并批量设置到 Azure

param(
    [Parameter(Mandatory=$true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [string]$EnvFile = "backend\media-service\.env"
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  配置 Azure Web App 环境变量" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 检�?.env 文件
if (-not (Test-Path $EnvFile)) {
    Write-Host "[ERROR] .env 文件不存�? $EnvFile" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] 读取环境变量文件: $EnvFile" -ForegroundColor Yellow

# 读取 .env 文件
$envVars = @{}
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    
    # 跳过空行和注�?
    if ($line -eq "" -or $line.StartsWith("#")) {
        return
    }
    
    # 解析 KEY=VALUE
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # 跳过不需要的本地变量
        if ($key -in @("DATABASE_URL", "REDIS_URL", "CORS_ORIGINS", "DEBUG", "LOG_LEVEL", "MAX_FILE_SIZE", "ALLOWED_AUDIO_FORMATS", "ALLOWED_IMAGE_FORMATS")) {
            Write-Host "[SKIP] 跳过本地变量: $key" -ForegroundColor Gray
            return
        }
        
        $envVars[$key] = $value
        Write-Host "[+] $key" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[INFO] 共读�?$($envVars.Count) 个环境变�? -ForegroundColor Yellow
Write-Host ""

# 添加 Azure 特定配置
$envVars["PORT"] = "8000"
$envVars["SCM_DO_BUILD_DURING_DEPLOYMENT"] = "true"
$envVars["ENABLE_ORYX_BUILD"] = "true"

Write-Host "[INFO] 开始配�?Azure Web App: $WebAppName" -ForegroundColor Yellow
Write-Host ""

# 构建 az webapp config 命令
$settingsArgs = @()
foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    # 转义特殊字符
    $value = $value -replace '"', '\"'
    $settingsArgs += "$key=`"$value`""
}

# 执行配置
try {
    Write-Host "[INFO] 正在上传环境变量�?Azure..." -ForegroundColor Yellow
    
    $settingsString = $settingsArgs -join " "
    $command = "az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppName --settings $settingsString --output none"
    
    Invoke-Expression $command
    
    Write-Host ""
    Write-Host "[SUCCESS] 环境变量配置完成!" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一�?" -ForegroundColor Cyan
    Write-Host "  1. �?Azure Portal 验证环境变量" -ForegroundColor White
    Write-Host "  2. 重启 Web App (如果需�?" -ForegroundColor White
    Write-Host "  3. 部署代码�?Web App" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] 配置失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "请检�?" -ForegroundColor Yellow
    Write-Host "  1. Azure CLI 是否已登�?(az login)" -ForegroundColor White
    Write-Host "  2. Web App 名称和资源组是否正确" -ForegroundColor White
    Write-Host "  3. 是否有权限修�?Web App 配置" -ForegroundColor White
    exit 1
}
