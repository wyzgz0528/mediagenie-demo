# GitHub部署设置脚本

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "mediagenie-demo"
)

Write-Host "=== 设置GitHub部署 ===" -ForegroundColor Green
Write-Host "GitHub用户�? $GitHubUsername" -ForegroundColor Yellow
Write-Host "仓库名称: $RepoName" -ForegroundColor Yellow
Write-Host ""

# 设置远程仓库URL
$repoUrl = "https://github.com/$GitHubUsername/$RepoName.git"
Write-Host "设置远程仓库URL: $repoUrl" -ForegroundColor Cyan

git remote set-url origin $repoUrl

# 验证设置
Write-Host ""
Write-Host "验证远程仓库设置:" -ForegroundColor Green
git remote -v

Write-Host ""
Write-Host "=== 下一步操�?===" -ForegroundColor Green
Write-Host "1. 确保GitHub仓库已创�? https://github.com/$GitHubUsername/$RepoName" -ForegroundColor White
Write-Host "2. 推送代码到GitHub:" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. 在Azure Portal中配置GitHub部署" -ForegroundColor White
Write-Host "   - 部署中心 �?GitHub �?选择仓库和分�? -ForegroundColor White
Write-Host ""
Write-Host "完成! 🎉" -ForegroundColor Green