# MediaGenie - GitHub 鑷姩閮ㄧ讲鑴氭湰
# 姝よ剼鏈皢閰嶇疆 Azure Web App 浠?GitHub 鑷姩閮ㄧ讲

param(
    [string]$ResourceGroup = "mediagenie-demo-rg",
    [string]$WebAppName = "mediagenie-demo",
    [string]$GitHubRepo = "https://github.com/wyzgz0528/mediagenie-demo",
    [string]$Branch = "main"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MediaGenie GitHub 鑷姩閮ㄧ讲閰嶇疆" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 妫€鏌?Azure CLI 鐧诲綍鐘舵€?
Write-Host "[姝ラ 1/6] 妫€鏌?Azure 鐧诲綍鐘舵€?.." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "鉂?鏈櫥褰?Azure,璇峰厛杩愯: az login" -ForegroundColor Red
    exit 1
}
Write-Host "鉁?宸茬櫥褰曡闃? $($account.name)" -ForegroundColor Green
Write-Host ""

# 2. 妫€鏌?Web App 鏄惁瀛樺湪
Write-Host "[姝ラ 2/6] 妫€鏌?Web App: $WebAppName..." -ForegroundColor Yellow
$webapp = az webapp show --name $WebAppName --resource-group $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $webapp) {
    Write-Host "鉂?Web App 涓嶅瓨鍦? -ForegroundColor Red
    exit 1
}
Write-Host "鉁?Web App 瀛樺湪,鐘舵€? $($webapp.state)" -ForegroundColor Green
Write-Host ""

# 3. 閰嶇疆杩愯鏃跺拰鍚姩鍛戒护
Write-Host "[姝ラ 3/6] 閰嶇疆 Python 杩愯鏃?.." -ForegroundColor Yellow
az webapp config set `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --linux-fx-version "PYTHON|3.11" `
    --startup-file "startup.sh" `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "鉁?杩愯鏃堕厤缃畬鎴? Python 3.11" -ForegroundColor Green
} else {
    Write-Host "鈿狅笍  杩愯鏃堕厤缃彲鑳藉け璐?浣嗙户缁?.." -ForegroundColor Yellow
}
Write-Host ""

# 4. 鍚敤鏋勫缓鑷姩鍖?
Write-Host "[姝ラ 4/6] 鍚敤 SCM 鏋勫缓鑷姩鍖?.." -ForegroundColor Yellow
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --settings `
        "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
        "ENABLE_ORYX_BUILD=true" `
        "POST_BUILD_COMMAND='cd frontend && npm install && npm run build'" `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "鉁?鏋勫缓鑷姩鍖栧凡鍚敤" -ForegroundColor Green
} else {
    Write-Host "鈿狅笍  鏋勫缓閰嶇疆鍙兘澶辫触,浣嗙户缁?.." -ForegroundColor Yellow
}
Write-Host ""

# 5. 浣跨敤 ZIP 閮ㄧ讲浠?GitHub
Write-Host "[姝ラ 5/6] 閰嶇疆浠?GitHub 閮ㄧ讲..." -ForegroundColor Yellow
Write-Host "姝ｅ湪浠?GitHub 鎷夊彇浠ｇ爜骞堕儴缃?杩欏彲鑳介渶瑕佸嚑鍒嗛挓..." -ForegroundColor Cyan

# 鍒涘缓涓存椂鐩綍
$tempDir = Join-Path $env:TEMP "mediagenie-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # 鍏嬮殕浠撳簱
    Write-Host "  - 鍏嬮殕 GitHub 浠撳簱..." -ForegroundColor Gray
    Set-Location $tempDir
    git clone --depth 1 --branch $Branch $GitHubRepo repo 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "鉂?鍏嬮殕浠撳簱澶辫触" -ForegroundColor Red
        exit 1
    }
    
    Set-Location "repo"
    
    # 鍒涘缓閮ㄧ讲鍖?
    Write-Host "  - 鍒涘缓閮ㄧ讲鍖?.." -ForegroundColor Gray
    $deployDir = Join-Path $tempDir "deploy"
    New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
    
    # 澶嶅埗蹇呰鏂囦欢
    Copy-Item "backend" -Destination $deployDir -Recurse -Force
    Copy-Item "frontend" -Destination $deployDir -Recurse -Force
    Copy-Item "marketplace-portal" -Destination $deployDir -Recurse -Force
    Copy-Item "startup.sh" -Destination $deployDir -Force -ErrorAction SilentlyContinue
    Copy-Item "supervisord-demo.conf" -Destination $deployDir -Force -ErrorAction SilentlyContinue
    Copy-Item "package.json" -Destination $deployDir -Force -ErrorAction SilentlyContinue
    
    # 鍒涘缓 ZIP 鍖?
    $zipFile = Join-Path $tempDir "deploy.zip"
    Write-Host "  - 鍘嬬缉閮ㄧ讲鍖?.." -ForegroundColor Gray
    Compress-Archive -Path "$deployDir\*" -DestinationPath $zipFile -Force
    
    # 閮ㄧ讲鍒?Azure
    Write-Host "  - 涓婁紶鍒?Azure Web App..." -ForegroundColor Gray
    az webapp deployment source config-zip `
        --resource-group $ResourceGroup `
        --name $WebAppName `
        --src $zipFile `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "鉁?閮ㄧ讲鎴愬姛!" -ForegroundColor Green
    } else {
        Write-Host "鉂?閮ㄧ讲澶辫触" -ForegroundColor Red
        exit 1
    }
    
} finally {
    # 娓呯悊涓存椂鏂囦欢
    Set-Location $PSScriptRoot
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""

# 6. 鏄剧ず閮ㄧ讲淇℃伅
Write-Host "[姝ラ 6/6] 閮ㄧ讲瀹屾垚!" -ForegroundColor Yellow
$webappUrl = "https://$($webapp.defaultHostName)"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  鉁?閮ㄧ讲鎴愬姛!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "馃寪 搴旂敤鍦板潃: $webappUrl" -ForegroundColor Cyan
Write-Host "馃搳 鏌ョ湅鏃ュ織: az webapp log tail --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor Cyan
Write-Host "馃攧 閲嶅惎搴旂敤: az webapp restart --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor Cyan
Write-Host ""
Write-Host "鈿狅笍  閲嶈鎻愮ず:" -ForegroundColor Yellow
Write-Host "1. 闇€瑕佸湪 Azure Portal 閰嶇疆鐜鍙橀噺(搴旂敤璁剧疆):" -ForegroundColor White
Write-Host "   - AZURE_SPEECH_KEY" -ForegroundColor Gray
Write-Host "   - AZURE_SPEECH_REGION" -ForegroundColor Gray
Write-Host "   - AZURE_VISION_KEY" -ForegroundColor Gray
Write-Host "   - AZURE_VISION_ENDPOINT" -ForegroundColor Gray
Write-Host "   - AZURE_OPENAI_API_KEY" -ForegroundColor Gray
Write-Host "   - AZURE_OPENAI_ENDPOINT" -ForegroundColor Gray
Write-Host "   - AZURE_OPENAI_DEPLOYMENT_NAME" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 鍙互浣跨敤浠ヤ笅鍛戒护閰嶇疆:" -ForegroundColor White
Write-Host "   az webapp config appsettings set --name $WebAppName --resource-group $ResourceGroup --settings @env-settings-template.json" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 搴旂敤姝ｅ湪鍚姩,鍙兘闇€瑕?-3鍒嗛挓鎵嶈兘璁块棶" -ForegroundColor White
Write-Host ""

# 璇㈤棶鏄惁鎵撳紑娴忚鍣?
$openBrowser = Read-Host "鏄惁鍦ㄦ祻瑙堝櫒涓墦寮€搴旂敤? (Y/N)"
if ($openBrowser -eq "Y" -or $openBrowser -eq "y") {
    Start-Process $webappUrl
}

