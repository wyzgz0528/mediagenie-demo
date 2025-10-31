# MediaGenie Azure 部署指南

本指南将帮助你通过 GitHub Actions 将 MediaGenie 项目部署到 Azure Web App。

## 📋 前置要求

- Azure 订阅账号 (wangyizhe@intellnet.cn)
- GitHub 账号 (wyzgz0528)
- Azure CLI 已安装并登录
- Git 已安装

## 🚀 部署步骤

### 第 1 步: 创建 Azure Container Registry (ACR)

Azure Container Registry 用于存储 Docker 镜像。

```bash
# 登录 Azure
az login

# 创建 ACR
az acr create \
  --resource-group mediagenie-rg \
  --name mediageniecr \
  --sku Basic \
  --location eastus2

# 启用管理员账户
az acr update --name mediageniecr --admin-enabled true

# 获取 ACR 凭据
az acr credential show --name mediageniecr
```

记录以下信息:
- **ACR 登录服务器**: `mediageniecr.azurecr.io`
- **用户名**: (从上面命令输出获取)
- **密码**: (从上面命令输出获取)

### 第 2 步: 配置 Azure Web App 使用容器

```bash
# 配置后端 Web App 使用容器
az webapp config container set \
  --name mediagenie-backend \
  --resource-group mediagenie-rg \
  --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-backend:latest \
  --docker-registry-server-url https://mediageniecr.azurecr.io \
  --docker-registry-server-user <ACR_USERNAME> \
  --docker-registry-server-password <ACR_PASSWORD>

# 配置前端 Web App 使用容器
az webapp config container set \
  --name mediagenie-frontend \
  --resource-group mediagenie-rg \
  --docker-custom-image-name mediageniecr.azurecr.io/mediagenie-frontend:latest \
  --docker-registry-server-url https://mediageniecr.azurecr.io \
  --docker-registry-server-user <ACR_USERNAME> \
  --docker-registry-server-password <ACR_PASSWORD>

# 配置后端端口
az webapp config appsettings set \
  --name mediagenie-backend \
  --resource-group mediagenie-rg \
  --settings WEBSITES_PORT=8000

# 配置前端端口
az webapp config appsettings set \
  --name mediagenie-frontend \
  --resource-group mediagenie-rg \
  --settings WEBSITES_PORT=8080
```

### 第 3 步: 获取 Web App 发布配置文件

```bash
# 获取后端发布配置文件
az webapp deployment list-publishing-profiles \
  --name mediagenie-backend \
  --resource-group mediagenie-rg \
  --xml > backend-publish-profile.xml

# 获取前端发布配置文件
az webapp deployment list-publishing-profiles \
  --name mediagenie-frontend \
  --resource-group mediagenie-rg \
  --xml > frontend-publish-profile.xml
```

### 第 4 步: 配置 GitHub Secrets

1. 打开 GitHub 仓库: https://github.com/wyzgz0528/MediaGenie1001
2. 进入 **Settings** > **Secrets and variables** > **Actions**
3. 点击 **New repository secret** 添加以下 secrets:

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `ACR_LOGIN_SERVER` | `mediageniecr.azurecr.io` | ACR 登录服务器 |
| `ACR_USERNAME` | (从第1步获取) | ACR 用户名 |
| `ACR_PASSWORD` | (从第1步获取) | ACR 密码 |
| `AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE` | (backend-publish-profile.xml 的内容) | 后端发布配置 |
| `AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE` | (frontend-publish-profile.xml 的内容) | 前端发布配置 |

### 第 5 步: 初始化 Git 仓库并推送

```bash
# 初始化 Git 仓库 (如果还没有)
git init

# 添加远程仓库
git remote add origin https://github.com/wyzgz0528/MediaGenie1001.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: Docker-based deployment"

# 推送到 GitHub (会触发 GitHub Actions)
git push -u origin main
```

### 第 6 步: 监控部署

1. 打开 GitHub 仓库
2. 进入 **Actions** 标签
3. 查看 "Deploy to Azure Web App" 工作流的运行状态
4. 等待部署完成 (通常需要 5-10 分钟)

### 第 7 步: 验证部署

部署完成后，访问以下 URL 验证:

- **后端健康检查**: https://mediagenie-backend.azurewebsites.net/health
- **后端 API 文档**: https://mediagenie-backend.azurewebsites.net/docs
- **前端应用**: https://mediagenie-frontend.azurewebsites.net

## 🔧 故障排查

### 问题 1: GitHub Actions 构建失败

**解决方案:**
1. 检查 GitHub Secrets 是否正确配置
2. 查看 Actions 日志中的错误信息
3. 确保 ACR 凭据正确

### 问题 2: 容器启动失败

**解决方案:**
1. 在 Azure Portal 中查看 Web App 日志
2. 检查环境变量是否正确配置
3. 确保 WEBSITES_PORT 设置正确

### 问题 3: 数据库连接失败

**解决方案:**
1. 检查 DATABASE_URL 环境变量
2. 确保 PostgreSQL 防火墙规则允许 Azure 服务访问
3. 验证数据库凭据

### 查看日志

```bash
# 查看后端日志
az webapp log tail --name mediagenie-backend --resource-group mediagenie-rg

# 查看前端日志
az webapp log tail --name mediagenie-frontend --resource-group mediagenie-rg
```

## 📝 后续更新

每次推送到 `main` 分支时，GitHub Actions 会自动:
1. 构建新的 Docker 镜像
2. 推送到 ACR
3. 部署到 Azure Web App

## 🔄 手动触发部署

如果需要手动触发部署:
1. 进入 GitHub 仓库的 **Actions** 标签
2. 选择 "Deploy to Azure Web App" 工作流
3. 点击 **Run workflow** 按钮
4. 选择 `main` 分支
5. 点击 **Run workflow**

## 📚 相关文档

- [Azure Container Registry 文档](https://docs.microsoft.com/azure/container-registry/)
- [Azure Web App for Containers 文档](https://docs.microsoft.com/azure/app-service/containers/)
- [GitHub Actions 文档](https://docs.github.com/actions)

## 💡 最佳实践

1. **使用环境变量**: 不要在代码中硬编码敏感信息
2. **定期更新依赖**: 保持 Docker 基础镜像和依赖包最新
3. **监控应用**: 使用 Azure Application Insights 监控应用性能
4. **备份数据库**: 定期备份 PostgreSQL 数据库
5. **使用 staging 环境**: 在生产环境前先在 staging 环境测试

## 🎯 下一步

- [ ] 配置自定义域名
- [ ] 启用 HTTPS
- [ ] 配置 Application Insights
- [ ] 设置自动扩展
- [ ] 配置 CDN 加速前端资源

