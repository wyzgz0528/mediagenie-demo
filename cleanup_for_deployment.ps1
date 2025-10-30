# MediaGenie 项目清理脚本 - 准备Azure部署
# 删除不必要的文件，保留核心代码和配置

Write-Host "开始清�?MediaGenie 项目..." -ForegroundColor Green

# 1. 删除所有旧的部署包
Write-Host "`n清理旧的部署�?.." -ForegroundColor Yellow
$zipFiles = @(
    "MediaGenie_Deploy_Complete.zip",
    "MediaGenie_Fresh_Deploy.zip",
    "MediaGenie_Marketplace_Deploy.zip",
    "MediaGenie_Deploy_EastUS2.zip",
    "MediaGenie_Azure_Final.zip",
    "MediaGenie_Fixed.zip",
    "MediaGenie_Final.zip",
    "MediaGenie_Deploy_Final.zip",
    "MediaGenie_CloudShell_Deploy.zip",
    "MediaGenie_Fix.zip",
    "MediaGenie_Complete_Redeploy.zip",
    "MediaGenie_Marketplace_Fix.zip",
    "Frontend_Fix_v2.zip",
    "Frontend_New.zip",
    "Frontend_Upload.zip",
    "Upload_Frontend_Manual.zip",
    "Upload_Frontend_Simple.zip",
    "frontend\build.zip"
)

foreach ($file in $zipFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  已删�? $file" -ForegroundColor Gray
    }
}

# 2. 删除重复的部署目�?Write-Host "`n清理重复的部署目�?.." -ForegroundColor Yellow
$deployDirs = @(
    "MediaGenie_Deploy_Slim",
    "MediaGenie_Marketplace_Deploy"
)

foreach ($dir in $deployDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
        Write-Host "  已删除目�? $dir" -ForegroundColor Gray
    }
}

# 3. 删除多余的文档文件（保留主要的README和部署指南）
Write-Host "`n清理多余的文�?.." -ForegroundColor Yellow
$docsToRemove = @(
    "AZURE_CONFIGURATION_GUIDE.md",
    "AZURE_DEPLOYMENT_GUIDE.md",
    "AZURE_OPENAI_CONFIG_COMPLETE.md",
    "AZURE_OPENAI_CONFIG_SUCCESS.md",
    "CLOUDSHELL_COMMANDS.txt",
    "DEPLOYMENT_CHECKLIST.md",
    "DEPLOYMENT_COMPLETE_SOLUTION.md",
    "DEPLOYMENT_COMPLETE_SUMMARY.md",
    "DEPLOYMENT_GUIDE.md",
    "DEPLOYMENT_GUIDE_FINAL.md",
    "DEPLOYMENT_INFO_V2.md",
    "DEPLOYMENT_INSTRUCTIONS.md",
    "DEPLOYMENT_READY.md",
    "DEPLOYMENT_VERIFICATION.md",
    "DEPLOY_GUIDE.md",
    "EASTUS2_DEPLOYMENT_INFO.md",
    "EMERGENCY_FIX_GUIDE.md",
    "FINAL_DEPLOYMENT_GUIDE.md",
    "KUDU_FIX_GUIDE.md",
    "MANUAL_TEST_GUIDE.md",
    "MARKETPLACE_FIX_GUIDE.md",
    "PRODUCTION_READINESS_CHECKLIST.md",
    "PRODUCTION_TEST_REPORT.md",
    "QUICK_FIX_NOW.md",
    "QUICK_REDEPLOY_GUIDE.md",
    "QUICK_REFERENCE.md",
    "QUOTA_CHECK_GUIDE.md",
    "QUOTA_SOLUTIONS.md",
    "README_DEPLOYMENT.md",
    "STT_TEST_SUMMARY.md",
    "TTS_TEST_REPORT.md"
)

foreach ($doc in $docsToRemove) {
    if (Test-Path $doc) {
        Remove-Item $doc -Force
        Write-Host "  已删�? $doc" -ForegroundColor Gray
    }
}

# 4. 删除多余的脚本（保留核心部署脚本�?Write-Host "`n清理多余的脚�?.." -ForegroundColor Yellow
$scriptsToRemove = @(
    "check_mediagenie.ps1",
    "check_quota.sh",
    "check_quota_quick.sh",
    "cleanup_project.py",
    "complete_redeploy.sh",
    "create_deploy_package.ps1",
    "create_marketplace_package.ps1",
    "deploy_azure_final.sh",
    "deploy_cloudshell_fixed.sh",
    "deploy_container_instances.sh",
    "deploy_fresh_start.sh",
    "deploy_multi_region.sh",
    "deploy_single_region.sh",
    "deploy_smart.sh",
    "fix_deployment.sh",
    "fix_frontend.sh",
    "fix_frontend_permissions.sh",
    "fix_frontend_upload.sh",
    "fix_marketplace.sh",
    "fix_marketplace_portal.ps1",
    "fix_marketplace_portal.sh",
    "fix_permissions.sh",
    "fix_production_issues.py",
    "fix_ssh_console.sh",
    "quick_deploy_fixed.ps1",
    "quick_deploy_fixed.sh",
    "quick_redeploy.sh",
    "rebuild_frontend.ps1",
    "upload_frontend_manual.sh",
    "upload_frontend_simple.sh",
    "verify_azure_config.py",
    "verify_azure_keys.py",
    "test_openai_config.py"
)

foreach ($script in $scriptsToRemove) {
    if (Test-Path $script) {
        Remove-Item $script -Force
        Write-Host "  已删�? $script" -ForegroundColor Gray
    }
}

# 5. 清理日志文件
Write-Host "`n清理日志文件..." -ForegroundColor Yellow
if (Test-Path "logs") {
    Get-ChildItem -Path "logs" -Filter *.log | Remove-Item -Force
    Write-Host "  已清�?logs 目录" -ForegroundColor Gray
}
if (Test-Path "backend\media-service\logs") {
    Get-ChildItem -Path "backend\media-service\logs" -Filter *.log | Remove-Item -Force
    Write-Host "  已清�?backend\media-service\logs 目录" -ForegroundColor Gray
}

# 6. 删除测试文件
Write-Host "`n清理测试文件..." -ForegroundColor Yellow
$testFiles = @(
    "test_image.png",
    "production_test_report.json"
)

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  已删�? $file" -ForegroundColor Gray
    }
}

# 7. 清理 node_modules（可选，如果需要重新安装）
# Write-Host "`n清理 node_modules..." -ForegroundColor Yellow
# if (Test-Path "node_modules") {
#     Remove-Item "node_modules" -Recurse -Force
#     Write-Host "  已删除根目录 node_modules" -ForegroundColor Gray
# }
# if (Test-Path "frontend\node_modules") {
#     Remove-Item "frontend\node_modules" -Recurse -Force
#     Write-Host "  已删�?frontend\node_modules" -ForegroundColor Gray
# }

Write-Host "`n清理完成�? -ForegroundColor Green
Write-Host "`n保留的核心文�?" -ForegroundColor Cyan
Write-Host "  - README.md (主文�?" -ForegroundColor White
Write-Host "  - MARKETPLACE_DEPLOYMENT_GUIDE.md (部署指南)" -ForegroundColor White
Write-Host "  - README_MARKETPLACE.md (Marketplace说明)" -ForegroundColor White
Write-Host "  - deploy-cloudshell.sh (Cloud Shell部署脚本)" -ForegroundColor White
Write-Host "  - azuredeploy.json (ARM模板)" -ForegroundColor White
Write-Host "  - docker-compose.yml (Docker配置)" -ForegroundColor White
Write-Host "  - frontend/ (前端代码)" -ForegroundColor White
Write-Host "  - backend/ (后端代码)" -ForegroundColor White
Write-Host "  - azure-deploy/ (Azure部署配置)" -ForegroundColor White
Write-Host "  - azure-marketplace/ (Marketplace配置)" -ForegroundColor White

Write-Host "`nProject is ready for deployment!" -ForegroundColor Green

