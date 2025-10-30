# MediaGenie 完整项目启动脚本（前�?+ 后端�?
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "              MediaGenie 完整项目启动（前�?+ 后端�?               " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 检�?Python
Write-Host "[1/4] 检�?Python 环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  OK - Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  错误 - 未找�?Python�? -ForegroundColor Red
    exit 1
}

# 检�?Node.js
Write-Host ""
Write-Host "[2/4] 检�?Node.js 环境..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    $npmVersion = npm --version 2>&1
    Write-Host "  OK - Node.js: $nodeVersion" -ForegroundColor Green
    Write-Host "  OK - npm: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host "  错误 - 未找�?Node.js�? -ForegroundColor Red
    exit 1
}

# 检查前端依�?Write-Host ""
Write-Host "[3/4] 检查前端依�?.." -ForegroundColor Yellow
if (Test-Path "frontend\node_modules") {
    Write-Host "  OK - 前端依赖已安�? -ForegroundColor Green
} else {
    Write-Host "  警告 - 前端依赖未安装，正在安装..." -ForegroundColor Yellow
    Set-Location frontend
    npm install
    Set-Location ..
    Write-Host "  OK - 前端依赖安装完成" -ForegroundColor Green
}

# 启动服务
Write-Host ""
Write-Host "[4/4] 启动服务..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  即将启动:" -ForegroundColor Cyan
Write-Host "    - 后端服务: http://localhost:9001" -ForegroundColor White
Write-Host "    - 前端应用: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "  API 文档: http://localhost:9001/docs" -ForegroundColor Gray
Write-Host "  健康检�? http://localhost:9001/health" -ForegroundColor Gray
Write-Host ""
Write-Host "  �?Ctrl+C 停止所有服�? -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 启动后端（后台）
Write-Host "正在启动后端服务..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location backend\media-service
    python -m uvicorn main:app --reload --port 9001 --host 0.0.0.0
}

# 等待后端启动
Write-Host "等待后端服务启动..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# 检查后端是否启动成�?$backendReady = $false
$maxRetries = 10
$retryCount = 0

while ($retryCount -lt $maxRetries -and -not $backendReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9001/health" -Method GET -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $backendReady = $true
            Write-Host "  OK - 后端服务已启�? -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "  等待�?.. ($retryCount/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $backendReady) {
    Write-Host ""
    Write-Host "  错误 - 后端服务启动失败�? -ForegroundColor Red
    Write-Host "  请检查后端日�? -ForegroundColor Yellow
    Stop-Job -Job $backendJob
    Remove-Job -Job $backendJob
    exit 1
}

Write-Host ""
Write-Host "正在启动前端应用..." -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  后端服务已就绪！" -ForegroundColor Green
Write-Host "  正在启动前端，请稍�?.." -ForegroundColor Green
Write-Host "  前端启动后会自动打开浏览�? http://localhost:3000" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

# 启动前端（前台）
Set-Location frontend
npm start

# 清理（当用户�?Ctrl+C 停止前端时）
Write-Host ""
Write-Host "正在停止后端服务..." -ForegroundColor Yellow
Stop-Job -Job $backendJob
Remove-Job -Job $backendJob
Write-Host "所有服务已停止" -ForegroundColor Green

