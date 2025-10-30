# 🚀 VS Code Azure 扩展部署指南

## 📋 准备工作

我已经为你配置好了所有必要的文件，现在可以直接通过VS Code Azure扩展部署�?
### �?已配置的文件

#### Backend (backend/media-service/)
- �?`main.py` - 更新了CORS配置
- �?`startup.txt` - Gunicorn启动命令
- �?`.deployment` - Kudu部署配置
- �?`deploy.cmd` - Python部署脚本
- �?`.env` - 环境变量配置

#### Frontend (frontend/)
- �?`package.json` - 更新了启动脚本和依赖
- �?`server.js` - Express生产服务�?- �?`.env` - 开发环境配�?- �?`.env.production` - 生产环境配置
- �?`web.config` - IIS配置
- �?`.deployment` - Kudu部署配置
- �?`deploy.cmd` - Node.js部署脚本

---

## 🎯 建议的Web App名称

基于资源组名�?`mediagenie`，建议使用以下名称：

- **后端**: `mediagenie-backend-prod`
- **前端**: `mediagenie-frontend-prod`
- **Portal**: `mediagenie-portal-prod`

---

## 🚀 部署步骤

### 第一步：部署后端

1. **在VS Code中打开Azure扩展**
2. **右键点击 `backend/media-service` 文件�?*
3. **选择 "Deploy to Web App..."**
4. **配置设置**:
   - Subscription: 选择你的订阅
   - Resource Group: `mediagenie`
   - Web App Name: `mediagenie-backend-prod`
   - Runtime: `Python 3.11`
   - Pricing Tier: `B1` �?`B2`

5. **等待部署完成** (�?-10分钟)

### 第二步：构建前端

在部署前端之前，需要先构建React应用�?
```bash
cd frontend
npm install
npm run build
```

### 第三步：部署前端

1. **确保 `frontend/build` 目录存在**
2. **右键点击 `frontend` 文件�?*
3. **选择 "Deploy to Web App..."**
4. **配置设置**:
   - Subscription: 选择你的订阅
   - Resource Group: `mediagenie`
   - Web App Name: `mediagenie-frontend-prod`
   - Runtime: `Node 18 LTS`
   - Pricing Tier: `B1` �?`B2`

5. **等待部署完成** (�?-5分钟)

---

## �?验证部署

### 后端验证

访问以下URL验证后端�?
```
健康检�? https://mediagenie-backend-prod.azurewebsites.net/health
API文档: https://mediagenie-backend-prod.azurewebsites.net/docs
```

**期望响应**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-27T...",
  "version": "1.0.0",
  "services": {
    "azure_speech": "available",
    "azure_vision": "available", 
    "azure_openai": "available",
    "azure_storage": "available"
  }
}
```

### 前端验证

访问以下URL验证前端�?
```
健康检�? https://mediagenie-frontend-prod.azurewebsites.net/health
主页: https://mediagenie-frontend-prod.azurewebsites.net
```

**期望响应**:
```json
{
  "status": "ok",
  "service": "mediagenie-frontend",
  "timestamp": "2025-10-27T...",
  "port": 8080,
  "environment": "production"
}
```

---

## 🔧 Azure Web App 配置

### 后端应用设置

在Azure Portal中为后端Web App添加以下应用设置�?
```
WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
SCM_DO_BUILD_DURING_DEPLOYMENT = true
WEBSITE_HTTPLOGGING_RETENTION_DAYS = 3
```

### 前端应用设置

在Azure Portal中为前端Web App添加以下应用设置�?
```
WEBSITE_NODE_DEFAULT_VERSION = 18-lts
SCM_DO_BUILD_DURING_DEPLOYMENT = false
WEBSITE_RUN_FROM_PACKAGE = 1
```

---

## 🔍 故障排除

### 常见问题

1. **后端启动失败**:
   - 检�?`startup.txt` 文件是否存在
   - 查看Azure Portal中的日志�?   - 确保所有Python依赖都在 `requirements.txt` �?
2. **前端显示错误页面**:
   - 确保 `build/` 目录已包含在部署�?   - 检�?`server.js` 是否正确启动
   - 查看Azure Portal中的日志�?
3. **CORS错误**:
   - 确保后端CORS配置包含前端域名
   - 检查前端环境变量是否指向正确的后端URL

### 查看日志

在Azure Portal中：
1. 进入Web App
2. 选择 "Log stream"
3. 查看实时日志输出

---

## 📝 下一�?
部署成功后：

1. **测试所有功�?*:
   - 语音转文�?   - 文字转语�?   - 图像分析
   - GPT聊天

2. **配置自定义域�?* (可�?

3. **设置SSL证书** (Azure自动提供)

4. **准备Azure Marketplace提交**:
   - Landing Page URL: `https://mediagenie-portal-prod.azurewebsites.net`
   - Webhook URL: `https://mediagenie-backend-prod.azurewebsites.net/marketplace/webhook`

---

## 🎉 完成�?
按照这个指南，你应该能够成功部署MediaGenie到Azure Web App�?
如果遇到任何问题，请查看Azure Portal中的日志或联系我获取帮助�?