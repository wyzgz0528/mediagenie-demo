# 🚀 VSCode Azure 扩展部署指南

**日期**: 2025-10-27  
**目标**: 通过 VSCode Azure 扩展部署 MediaGenie �?Azure

---

## 📋 �?1 �? 安装 Azure 扩展

### 方法 A: 通过 VSCode 扩展市场 (推荐)

1. **打开 VSCode**

2. **打开扩展市场**
   - 快捷�? `Ctrl + Shift + X`
   - 或点击左侧活动栏�?"扩展" 图标

3. **搜索 Azure 扩展**
   - 搜索框输�? `Azure Tools`
   - 或搜�? `ms-vscode.vscode-node-azure-pack`

4. **安装扩展�?*
   - 点击 "Azure Tools" (�?Microsoft 官方提供)
   - 点击 "Install" 按钮
   - 等待安装完成 (�?1-2 分钟)

5. **重新加载 VSCode**
   - 点击 "Reload" 按钮
   - 或按 `Ctrl + Shift + P` 输入 "Reload Window"

### 方法 B: 通过命令行安�?
```powershell
# 安装 Azure Tools 扩展�?code --install-extension ms-vscode.vscode-node-azure-pack

# 或分别安装各个扩�?code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azureappservice
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

---

## 📋 �?2 �? 登录 Azure 账户

### �?VSCode 中登�?
1. **打开 Azure 视图**
   - �?`Ctrl + Shift + X` 打开扩展
   - 找到 "Azure" 扩展
   - 点击 "Azure Account" 中的 "Sign in to Azure"

2. **或使用命令面�?*
   - �?`Ctrl + Shift + P`
   - 输入: `Azure: Sign In`
   - �?Enter

3. **浏览器会打开**
   - 使用你的 Azure 账户登录
   - 邮箱: wangyizhe@intellnet.cn
   - 密码: [你的密码]

4. **授权 VSCode**
   - 点击 "Allow" 授权 VSCode 访问你的 Azure 账户

5. **返回 VSCode**
   - 登录完成后，VSCode 会自动关闭浏览器
   - 你会看到 Azure 视图中显示你的订�?
---

## 📋 �?3 �? 创建 Azure 资源

### 方法 A: 使用 VSCode Azure 扩展 (推荐)

1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标
   - 或按 `Ctrl + Shift + A`

2. **创建资源�?*
   - �?"Resources" 中右�?   - 选择 "Create Resource Group"
   - 输入名称: `mediagenie-rg`
   - 选择位置: `East US`

3. **创建 App Service Plan**
   - 在资源组中右�?   - 选择 "Create App Service Plan"
   - 输入名称: `mediagenie-plan`
   - 选择 SKU: `B1`

4. **创建 Web App**
   - �?App Service Plan 中右�?   - 选择 "Create Web App"
   - 输入名称: `mediagenie-backend`
   - 选择运行�? `Python 3.11`

### 方法 B: 使用 PowerShell 脚本

```powershell
# 运行之前创建的部署脚�?.\deploy-to-azure.ps1
```

---

## 📋 �?4 �? 部署代码

### 方法 A: 使用 VSCode 部署 (最简�?

1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标

2. **找到你的 Web App**
   - 展开 "App Service"
   - 找到 "mediagenie-backend"

3. **部署代码**
   - 右键点击 "mediagenie-backend"
   - 选择 "Deploy to Web App"
   - 选择要部署的文件�? `backend`
   - 点击 "Deploy"

4. **等待部署完成**
   - VSCode 会显示部署进�?   - 完成后会显示 "Deployment successful"

### 方法 B: 使用 ZIP 部署

1. **准备部署�?*
   ```powershell
   # 运行脚本创建 ZIP �?   .\quick-deploy-to-azure.ps1
   ```

2. **�?VSCode 中部�?*
   - 右键点击 Web App
   - 选择 "Deploy to Web App"
   - 选择 `backend-quick.zip`

---

## 📋 �?5 �? 配置环境变量

### �?VSCode 中配�?
1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标

2. **找到 Web App**
   - 展开 "App Service"
   - 找到 "mediagenie-backend"

3. **打开应用设置**
   - 右键点击 "mediagenie-backend"
   - 选择 "Open in Portal" �?"Application Settings"

4. **添加环境变量**
   - 点击 "New Application Setting"
   - 添加以下变量:
     ```
     DATABASE_URL = postgresql+asyncpg://dbadmin:MediaGenie@246741@mediagenie-db-5195.postgres.database.azure.com:5432/mediagenie
     ENVIRONMENT = production
     DEBUG = false
     ```

---

## 📋 �?6 �? 验证部署

### 检查部署状�?
1. **�?VSCode 中查看日�?*
   - 右键点击 Web App
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

�?VSCode �?
1. 右键点击 Web App
2. 选择 "View Streaming Logs"
3. 查看实时日志

### Q: 如何重启应用?

�?VSCode �?
1. 右键点击 Web App
2. 选择 "Restart"

### Q: 如何更新代码?

�?VSCode �?
1. 修改代码
2. 右键点击 Web App
3. 选择 "Deploy to Web App"
4. 选择要部署的文件�?
### Q: 部署失败怎么�?

1. 查看部署日志
2. 检查环境变量是否正�?3. 检查数据库连接字符�?4. 检查代码是否有错误

---

## 📚 相关文档

- `DEPLOYMENT_COMPLETE_2025-10-27.md` - 部署总结
- `AZURE_DEPLOYMENT_COMPLETE.md` - 完整部署指南
- `deploy-to-azure.ps1` - 创建资源脚本
- `quick-deploy-to-azure.ps1` - 快速部署脚�?
---

## �?总结

### 安装步骤

1. �?打开 VSCode
2. �?�?`Ctrl + Shift + X` 打开扩展
3. �?搜索 "Azure Tools"
4. �?点击 "Install"
5. �?重新加载 VSCode

### 登录步骤

1. �?�?`Ctrl + Shift + P`
2. �?输入 "Azure: Sign In"
3. �?在浏览器中登�?4. �?授权 VSCode

### 部署步骤

1. �?打开 Azure 视图
2. �?找到 Web App
3. �?右键选择 "Deploy to Web App"
4. �?选择要部署的文件�?5. �?等待部署完成

---

**下一�?*: 按照上述步骤安装 Azure 扩展并登�?
🚀 **祝你部署顺利�?*

