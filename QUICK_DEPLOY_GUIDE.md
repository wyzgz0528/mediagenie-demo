# MediaGenie 快速部署指南（Azure Portal 方法�?

## 🎯 当前状�?
- �?Azure 资源已创�?
- �?ZIP 包已准备�?
- �?需要上传代�?

## 📦 已准备的部署�?
- `marketplace-portal.zip` - Marketplace Portal 应用
- `backend-api.zip` - Backend API 应用  
- `frontend-simple/index.html` - Frontend 测试�?

---

## 🚀 3 步完成部署（最简单方法）

### 步骤 1: 部署 Marketplace Portal

1. 打开浏览器访问：
   ```
   https://mediagenie-marketplace.scm.azurewebsites.net/ZipDeployUI
   ```

2. 会提示登录，使用您的 Azure 账号登录

3. 页面加载后，�?`F:\project\MediaGenie1001\marketplace-portal.zip` 拖拽到浏览器窗口

4. 等待上传完成�?-2分钟�?

5. 配置启动命令:
   - 访问: https://portal.azure.com
   - 导航: 资源�?�?MediaGenie-RG �?mediagenie-marketplace
   - 左侧菜单: 配置 �?常规设置
   - 启动命令: `gunicorn --bind=0.0.0.0:8000 --timeout 600 app:app`
   - 点击"保存"，然后点�?重启"

6. 验证: 访问 https://mediagenie-marketplace.azurewebsites.net

---

### 步骤 2: 部署 Backend API

1. 打开浏览器访问：
   ```
   https://mediagenie-backend.scm.azurewebsites.net/ZipDeployUI
   ```

2. 登录后，拖拽 `F:\project\MediaGenie1001\backend-api.zip` 到浏览器

3. 配置启动命令:
   - Portal: MediaGenie-RG �?mediagenie-backend �?配置
   - 启动命令: `gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 4 main:app`
   - 保存并重�?

4. 验证:
   - Health: https://mediagenie-backend.azurewebsites.net/health
   - Docs: https://mediagenie-backend.azurewebsites.net/docs

---

### 步骤 3: 部署 Frontend

1. 访问 Azure Portal: https://portal.azure.com

2. 导航: 资源�?�?MediaGenie-RG �?mediageniesa3507

3. 左侧菜单: 数据存储 �?容器

4. 点击 `$web` 容器

5. 点击"上传"按钮

6. 选择文件: `F:\project\MediaGenie1001\frontend-simple\index.html`

7. 点击"上传"

8. 验证: 访问 https://mediageniesa3507.z13.web.core.windows.net

---

## �?验证清单

完成上述步骤后，检�?

- [ ] https://mediagenie-marketplace.azurewebsites.net - 显示 Landing Page
- [ ] https://mediagenie-backend.azurewebsites.net/health - 返回 `{"status":"healthy"}`  
- [ ] https://mediagenie-backend.azurewebsites.net/docs - 显示 API 文档
- [ ] https://mediageniesa3507.z13.web.core.windows.net - 显示 Frontend 页面

---

## 🎊 完成�?

所有服务运行正常后，您就可以：

1. �?Azure Marketplace Partner Center 提交:
   - Landing Page URL: `https://mediagenie-marketplace.azurewebsites.net`
   - Webhook URL: `https://mediagenie-backend.azurewebsites.net/api/marketplace/webhook`

2. 测试 Webhook:
   ```powershell
   Invoke-WebRequest -Method POST `
     -Uri "https://mediagenie-backend.azurewebsites.net/api/marketplace/webhook" `
     -Headers @{"Content-Type"="application/json"} `
     -Body '{"action":"test"}'
   ```

---

## 💡 提示

- ZipDeployUI 是最简单的部署方法，无需 CLI
- 拖拽上传后等待绿色成功消�?
- 修改启动命令后必须重启应�?
- 首次访问可能需�?1-2 分钟冷启�?

---

## 🔗 快速链�?

- Marketplace Portal ZipDeploy: https://mediagenie-marketplace.scm.azurewebsites.net/ZipDeployUI
- Backend API ZipDeploy: https://mediagenie-backend.scm.azurewebsites.net/ZipDeployUI  
- Azure Portal: https://portal.azure.com
- Resource Group: https://portal.azure.com/#@/resource/subscriptions/3628daff-52ae-4f64-a310-28ad4b2158ca/resourceGroups/MediaGenie-RG/overview
