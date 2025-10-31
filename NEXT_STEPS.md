# 🎉 项目已成功推送到 GitHub！

代码已经推送到: https://github.com/wyzgz0528/mediagenie-demo

## ✅ 已完成的工作

1. ✅ **项目精简**: 删除了 200+ 个无用文件（文档、脚本、压缩包）
2. ✅ **Docker 配置**: 创建了优化的 Dockerfile 和 docker-compose.yml
3. ✅ **GitHub Actions**: 配置了自动化 CI/CD 工作流
4. ✅ **代码推送**: 成功推送到 GitHub 仓库

## 📋 接下来需要做的事情

### 第 1 步: 创建 Azure Container Registry (ACR)

打开 PowerShell 或 Azure Cloud Shell，执行以下命令:

```powershell
# 登录 Azure
az login

# 创建 ACR
az acr create `
  --resource-group mediagenie-rg `
  --name mediageniecr `
  --sku Basic `
  --location eastus2

# 启用管理员账户
az acr update --name mediageniecr --admin-enabled true

# 获取 ACR 凭据
az acr credential show --name mediageniecr
```

**记录以下信息**:
- ACR 登录服务器: `mediageniecr.azurecr.io`
- 用户名: (从命令输出获取)
- 密码: (从命令输出获取)

---

### 第 2 步: 配置 Azure Web App 使用容器

```powershell
# 配置后端 Web App
az webapp config container set `
  --name mediagenie-backend `
  --resource-group mediagenie-rg `
  --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-backend:latest `
  --docker-registry-server-url https://mediageniecr.azurecr.io `
  --docker-registry-server-user <替换为ACR用户名> `
  --docker-registry-server-password <替换为ACR密码>

# 配置前端 Web App
az webapp config container set `
  --name mediagenie-frontend `
  --resource-group mediagenie-rg `
  --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-frontend:latest `
  --docker-registry-server-url https://mediageniecr.azurecr.io `
  --docker-registry-server-user <替换为ACR用户名> `
  --docker-registry-server-password <替换为ACR密码>

# 配置端口
az webapp config appsettings set `
  --name mediagenie-backend `
  --resource-group mediagenie-rg `
  --settings WEBSITES_PORT=8000

az webapp config appsettings set `
  --name mediagenie-frontend `
  --resource-group mediagenie-rg `
  --settings WEBSITES_PORT=8080
```

---

### 第 3 步: 获取 Web App 发布配置文件

```powershell
# 获取后端发布配置文件
az webapp deployment list-publishing-profiles `
  --name mediagenie-backend `
  --resource-group mediagenie-rg `
  --xml > backend-publish-profile.xml

# 获取前端发布配置文件
az webapp deployment list-publishing-profiles `
  --name mediagenie-frontend `
  --resource-group mediagenie-rg `
  --xml > frontend-publish-profile.xml
```

这会在当前目录生成两个 XML 文件。

---

### 第 4 步: 配置 GitHub Secrets

1. **打开 GitHub 仓库**: https://github.com/wyzgz0528/mediagenie-demo
2. **进入 Settings** > **Secrets and variables** > **Actions**
3. **点击 "New repository secret"** 添加以下 5 个 secrets:

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `ACR_LOGIN_SERVER` | `mediageniecr.azurecr.io` | ACR 登录服务器地址 |
| `ACR_USERNAME` | (从第1步获取) | ACR 用户名 |
| `ACR_PASSWORD` | (从第1步获取) | ACR 密码 |
| `AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE` | (backend-publish-profile.xml 的完整内容) | 后端发布配置 |
| `AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE` | (frontend-publish-profile.xml 的完整内容) | 前端发布配置 |

**注意**: 
- 复制 XML 文件的**完整内容**（包括 `<?xml` 开头）
- 不要遗漏任何字符

---

### 第 5 步: 手动触发 GitHub Actions 部署

由于我们推送到的是 `master` 分支，但 GitHub Actions 配置的是 `main` 分支，我们需要:

**选项 A: 创建 main 分支并推送**
```powershell
git checkout -b main
git push origin main
```

**选项 B: 修改 GitHub Actions 配置**
1. 打开 `.github/workflows/azure-deploy.yml`
2. 将 `branches: - main` 改为 `branches: - master`
3. 提交并推送:
   ```powershell
   git add .github/workflows/azure-deploy.yml
   git commit -m "Fix: Update workflow to trigger on master branch"
   git push origin master
   ```

**选项 C: 手动触发工作流**
1. 打开 GitHub 仓库
2. 进入 **Actions** 标签
3. 选择 "Deploy to Azure Web App" 工作流
4. 点击 **Run workflow** 按钮
5. 选择 `master` 分支
6. 点击 **Run workflow**

---

### 第 6 步: 监控部署

1. 在 GitHub 仓库的 **Actions** 标签中查看工作流运行状态
2. 等待部署完成（通常需要 5-10 分钟）
3. 查看日志以确保没有错误

---

### 第 7 步: 验证部署

部署完成后，访问以下 URL:

- **后端健康检查**: https://mediagenie-backend.azurewebsites.net/health
- **后端 API 文档**: https://mediagenie-backend.azurewebsites.net/docs
- **前端应用**: https://mediagenie-frontend.azurewebsites.net

---

## 🔧 故障排查

### 如果 GitHub Actions 失败

1. **检查 Secrets**: 确保所有 5 个 secrets 都正确配置
2. **查看日志**: 在 Actions 标签中查看详细错误信息
3. **验证 ACR**: 确保 ACR 已创建并启用管理员账户

### 如果容器无法启动

1. **查看 Web App 日志**:
   ```powershell
   az webapp log tail --name mediagenie-backend --resource-group mediagenie-rg
   ```
2. **检查环境变量**: 确保 `WEBSITES_PORT` 设置正确
3. **验证镜像**: 确保 Docker 镜像已成功推送到 ACR

---

## 📚 相关文档

- **完整部署指南**: 查看 `DEPLOYMENT_GUIDE.md`
- **Docker Compose**: 查看 `docker-compose.yml` 进行本地测试
- **GitHub Actions**: 查看 `.github/workflows/azure-deploy.yml`

---

## 💡 推荐的下一步

完成部署后，建议:

1. ✅ 配置自定义域名
2. ✅ 启用 HTTPS
3. ✅ 配置 Application Insights 监控
4. ✅ 设置自动扩展
5. ✅ 配置 CDN 加速

---

## 🆘 需要帮助？

如果遇到问题，请:
1. 查看 `DEPLOYMENT_GUIDE.md` 中的故障排查部分
2. 检查 GitHub Actions 日志
3. 查看 Azure Web App 日志

---

**祝你部署顺利！** 🚀

