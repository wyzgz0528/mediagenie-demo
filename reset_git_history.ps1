# ============================================================================
# 清理Git历史并重新开始(移除所有敏感信息)
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        清理Git历史并创建全新的干净仓库                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Yellow

Write-Host "`n⚠️ 警告: 这将删除所有Git历史记录并创建新的初始提交" -ForegroundColor Red
Write-Host ""
$response = Read-Host "确认继续? (输入 YES 继续)"
if ($response -ne "YES") {
    Write-Host "❌ 已取消操作" -ForegroundColor Yellow
    exit 0
}

# 1. 删除包含敏感信息的文件
Write-Host "`n🗑️ 步骤 1: 删除包含敏感信息的文件..." -ForegroundColor Cyan

$filesToDelete = @(
    "azure_env_vars.txt",
    "complete-deployment-commands.txt",
    "cloud-shell-commands.txt",
    "cloud-shell-deploy-commands.txt",
    "final-deployment-commands.txt",
    "quick-deploy-options.txt",
    "fixed-deployment.txt",
    "test-mcr-commands.txt",
    "PowerShell部署指南.md",
    "配额限制完全解决指南.md",
    "Cloud Shell PowerShell 部署指南.md",
    "CLOUD_SHELL_DEPLOYMENT_COMMANDS.txt",
    "DIAGNOSTIC_DEPLOYMENT_GUIDE.txt",
    "README_本地测试.txt"
)

$dirsToDelete = @(
    "verify-real",
    "verify-complete",
    "verify-package",
    "mediagenie-complete-temp",
    "mediagenie-real-temp",
    "mediagenie-english-temp",
    "mediagenie-fixed-temp",
    "deployment-temp"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  ✅ 已删除: $file" -ForegroundColor Green
    }
}

foreach ($dir in $dirsToDelete) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
        Write-Host "  ✅ 已删除目录: $dir" -ForegroundColor Green
    }
}

# 2. 备份Git远程仓库配置
Write-Host "`n💾 步骤 2: 保存Git配置..." -ForegroundColor Cyan
$remoteUrl = git remote get-url origin
Write-Host "  📝 远程仓库: $remoteUrl" -ForegroundColor White

# 3. 删除.git目录
Write-Host "`n🔄 步骤 3: 删除Git历史..." -ForegroundColor Cyan
if (Test-Path ".git") {
    Remove-Item ".git" -Recurse -Force
    Write-Host "  ✅ 已删除.git目录" -ForegroundColor Green
}

# 4. 重新初始化Git仓库
Write-Host "`n🆕 步骤 4: 初始化新的Git仓库..." -ForegroundColor Cyan
git init
Write-Host "  ✅ Git仓库已初始化" -ForegroundColor Green

# 5. 添加远程仓库
Write-Host "`n🔗 步骤 5: 配置远程仓库..." -ForegroundColor Cyan
git remote add origin $remoteUrl
Write-Host "  ✅ 已添加远程仓库: $remoteUrl" -ForegroundColor Green

# 6. 创建初始提交
Write-Host "`n📝 步骤 6: 创建初始提交..." -ForegroundColor Cyan
git add .
git commit -m "Initial commit: MediaGenie clean version

- Complete MediaGenie application codebase
- Frontend: React + TypeScript
- Backend: FastAPI Python service
- Marketplace Portal: Flask application
- Azure Web App deployment scripts and guides
- Removed all sensitive information and credentials"

Write-Host "  ✅ 初始提交已创建" -ForegroundColor Green

# 7. 显示状态
Write-Host "`n📊 当前状态:" -ForegroundColor Yellow
git log --oneline -1
Write-Host ""
git status --short

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                    ✅ 清理完成!                                ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "📝 下一步操作:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. 推送到GitHub (强制推送,覆盖远程历史):" -ForegroundColor White
Write-Host "     git push -f origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. 或者先查看要推送的文件:" -ForegroundColor White
Write-Host "     git log --stat" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️ 注意: 使用 -f (force) 会覆盖GitHub上的所有历史记录" -ForegroundColor Yellow
Write-Host "         这是必要的,因为之前的提交包含敏感信息" -ForegroundColor Yellow
Write-Host ""
