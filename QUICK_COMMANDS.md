# 快速命令参考

## 🚀 Azure 部署命令（复制粘贴即可）

### 1. 创建 ACR 并获取凭据

```powershell
# 创建 ACR
az acr create --resource-group mediagenie-rg --name mediageniecr --sku Basic --location eastus2

# 启用管理员
az acr update --name mediageniecr --admin-enabled true

# 获取凭据（记录输出）
az acr credential show --name mediageniecr
```

---

### 2. 配置 Web App 使用容器

**⚠️ 注意**: 将 `<ACR_USERNAME>` 和 `<ACR_PASSWORD>` 替换为第1步获取的实际值

```powershell
# 后端
az webapp config container set --name mediagenie-backend --resource-group mediagenie-rg --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-backend:latest --docker-registry-server-url https://mediageniecr.azurecr.io --docker-registry-server-user <ACR_USERNAME> --docker-registry-server-password <ACR_PASSWORD>

# 前端
az webapp config container set --name mediagenie-frontend --resource-group mediagenie-rg --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-frontend:latest --docker-registry-server-url https://mediageniecr.azurecr.io --docker-registry-server-user <ACR_USERNAME> --docker-registry-server-password <ACR_PASSWORD>

# 配置端口
az webapp config appsettings set --name mediagenie-backend --resource-group mediagenie-rg --settings WEBSITES_PORT=8000
az webapp config appsettings set --name mediagenie-frontend --resource-group mediagenie-rg --settings WEBSITES_PORT=8080
```

---

### 3. 获取发布配置文件

```powershell
# 后端
az webapp deployment list-publishing-profiles --name mediagenie-backend --resource-group mediagenie-rg --xml > backend-publish-profile.xml

# 前端
az webapp deployment list-publishing-profiles --name mediagenie-frontend --resource-group mediagenie-rg --xml > frontend-publish-profile.xml
```

---

### 4. 查看日志

```powershell
# 后端日志
az webapp log tail --name mediagenie-backend --resource-group mediagenie-rg

# 前端日志
az webapp log tail --name mediagenie-frontend --resource-group mediagenie-rg
```

---

## 🐳 本地 Docker 测试

```powershell
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重新构建并启动
docker-compose up -d --build
```

---

## 📝 Git 命令

```powershell
# 查看状态
git status

# 添加所有更改
git add -A

# 提交
git commit -m "Your commit message"

# 推送到 GitHub
git push origin master

# 创建并切换到 main 分支
git checkout -b main
git push origin main
```

---

## 🔍 验证命令

```powershell
# 测试后端健康检查
curl https://mediagenie-backend.azurewebsites.net/health

# 测试前端
curl https://mediagenie-frontend.azurewebsites.net

# 检查 ACR 镜像
az acr repository list --name mediageniecr --output table
```

---

## 📊 GitHub Secrets 清单

需要在 GitHub 仓库中配置的 5 个 Secrets:

| Secret 名称 | 获取方式 |
|------------|---------|
| `ACR_LOGIN_SERVER` | 固定值: `mediageniecr.azurecr.io` |
| `ACR_USERNAME` | 运行: `az acr credential show --name mediageniecr` |
| `ACR_PASSWORD` | 运行: `az acr credential show --name mediageniecr` |
| `AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE` | 运行: `az webapp deployment list-publishing-profiles --name mediagenie-backend --resource-group mediagenie-rg --xml` |
| `AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE` | 运行: `az webapp deployment list-publishing-profiles --name mediagenie-frontend --resource-group mediagenie-rg --xml` |

---

## 🌐 访问 URL

- **GitHub 仓库**: https://github.com/wyzgz0528/mediagenie-demo
- **后端 API**: https://mediagenie-backend.azurewebsites.net
- **后端文档**: https://mediagenie-backend.azurewebsites.net/docs
- **前端应用**: https://mediagenie-frontend.azurewebsites.net
- **Azure Portal**: https://portal.azure.com

---

## ⚡ 一键部署脚本

将以下内容保存为 `quick-deploy.ps1`:

```powershell
# 快速部署脚本
Write-Host "=== MediaGenie 快速部署 ===" -ForegroundColor Green

# 1. 创建 ACR
Write-Host "`n[1/5] 创建 Azure Container Registry..." -ForegroundColor Yellow
az acr create --resource-group mediagenie-rg --name mediageniecr --sku Basic --location eastus2
az acr update --name mediageniecr --admin-enabled true

# 2. 获取凭据
Write-Host "`n[2/5] 获取 ACR 凭据..." -ForegroundColor Yellow
$acrCreds = az acr credential show --name mediageniecr | ConvertFrom-Json
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "ACR 用户名: $acrUsername" -ForegroundColor Cyan
Write-Host "ACR 密码: $acrPassword" -ForegroundColor Cyan

# 3. 配置 Web App
Write-Host "`n[3/5] 配置 Web App..." -ForegroundColor Yellow
az webapp config container set --name mediagenie-backend --resource-group mediagenie-rg --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-backend:latest --docker-registry-server-url https://mediageniecr.azurecr.io --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword

az webapp config container set --name mediagenie-frontend --resource-group mediagenie-rg --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-frontend:latest --docker-registry-server-url https://mediageniecr.azurecr.io --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword

# 4. 配置端口
Write-Host "`n[4/5] 配置端口..." -ForegroundColor Yellow
az webapp config appsettings set --name mediagenie-backend --resource-group mediagenie-rg --settings WEBSITES_PORT=8000
az webapp config appsettings set --name mediagenie-frontend --resource-group mediagenie-rg --settings WEBSITES_PORT=8080

# 5. 获取发布配置文件
Write-Host "`n[5/5] 获取发布配置文件..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles --name mediagenie-backend --resource-group mediagenie-rg --xml > backend-publish-profile.xml
az webapp deployment list-publishing-profiles --name mediagenie-frontend --resource-group mediagenie-rg --xml > frontend-publish-profile.xml

Write-Host "`n=== 部署准备完成！ ===" -ForegroundColor Green
Write-Host "`n下一步:" -ForegroundColor Yellow
Write-Host "1. 打开 GitHub 仓库: https://github.com/wyzgz0528/mediagenie-demo" -ForegroundColor Cyan
Write-Host "2. 进入 Settings > Secrets and variables > Actions" -ForegroundColor Cyan
Write-Host "3. 添加以下 Secrets:" -ForegroundColor Cyan
Write-Host "   - ACR_LOGIN_SERVER: mediageniecr.azurecr.io" -ForegroundColor White
Write-Host "   - ACR_USERNAME: $acrUsername" -ForegroundColor White
Write-Host "   - ACR_PASSWORD: $acrPassword" -ForegroundColor White
Write-Host "   - AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE: (backend-publish-profile.xml 的内容)" -ForegroundColor White
Write-Host "   - AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE: (frontend-publish-profile.xml 的内容)" -ForegroundColor White
Write-Host "`n4. 手动触发 GitHub Actions 工作流" -ForegroundColor Cyan
```

运行脚本:
```powershell
.\quick-deploy.ps1
```

---

**提示**: 将此文件保存为书签，方便随时查阅！ 📌

