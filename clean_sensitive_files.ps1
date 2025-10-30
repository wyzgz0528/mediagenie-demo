# ============================================================================
# 清理Git历史中的敏感信息
# ============================================================================

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 开始清理敏感信息..." -ForegroundColor Yellow
Write-Host ""

# 需要删除的文件列表(包含真实密钥)
$filesToRemove = @(
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
    "GITHUB_DEPLOYMENT.md",
    "create-complete-package.ps1",
    "create-fixed-package.ps1",
    "verify-real/",
    "verify-complete/",
    "verify-package/",
    "mediagenie-*-temp/",
    "deployment-temp/",
    "*.zip"
)

Write-Host "📋 将删除以下文件/目录:" -ForegroundColor Cyan
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Write-Host "  ❌ $file" -ForegroundColor Red
    }
}

Write-Host ""
if (-not $Force) {
    $response = Read-Host "是否继续? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "❌ 已取消操作" -ForegroundColor Yellow
        exit 0
    }
}

# 删除包含密钥的文件
Write-Host "`n🗑️ 删除包含密钥的文件..." -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Recurse -Force
        Write-Host "  ✅ 已删除: $file" -ForegroundColor Green
    }
}

# 从Git历史中移除(如果已经commit)
Write-Host "`n🔄 从Git中移除这些文件..." -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    try {
        git rm -r --cached $file 2>$null
        Write-Host "  ✅ Git已移除: $file" -ForegroundColor Green
    } catch {
        # 文件可能不在Git中,忽略错误
    }
}

Write-Host "`n✅ 清理完成!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 下一步:" -ForegroundColor Yellow
Write-Host "  1. 检查: git status" -ForegroundColor White
Write-Host "  2. 提交: git add -A && git commit -m 'Remove sensitive files'" -ForegroundColor White
Write-Host "  3. 推送: git push origin main" -ForegroundColor White
