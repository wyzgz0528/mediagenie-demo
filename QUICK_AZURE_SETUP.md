# 🚀 快�?Azure 部署指南 (VSCode 方式)

**日期**: 2025-10-27  
**方法**: 使用 VSCode Azure 扩展 + Azure Portal

---

## ⚠️ 当前状�?
你已经有:
- �?资源�? `mediagenie-rg` (已创�?
- �?App Service 计划: `mediagenie-plan` (已创�?
- �?后端 Web App: `mediagenie-backend` (已创�? Python 3.11)
- �?前端 Web App: `mediagenie-frontend` (已创�? Node.js 22 LTS)
- �?PostgreSQL 数据�? `mediagenie-db-XXXX` (已创�? East US 2)

**下一�?*: 配置应用设置

---

## 📋 方法 1: 使用 Azure Portal (最简�?

### �?1 �? 打开 Azure Portal

1. 打开浏览器访�? https://portal.azure.com
2. 登录: wangyizhe@intellnet.cn

### �?2 �? 创建后端 Web App

1. 点击 "创建资源"
2. 搜索 "Web App"
3. 点击 "创建"
4. 填写以下信息:
   ```
   资源�? mediagenie-rg
   名称: mediagenie-backend
   发布: 代码
   运行时堆�? Python 3.11
   操作系统: Linux
   App Service 计划: mediagenie-plan
   ```
5. 点击 "创建"

### �?3 �? 创建前端 Web App

1. 点击 "创建资源"
2. 搜索 "Web App"
3. 点击 "创建"
4. 填写以下信息:
   ```
   资源�? mediagenie-rg
   名称: mediagenie-frontend
   发布: 代码
   运行时堆�? Node.js 18 LTS
   操作系统: Linux
   App Service 计划: mediagenie-plan
   ```
5. 点击 "创建"

### �?4 �? 创建 PostgreSQL 数据�?
1. 点击 "创建资源"
2. 搜索 "Azure Database for PostgreSQL"
3. 选择 "灵活服务�?
4. 点击 "创建"
5. 填写以下信息:
   ```
   资源�? mediagenie-rg
   服务器名�? mediagenie-db-[随机数]
   位置: East US
   PostgreSQL 版本: 15
   计算 + 存储: 可突�? B1ms
   管理员用户名: dbadmin
   管理员密�? MediaGenie@[随机数]
   ```
6. 点击 "创建"

### �?5 �? 配置应用设置

**对于后端 (mediagenie-backend)**:

1. 打开 mediagenie-backend Web App
2. 左侧菜单 �?"配置"
3. 点击 "新应用设�?
4. 添加以下设置:
   ```
   DATABASE_URL = postgresql+asyncpg://dbadmin:PASSWORD@mediagenie-db-XXXX.postgres.database.azure.com:5432/mediagenie
   ENVIRONMENT = production
   DEBUG = false
   ```
5. 点击 "保存"

**对于前端 (mediagenie-frontend)**:

1. 打开 mediagenie-frontend Web App
2. 左侧菜单 �?"配置"
3. 点击 "新应用设�?
4. 添加以下设置:
   ```
   REACT_APP_MEDIA_SERVICE_URL = https://mediagenie-backend.azurewebsites.net
   REACT_APP_ENV = production
   ```
5. 点击 "保存"

---

## 📋 方法 2: 使用 VSCode Azure 扩展

### �?1 �? �?VSCode 中打开 Azure 视图

1. 点击左侧活动栏的 "Azure" 图标
2. 或按 `Ctrl + Shift + A`

### �?2 �? 创建 Web App

1. �?"App Service" 中右�?2. 选择 "Create Web App"
3. 输入名称: `mediagenie-backend`
4. 选择运行�? `Python 3.11`
5. 等待创建完成

重复上述步骤创建前端 Web App:
1. 输入名称: `mediagenie-frontend`
2. 选择运行�? `Node.js 18 LTS`

### �?3 �? 创建数据�?
1. �?"Databases" 中右�?2. 选择 "Create Database"
3. 选择 "PostgreSQL"
4. 填写信息并创�?
### �?4 �? 配置应用设置

1. 右键点击 Web App
2. 选择 "Application Settings"
3. 添加环境变量

---

## 🚀 �?6 �? 部署代码

### 使用 VSCode 部署

1. 打开 Azure 视图
2. 找到 "mediagenie-backend"
3. 右键 �?"Deploy to Web App"
4. 选择 `backend` 文件�?5. 点击 "Deploy"

对前端重复相同步骤�?
---

## 🧪 验证部署

1. 访问: https://mediagenie-backend.azurewebsites.net/health
2. 应该返回 200 OK

---

## 💾 重要信息

### 数据库连接字符串格式

```
postgresql+asyncpg://dbadmin:PASSWORD@SERVER.postgres.database.azure.com:5432/mediagenie
```

### 后端 URL

```
https://mediagenie-backend.azurewebsites.net
```

### 前端 URL

```
https://mediagenie-frontend.azurewebsites.net
```

---

## �?总结

**最简单的方式**:
1. 打开 Azure Portal
2. 创建 Web Apps 和数据库
3. 配置应用设置
4. �?VSCode 中部署代�?
**预计时间**: 30-45 分钟

---

**下一�?*: 打开 Azure Portal 开始创建资�?
🚀 **祝你部署顺利�?*

