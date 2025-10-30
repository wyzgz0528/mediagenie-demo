# MediaGenie 部署完成指南

## �?已完成的部署

###基础设施已就绪！
- �?Marketplace Portal App Service: `mediagenie-marketplace`
- �?Backend API App Service: `mediagenie-backend`  
- �?Storage Account: `mediageniesa3507` (静态网站已启用)

### 重要 URL
- **Landing Page**: https://mediagenie-marketplace.azurewebsites.net
- **Webhook**: https://mediagenie-backend.azurewebsites.net/api/marketplace/webhook
- **Frontend**: https://mediageniesa3507.z13.web.core.windows.net

---

## 📋 待完成：部署应用代码

由于本地 Azure CLI 会话不稳定，建议使用 **Azure Portal** 完成代码部署�?

### 方法 1: 使用 Azure Portal 部署 (推荐)

#### 步骤 1: 部署 Marketplace Portal

1. 访问 Azure Portal: https://portal.azure.com
2. 导航到：**资源�?* �?**MediaGenie-RG** �?**mediagenie-marketplace**
3. 左侧菜单点击�?*部署中心** (Deployment Center)
4. 选择源：**本地 Git** �?**ZIP 部署**

**使用 ZIP 部署（最简单）�?*
```powershell
# 在本地打�?
cd F:\project\MediaGenie1001\marketplace-portal
Compress-Archive -Path * -DestinationPath ..\marketplace-portal.zip -Force
```

5. �?Azure Portal �?App Service 页面:
   - 点击顶部 **高级工具** �?**转到**
   - �?Kudu 界面，点击顶�?**Tools** �?**ZIP Push Deploy**
   - 拖拽 `marketplace-portal.zip` 到浏览器窗口上传

6. 配置启动命令:
   - 返回 App Service 页面
   - 左侧菜单�?*配置** �?**常规设置**
   - **启动命令**: `gunicorn --bind=0.0.0.0:8000 --timeout 600 app:app`
   - 点击 **保存**
   - 点击 **重启**

#### 步骤 2: 部署 Backend API

重复步骤 1，但针对 `mediagenie-backend`:

```powershell
# 打包 Backend
cd F:\project\MediaGenie1001\backend\media-service
Compress-Archive -Path * -DestinationPath ..\..\backend-api.zip -Force
```

- App Service: **mediagenie-backend**
- ZIP 文件: `backend-api.zip`
- 启动命令: `gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 4 main:app`

#### 步骤 3: 部署 Frontend 静态网�?

**选项 A: 使用 Azure Portal**

1. 访问: https://portal.azure.com
2. 导航到：**存储账户** �?**mediageniesa3507**
3. 左侧菜单�?*数据管理** �?**静态网�?*
4. 确认已启用，索引文档: `index.html`
5. 点击 **$web** 容器
6. 点击顶部 **上传**
7. 上传文件: `F:\project\MediaGenie1001\frontend-simple\index.html`

**选项 B: 构建并部署完�?React 应用**

```powershell
# 构建 Frontend
cd F:\project\MediaGenie1001\frontend
npm install --legacy-peer-deps
$env:REACT_APP_MEDIA_SERVICE_URL="https://mediagenie-backend.azurewebsites.net"
npm run build

# 使用 Azure Storage Explorer 上传
# 或在 Portal 中手动上�?build/ 目录下的所有文件到 $web 容器
```

---

### 方法 2: 使用 Azure Cloud Shell (如果本地 CLI 不稳�?

1. 访问: https://shell.azure.com
2. 选择 **PowerShell** 环境
3. 切换�?WYZ 订阅:
```bash
az account set --subscription "WYZ"
```

4. 上传 ZIP 文件�?Cloud Shell (点击上传按钮)

5. 部署 Marketplace Portal:
```bash
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace \
  --src marketplace-portal.zip
  
az webapp config set \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace \
  --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 app:app"
  
az webapp restart \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace
```

6. 部署 Backend API:
```bash
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --src backend-api.zip
  
az webapp config set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 4 main:app"
  
az webapp restart \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend
```

7. 上传 Frontend 文件:
```bash
az storage blob upload \
  --account-name mediageniesa3507 \
  --container-name '$web' \
  --name index.html \
  --file frontend-simple/index.html \
  --content-type "text/html" \
  --overwrite
```

---

## 🔍 验证部署

### 1. 检�?Marketplace Portal
```
访问: https://mediagenie-marketplace.azurewebsites.net
预期: 看到 Landing Page 或应用界�?
```

### 2. 检�?Backend API
```
访问: https://mediagenie-backend.azurewebsites.net/health
预期: {"status": "healthy"}

访问: https://mediagenie-backend.azurewebsites.net/docs
预期: FastAPI 文档界面
```

### 3. 检�?Frontend
```
访问: https://mediageniesa3507.z13.web.core.windows.net
预期: 看到 MediaGenie 首页
```

### 4. 测试 Webhook
```powershell
Invoke-WebRequest -Method POST `
  -Uri "https://mediagenie-backend.azurewebsites.net/api/marketplace/webhook" `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"action":"test"}' `
  | Select-Object StatusCode, Content
```

---

## 🐛 故障排查

### 应用显示 "Application Error"

1. 查看日志:
   - Portal: App Service �?**监视** �?**日志�?*
   - �?Kudu: `https://<app-name>.scm.azurewebsites.net` �?**Log Stream**

2. 检查启动命令是否正�?
3. 确认requirements.txt中的依赖已安�?

### 应用显示 503 错误

- 应用可能正在启动（冷启动需�?-2分钟�?
- 等待几分钟后重试

### Frontend 显示 404

- 确认静态网站已启用
- 确认文件已上传到 `$web` 容器
- 检查文件名是否�?`index.html`

---

## 📝 下一步：提交�?Azure Marketplace

部署并验证成功后�?

1. 登录 Partner Center: https://partner.microsoft.com/dashboard/marketplace-offers/overview
2. 找到 MediaGenie 产品
3. 进入 **Technical configuration**
4. 填写:
   - **Landing page URL**: `https://mediagenie-marketplace.azurewebsites.net`
   - **Connection webhook**: `https://mediagenie-backend.azurewebsites.net/api/marketplace/webhook`
5. 保存并提交审�?

---

## 📂 本地文件位置

- Marketplace Portal ZIP: `F:\project\MediaGenie1001\marketplace-portal.zip`
- Backend API ZIP: `F:\project\MediaGenie1001\backend-api.zip`
- Frontend 测试�? `F:\project\MediaGenie1001\frontend-simple\index.html`
- Frontend 完整�? `F:\project\MediaGenie1001\frontend\build\`

---

## 💡 提示

- 使用 Portal 部署最可靠，避�?CLI 问题
- 每次修改启动命令后记�?*重启**应用
- 检查日志是诊断问题的最佳方�?
- 首次访问可能需要等�?-2分钟（冷启动�?

---

## 🎯 部署检查清�?

- [ ] Marketplace Portal 代码已部�?
- [ ] Marketplace Portal 启动命令已配�?
- [ ] Marketplace Portal 应用已重�?
- [ ] Marketplace Portal 可访�?
- [ ] Backend API 代码已部�?
- [ ] Backend API 启动命令已配�?
- [ ] Backend API 应用已重�?
- [ ] Backend API /health 返回正常
- [ ] Backend API /docs 可访�?
- [ ] Frontend index.html 已上�?
- [ ] Frontend 静态网站可访问
- [ ] Webhook 测试通过
- [ ] 已在 Partner Center 提交 URL
