# 🚀 VSCode Azure 手动安装指南

**针对**: VSCode (不是 Cursor)  
**日期**: 2025-10-27

---

## 📋 �?1 �? �?VSCode 中安�?Azure 扩展

### 方法 1: 通过扩展市场 (推荐)

1. **打开 VSCode**

2. **打开扩展市场**
   - 快捷�? `Ctrl + Shift + X`
   - 或点击左侧活动栏�?"扩展" 图标

3. **搜索并安装以下扩�?* (按顺�?:

   **�?1 �?*: Azure Account
   - 搜索: `Azure Account`
   - 发布�? Microsoft
   - 点击 "Install"

   **�?2 �?*: Azure App Service
   - 搜索: `Azure App Service`
   - 发布�? Microsoft
   - 点击 "Install"

   **�?3 �?*: Azure Resource Groups
   - 搜索: `Azure Resource Groups`
   - 发布�? Microsoft
   - 点击 "Install"

   **�?4 �?*: Azure Databases
   - 搜索: `Azure Databases`
   - 发布�? Microsoft
   - 点击 "Install"

4. **重新加载 VSCode**
   - �?`Ctrl + Shift + P`
   - 输入: `Reload Window`
   - �?Enter

---

## 📋 �?2 �? 登录 Azure 账户

### �?VSCode 中登�?
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

4. **授权 VSCode**
   - 点击 "Allow" 授权 VSCode 访问你的 Azure 账户

5. **返回 VSCode**
   - 登录完成后，浏览器会自动关闭
   - VSCode 会显示你�?Azure 订阅

---

## 📋 �?3 �? 验证安装

### 检�?Azure 视图

1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标
   - 或按 `Ctrl + Shift + A`

2. **应该看到以下内容**:
   - 你的 Azure 账户名称
   - 你的订阅 (WYZ)
   - 资源组列�?   - App Service 列表

3. **如果看到这些，说明安装成功！**

---

## 🚀 �?4 �? 创建 Azure 资源

### 使用 PowerShell 脚本创建资源

打开 PowerShell 并运�?

```powershell
.\deploy-to-azure.ps1
```

这会创建:
- �?资源�? mediagenie-rg
- �?App Service 计划: mediagenie-plan
- �?后端 Web App: mediagenie-backend
- �?前端 Web App: mediagenie-frontend
- �?PostgreSQL 数据�? mediagenie-db-5195

---

## 🚀 �?5 �? 部署代码

### �?VSCode 中部署后�?
1. **打开 Azure 视图**
   - 点击左侧活动栏的 "Azure" 图标

2. **找到后端应用**
   - 展开 "App Service"
   - 找到 "mediagenie-backend"

3. **部署代码**
   - 右键点击 "mediagenie-backend"
   - 选择 "Deploy to Web App"
   - 选择要部署的文件�? `backend`
   - 点击 "Deploy"

4. **等待部署完成**
   - VSCode 会显示部署进�?   - 完成后会显示 "Deployment successful"

### �?VSCode 中部署前�?
1. **找到前端应用**
   - 展开 "App Service"
   - 找到 "mediagenie-frontend"

2. **部署代码**
   - 右键点击 "mediagenie-frontend"
   - 选择 "Deploy to Web App"
   - 选择要部署的文件�? `frontend`
   - 点击 "Deploy"

3. **等待部署完成**

---

## 🧪 �?6 �? 验证部署

### 查看实时日志

1. **�?VSCode �?*
   - 右键点击 "mediagenie-backend"
   - 选择 "View Streaming Logs"
   - 查看实时日志

2. **访问应用**
   - 后端: https://mediagenie-backend.azurewebsites.net
   - API 文档: https://mediagenie-backend.azurewebsites.net/docs
   - 健康检�? https://mediagenie-backend.azurewebsites.net/health

---

## 🆘 常见问题

### Q: 如何查看部署日志?

�?VSCode �?
1. 右键点击 Web App
2. 选择 "View Streaming Logs"

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
2. 检查环境变量是否正�?3. 检查数据库连接字符�?4. 重启应用

---

## �?总结

### 安装步骤

1. �?打开 VSCode
2. �?�?`Ctrl + Shift + X` 打开扩展
3. �?搜索并安�?Azure 扩展
4. �?重新加载 VSCode

### 登录步骤

1. �?�?`Ctrl + Shift + P`
2. �?输入 "Azure: Sign In"
3. �?在浏览器中登�?4. �?授权 VSCode

### 部署步骤

1. �?运行 `deploy-to-azure.ps1` 创建资源
2. �?�?VSCode 中部署代�?3. �?验证部署

---

**下一�?*: 按照�?1 步开始安�?Azure 扩展

🚀 **祝你部署顺利�?*

