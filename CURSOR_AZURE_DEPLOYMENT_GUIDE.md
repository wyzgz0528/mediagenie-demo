# 🚀 Cursor Azure 部署指南

**日期**: 2025-10-27  
**编辑�?*: Cursor (基于 VSCode)  
**目标**: 通过 Cursor 部署 MediaGenie �?Azure

---

## 📋 �?1 �? �?Cursor 中安�?Azure 扩展

### 方法 A: 使用脚本 (推荐)

�?PowerShell 中运�?
```powershell
.\install-azure-extensions-fixed.ps1
```

### 方法 B: 手动安装

1. **打开 Cursor**

2. **打开扩展市场**
   - 快捷�? `Ctrl + Shift + X`

3. **搜索并安�?Azure Account**
   - 搜索: `Azure Account`
   - 点击 "Install"

4. **搜索并安�?Azure App Service**
   - 搜索: `Azure App Service`
   - 点击 "Install"

5. **重新加载 Cursor**
   - �?`Ctrl + Shift + P`
   - 输入: `Reload Window`
   - �?Enter

---

## 📋 �?2 �? �?Cursor 中登�?Azure

### 登录步骤

1. **打开命令面板**
   - 快捷�? `Ctrl + Shift + P`

2. **输入登录命令**
   - 输入: `Azure: Sign In`
   - �?Enter

3. **浏览器会打开**
   - 使用以下凭证登录:
     ```
     邮箱: wangyizhe@intellnet.cn
     密码: [你的密码]
     ```

4. **授权 Cursor**
   - 点击 "Allow" 授权 Cursor 访问你的 Azure 账户

5. **返回 Cursor**
   - 登录完成后，浏览器会自动关闭
   - Cursor 会显示你�?Azure 订阅

---

## 📋 �?3 �? 创建 Azure 资源

### 使用 PowerShell 脚本 (最�?

```powershell
# 运行部署脚本创建所有资�?.\deploy-to-azure.ps1
```

这个脚本会创�?
- �?资源�? mediagenie-rg
- �?App Service 计划: mediagenie-plan
- �?后端 Web App: mediagenie-backend
- �?前端 Web App: mediagenie-frontend
- �?PostgreSQL 数据�? mediagenie-db-5195

**预期输出**:
```
Resource Group: mediagenie-rg created
App Service Plan: mediagenie-plan created
Backend Web App: mediagenie-backend created
Frontend Web App: mediagenie-frontend created
PostgreSQL Database: mediagenie-db-5195 created
```

---

## 📋 �?4 �? 准备部署�?
### 创建部署�?
```powershell
# 运行脚本创建 ZIP 部署�?.\quick-deploy-to-azure.ps1
```

这会创建:
- �?`backend-quick.zip` - 后端部署�?- �?`frontend-quick.zip` - 前端部署�?
---

## 📋 �?5 �? 部署代码

### 方法 A: 使用 Cursor 部署 (推荐)

1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标
   - 或按 `Ctrl + Shift + A`

2. **找到后端应用**
   - 展开 "App Service"
   - 找到 "mediagenie-backend"

3. **部署代码**
   - 右键点击 "mediagenie-backend"
   - 选择 "Deploy to Web App"
   - 选择要部署的文件�? `backend`
   - 点击 "Deploy"

4. **等待部署完成**
   - Cursor 会显示部署进�?   - 完成后会显示 "Deployment successful"

### 方法 B: 使用 Azure CLI

```powershell
# 登录
az login

# 部署后端
az webapp deployment source config-zip `
    --resource-group mediagenie-rg `
    --name mediagenie-backend `
    --src backend-quick.zip

# 部署前端
az webapp deployment source config-zip `
    --resource-group mediagenie-rg `
    --name mediagenie-frontend `
    --src frontend-quick.zip

# 重启应用
az webapp restart --resource-group mediagenie-rg --name mediagenie-backend
az webapp restart --resource-group mediagenie-rg --name mediagenie-frontend
```

---

## 📋 �?6 �? 配置环境变量

### �?Azure Portal 中配�?
1. **打开 Azure Portal**
   - 访问: https://portal.azure.com

2. **找到后端应用**
   - 搜索: `mediagenie-backend`

3. **打开应用设置**
   - 左侧菜单 �?"Configuration"

4. **添加环境变量**
   - 点击 "New application setting"
   - 添加以下变量:

   ```
   DATABASE_URL = postgresql+asyncpg://dbadmin:MediaGenie@246741@mediagenie-db-5195.postgres.database.azure.com:5432/mediagenie
   ENVIRONMENT = production
   DEBUG = false
   ```

5. **保存设置**
   - 点击 "Save"

---

## 📋 �?7 �? 验证部署

### 检查部署状�?
1. **查看实时日志**
   - �?Cursor 中右键点�?Web App
   - 选择 "View Streaming Logs"
   - 查看实时日志

2. **访问应用**
   - 后端: https://mediagenie-backend.azurewebsites.net
   - API 文档: https://mediagenie-backend.azurewebsites.net/docs
   - 健康检�? https://mediagenie-backend.azurewebsites.net/health

3. **检查数据库连接**
   - 查看日志中是否有数据库连接错�?   - 如果有错误，检�?DATABASE_URL 是否正确

---

## 🆘 常见问题

### Q: 如何查看部署日志?

�?Cursor �?
1. 右键点击 Web App
2. 选择 "View Streaming Logs"

### Q: 如何重启应用?

�?Cursor �?
1. 右键点击 Web App
2. 选择 "Restart"

### Q: 如何更新代码?

�?Cursor �?
1. 修改代码
2. 右键点击 Web App
3. 选择 "Deploy to Web App"
4. 选择要部署的文件�?
### Q: 部署失败怎么�?

1. 查看部署日志
2. 检查环境变量是否正�?3. 检查数据库连接字符�?4. 检查代码是否有错误

---

## �?总结

按照以上 7 个步骤，你可�?
1. �?�?Cursor 中安�?Azure 扩展
2. �?登录 Azure 账户
3. �?创建 Azure 资源
4. �?准备部署�?5. �?部署代码
6. �?配置环境变量
7. �?验证部署

---

## 📚 相关文档

- `VSCODE_AZURE_DEPLOYMENT_GUIDE.md` - VSCode 部署指南
- `VSCODE_DEPLOYMENT_STEPS.md` - 详细步骤指南
- `install-azure-extensions-fixed.ps1` - 扩展安装脚本
- `deploy-to-azure.ps1` - 创建资源脚本
- `quick-deploy-to-azure.ps1` - 快速部署脚�?
---

## 🚀 立即开�?
**�?1 �?*: �?PowerShell 中运�?
```powershell
.\install-azure-extensions-fixed.ps1
```

**�?2 �?*: 重新启动 Cursor

**�?3 �?*: 按照上述步骤继续

🚀 **祝你部署顺利�?*

