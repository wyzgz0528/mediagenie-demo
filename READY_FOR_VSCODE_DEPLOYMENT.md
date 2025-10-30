# �?MediaGenie VS Code 部署就绪

## 🎯 配置完成总结

我已经为你完全配置好了所有文件，现在可以直接通过VS Code Azure扩展部署到Azure Web App�?
### �?已配置的组件

#### 1. Backend (backend/media-service/)
- �?**CORS配置**: 已更新支持生产域�?- �?**启动配置**: `startup.txt` (Gunicorn)
- �?**部署配置**: `.deployment` + `deploy.cmd`
- �?**环境变量**: `.env` 包含所有Azure服务密钥

#### 2. Frontend (frontend/)
- �?**生产服务�?*: `server.js` (Express + 静态文件服�?
- �?**启动脚本**: `package.json` 已更�?- �?**环境配置**: `.env` + `.env.production`
- �?**部署配置**: `web.config` + `.deployment` + `deploy.cmd`
- �?**依赖管理**: 已添�?Express 依赖

#### 3. Marketplace Portal (marketplace-portal/)
- �?**启动配置**: `startup.txt` (Gunicorn)
- �?**部署配置**: `.deployment` + `deploy.cmd`
- �?**Flask应用**: 已配置完�?
---

## 🚀 立即开始部�?
### 第一步：构建前端

```powershell
# 在项目根目录执行
.\build-for-deployment.ps1
```

这将�?- 安装前端依赖
- 构建React应用
- 验证构建结果

### 第二步：VS Code 部署

#### 部署后端
1. 在VS Code中打开Azure扩展
2. 右键点击 `backend/media-service` 文件�?3. 选择 "Deploy to Web App..."
4. 配置�?   - Resource Group: `mediagenie`
   - Web App Name: `mediagenie-backend-prod`
   - Runtime: `Python 3.11`

#### 部署前端
1. 右键点击 `frontend` 文件�?2. 选择 "Deploy to Web App..."
3. 配置�?   - Resource Group: `mediagenie`
   - Web App Name: `mediagenie-frontend-prod`
   - Runtime: `Node 18 LTS`

#### 部署Portal (可�?
1. 右键点击 `marketplace-portal` 文件�?2. 选择 "Deploy to Web App..."
3. 配置�?   - Resource Group: `mediagenie`
   - Web App Name: `mediagenie-portal-prod`
   - Runtime: `Python 3.11`

---

## 🔗 预期的URL

部署完成后，你将获得以下URL�?
```
后端API: https://mediagenie-backend-prod.azurewebsites.net
前端应用: https://mediagenie-frontend-prod.azurewebsites.net
Portal页面: https://mediagenie-portal-prod.azurewebsites.net
```

---

## �?验证清单

### 后端验证
- [ ] 健康检�? `https://mediagenie-backend-prod.azurewebsites.net/health`
- [ ] API文档: `https://mediagenie-backend-prod.azurewebsites.net/docs`
- [ ] 无启动错�?
### 前端验证
- [ ] 健康检�? `https://mediagenie-frontend-prod.azurewebsites.net/health`
- [ ] 主页访问: `https://mediagenie-frontend-prod.azurewebsites.net`
- [ ] 无控制台错误
- [ ] 能调用后端API

### 集成验证
- [ ] 前后端通信正常
- [ ] 无CORS错误
- [ ] 所有功能正常工�?
---

## 🔧 关键配置说明

### CORS配置
后端已配置支持以下域名：
```python
allow_origins=[
    "https://mediagenie-frontend-prod.azurewebsites.net",
    "https://mediagenie-backend-prod.azurewebsites.net", 
    "https://mediagenie-portal-prod.azurewebsites.net",
    # 还包括其他可能的命名模式
]
```

### 环境变量
前端生产环境已配置：
```bash
REACT_APP_API_URL=https://mediagenie-backend-prod.azurewebsites.net/api
REACT_APP_USER_SERVICE_URL=https://mediagenie-backend-prod.azurewebsites.net/api
REACT_APP_MEDIA_SERVICE_URL=https://mediagenie-backend-prod.azurewebsites.net/api
```

### 启动命令
- **后端**: `gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000 --timeout 120`
- **前端**: `node server.js`
- **Portal**: `gunicorn -w 2 -b 0.0.0.0:8000 app:app --timeout 120`

---

## 🆘 如果遇到问题

### 常见问题解决

1. **构建失败**:
   ```bash
   cd frontend
   npm install
   npm run build
   ```

2. **部署失败**:
   - 检查Azure订阅权限
   - 确保资源�?`mediagenie` 存在
   - 查看VS Code输出面板的错误信�?
3. **应用无法启动**:
   - 查看Azure Portal中的日志�?   - 检查启动命令是否正�?   - 验证依赖是否正确安装

### 查看日志
在Azure Portal中：
1. 进入对应的Web App
2. 选择 "Log stream"
3. 查看实时日志

---

## 🎉 准备就绪�?
所有配置已完成，你现在可以�?
1. **运行构建脚本**: `.\build-for-deployment.ps1`
2. **使用VS Code Azure扩展部署**
3. **验证部署结果**
4. **开始使用MediaGenie**

**祝你部署顺利�?* 🚀

如有任何问题，请查看详细指南：`VSCODE_DEPLOYMENT_GUIDE.md`
