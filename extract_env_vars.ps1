# 从现有的.env文件提取环境变量配置
# 用于Azure App Service部署

Write-Host "=== �?env文件提取环境变量 ===" -ForegroundColor Green
Write-Host ""

$envFile = "backend/media-service/.env"

if (!(Test-Path $envFile)) {
    Write-Host "错误：找不到.env文件�?envFile" -ForegroundColor Red
    exit 1
}

Write-Host "正在�?$envFile 提取环境变量..." -ForegroundColor Yellow
Write-Host ""

# 读取并处�?env文件
$envVars = Get-Content $envFile | Where-Object {
    # 跳过注释行和空行
    $_ -match '^[^#]' -and $_ -match '=' -and $_.Trim() -ne ''
} | ForEach-Object {
    $line = $_.Trim()
    # 分割键值对
    $key, $value = $line -split '=', 2
    if ($key -and $value) {
        "$key=$value"
    }
}

# 显示提取的变�?
Write-Host "提取到的环境变量�? -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
$envVars | ForEach-Object { Write-Host $_ -ForegroundColor White }
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 保存到文�?
$envVars | Out-File "azure_env_vars.txt" -Encoding UTF8
Write-Host "�?环境变量已保存到：azure_env_vars.txt" -ForegroundColor Green
Write-Host ""

Write-Host "📋 复制步骤�? -ForegroundColor Yellow
Write-Host "1. 打开 Azure Portal �?你的 App Service �?设置 �?环境变量" -ForegroundColor White
Write-Host "2. 逐个添加上述变量名和�? -ForegroundColor White
Write-Host "3. 记得更新 DATABASE_URL 为你�?Azure PostgreSQL 连接字符�? -ForegroundColor White
Write-Host "4. 生成新的 JWT_SECRET_KEY�?2位随机字符串�? -ForegroundColor White
Write-Host ""

Write-Host "⚠️  重要提醒�? -ForegroundColor Red
Write-Host "�?不要直接复制连接字符串中的特殊字�? -ForegroundColor White
Write-Host "�?DATABASE_URL 需要更新为 Azure PostgreSQL" -ForegroundColor White
Write-Host "�?JWT_SECRET_KEY 必须是新的随机密�? -ForegroundColor White
Write-Host "�?CORS_ORIGINS 需要更新为你的域名" -ForegroundColor White