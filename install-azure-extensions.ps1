# 🚀 VSCode Azure 扩展安装脚本
# 自动安装所有必需�?Azure 扩展

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VSCode Azure 扩展安装脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检�?VSCode 是否已安�?Write-Host "检�?VSCode 是否已安�?.." -ForegroundColor Yellow
$codeExists = Get-Command code -ErrorAction SilentlyContinue
if (-not $codeExists) {
    Write-Host "�?VSCode 未安装或不在 PATH �? -ForegroundColor Red
    Write-Host "请先安装 VSCode: https://code.visualstudio.com/" -ForegroundColor Yellow
    exit 1
}
Write-Host "�?VSCode 已安�? -ForegroundColor Green
Write-Host ""

# 要安装的扩展列表
$extensions = @(
    "ms-vscode.azure-account",                    # Azure Account
    "ms-azuretools.vscode-azureappservice",       # Azure App Service
    "ms-azuretools.vscode-azureresourcegroups",   # Azure Resource Groups
    "ms-azuretools.vscode-azuredatabases",        # Azure Databases
    "ms-azuretools.vscode-azurestorage",          # Azure Storage
    "ms-azuretools.vscode-docker"                 # Docker (已有)
)

Write-Host "开始安�?Azure 扩展..." -ForegroundColor Yellow
Write-Host ""

$installed = 0
$failed = 0

foreach ($extension in $extensions) {
    Write-Host "安装: $extension" -ForegroundColor Cyan
    
    try {
        code --install-extension $extension
        Write-Host "�?已安�? $extension" -ForegroundColor Green
        $installed++
    }
    catch {
        Write-Host "�?安装失败: $extension" -ForegroundColor Red
        Write-Host "错误: $_" -ForegroundColor Red
        $failed++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "安装完成�? -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "已安�? $installed 个扩�? -ForegroundColor Green
Write-Host "失败: $failed 个扩�? -ForegroundColor Yellow
Write-Host ""

if ($failed -eq 0) {
    Write-Host "�?所有扩展已成功安装�? -ForegroundColor Green
    Write-Host ""
    Write-Host "下一�?" -ForegroundColor Cyan
    Write-Host "1. 重新启动 VSCode" -ForegroundColor White
    Write-Host "2. �?Ctrl + Shift + P 打开命令面板" -ForegroundColor White
    Write-Host "3. 输入 'Azure: Sign In' 并按 Enter" -ForegroundColor White
    Write-Host "4. 在浏览器中使�?wangyizhe@intellnet.cn 登录" -ForegroundColor White
    Write-Host "5. 授权 VSCode 访问你的 Azure 账户" -ForegroundColor White
}
else {
    Write-Host "警告: 部分扩展安装失败，请检查错误信�? -ForegroundColor Yellow
}

Write-Host ""
Write-Host "更多信息，请查看: VSCODE_AZURE_DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan

