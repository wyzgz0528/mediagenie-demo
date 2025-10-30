# MediaGenie Azure Web App 部署指南

## 📋 目录

1. [准备工作](#准备工作)
2. [方法一:一键自动部署(推荐)](#方法一一键自动部署推荐)
3. [方法二:手动ZIP部署](#方法二手动zip部署)
4. [环境变量配置](#环境变量配置)
5. [验证部署](#验证部署)
6. [故障排除](#故障排除)

---

## 准备工作

### 1. 安装Azure CLI

**Windows:**
```powershell
# 使用MSI安装包
# 下载: https://aka.ms/installazurecliwindows
```

**Mac/Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. 登录Azure
```bash
az login
```

### 3. 检查前端构建

确保前端已构建:
```bash
cd frontend
npm install
npm run build
```

构建完成后会生成 `frontend/build` 目录。

---

## 方法一:一键自动部署(推荐)

### 步骤1: 准备环境变量配置

复制环境变量模板并填入实际值:

```powershell
# 复制模板
Copy-Item env-settings-template.json env-settings.json

# 编辑 env-settings.json,填入你的Azure服务密钥
```

**必须配置的环境变量:**
- `AZURE_SPEECH_KEY`: 语音服务密钥
- `AZURE_SPEECH_REGION`: 语音服务区域
- `AZURE_VISION_KEY`: 视觉服务密钥
- `AZURE_VISION_ENDPOINT`: 视觉服务端点
- `AZURE_OPENAI_KEY`: OpenAI服务密钥
- `AZURE_OPENAI_ENDPOINT`: OpenAI服务端点
- `DATABASE_URL`: PostgreSQL数据库连接字符串

### 步骤2: 运行一键部署脚本

**场景A: 使用现有的Web App部署**

```powershell
.\deploy_to_azure_webapp.ps1 `
    -ResourceGroup "MediaGenie-RG" `
    -WebAppName "mediagenie-app" `
    -EnvSettingsFile "env-settings.json"
```

**场景B: 创建新的Web App并部署**

```powershell
.\deploy_to_azure_webapp.ps1 `
    -ResourceGroup "MediaGenie-RG" `
    -WebAppName "mediagenie-app" `
    -Location "East US" `
    -Sku "B1" `
    -CreateResources `
    -EnvSettingsFile "env-settings.json"
```

**参数说明:**
- `-ResourceGroup`: Azure资源组名称
- `-WebAppName`: Web App名称(全局唯一)
- `-Location`: Azure区域(默认: East US)
- `-Sku`: 定价层(B1, B2, S1, P1V2等)
- `-CreateResources`: 创建新资源(资源组、App Service Plan、Web App)
- `-BuildFrontend`: 部署前重新构建前端
- `-EnvSettingsFile`: 环境变量JSON文件路径

### 步骤3: 等待部署完成

脚本会自动完成以下步骤:
1. ✅ 检查Azure CLI和登录状态
2. ✅ (可选)创建Azure资源
3. ✅ 创建部署包
4. ✅ 压缩为ZIP文件
5. ✅ 上传并部署到Azure
6. ✅ 配置环境变量和启动命令

部署完成后会显示:
```
╔════════════════════════════════════════════════════════════════╗
║                    🎉 部署完成!                                ║
╚════════════════════════════════════════════════════════════════╝

应用URL: https://mediagenie-app.azurewebsites.net
健康检查: https://mediagenie-app.azurewebsites.net/health
```

---

## 方法二:手动ZIP部署

### 步骤1: 创建部署包

```powershell
# 创建部署目录和文件
.\create_azure_deployment_package.ps1 -OutputDir "azure-webapp-deploy"
```

这会创建包含以下内容的部署目录:
```
azure-webapp-deploy/
├── backend/              # 后端FastAPI代码
├── frontend/             # 前端构建文件和server.js
├── marketplace-portal/   # Marketplace门户
├── requirements.txt      # Python依赖
├── startup.sh           # 启动脚本
├── supervisord.conf     # 进程管理配置
├── .deployment          # Azure部署配置
└── DEPLOYMENT_GUIDE.md  # 详细部署文档
```

### 步骤2: 创建ZIP包

```powershell
# 进入部署目录
cd azure-webapp-deploy

# 创建ZIP包
Compress-Archive -Path * -DestinationPath ..\mediagenie-webapp.zip -Force
cd ..
```

### 步骤3: 部署到Azure

```bash
# 使用Azure CLI部署
az webapp deploy \
    --resource-group MediaGenie-RG \
    --name mediagenie-app \
    --src-path mediagenie-webapp.zip \
    --type zip
```

### 步骤4: 配置环境变量

**方法A: 使用Azure CLI**

```bash
# 从JSON文件批量导入
az webapp config appsettings set \
    --resource-group MediaGenie-RG \
    --name mediagenie-app \
    --settings @env-settings.json
```

**方法B: 使用Azure Portal**

1. 登录 [Azure Portal](https://portal.azure.com)
2. 找到你的Web App
3. 左侧菜单选择"配置" → "应用程序设置"
4. 点击"新建应用程序设置"添加环境变量
5. 点击"保存"

### 步骤5: 配置启动命令

**方法A: 使用Azure CLI**

```bash
az webapp config set \
    --resource-group MediaGenie-RG \
    --name mediagenie-app \
    --startup-file "bash startup.sh"
```

**方法B: 使用Azure Portal**

1. Web App → 配置 → 常规设置
2. 启动命令: `bash startup.sh`
3. 保存

---

## 环境变量配置

### 完整环境变量清单

创建 `env-settings.json` 文件:

```json
[
  {
    "name": "AZURE_SPEECH_KEY",
    "value": "你的语音服务密钥"
  },
  {
    "name": "AZURE_SPEECH_REGION",
    "value": "eastus"
  },
  {
    "name": "AZURE_VISION_KEY",
    "value": "你的视觉服务密钥"
  },
  {
    "name": "AZURE_VISION_ENDPOINT",
    "value": "https://你的资源名.cognitiveservices.azure.com/"
  },
  {
    "name": "AZURE_OPENAI_KEY",
    "value": "你的OpenAI密钥"
  },
  {
    "name": "AZURE_OPENAI_ENDPOINT",
    "value": "https://你的资源名.openai.azure.com/"
  },
  {
    "name": "AZURE_OPENAI_DEPLOYMENT",
    "value": "gpt-4.1"
  },
  {
    "name": "AZURE_OPENAI_API_VERSION",
    "value": "2025-01-01-preview"
  },
  {
    "name": "DATABASE_URL",
    "value": "postgresql+asyncpg://user:pass@host:5432/dbname"
  },
  {
    "name": "DEBUG",
    "value": "false"
  },
  {
    "name": "PORT",
    "value": "8000"
  }
]
```

### 获取Azure服务密钥

#### 1. Speech Service
```bash
# Azure Portal
认知服务 → Speech Services → 密钥和终结点
```

#### 2. Computer Vision
```bash
# Azure Portal  
认知服务 → Computer Vision → 密钥和终结点
```

#### 3. Azure OpenAI
```bash
# Azure Portal
Azure OpenAI → 密钥和终结点
```

#### 4. PostgreSQL数据库

如需创建数据库:
```bash
# 创建PostgreSQL服务器
az postgres flexible-server create \
    --resource-group MediaGenie-RG \
    --name mediagenie-db \
    --location eastus \
    --admin-user myadmin \
    --admin-password MySecurePassword123! \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 14

# 创建数据库
az postgres flexible-server db create \
    --resource-group MediaGenie-RG \
    --server-name mediagenie-db \
    --database-name mediagenie

# 获取连接字符串
DATABASE_URL="postgresql+asyncpg://myadmin:MySecurePassword123!@mediagenie-db.postgres.database.azure.com:5432/mediagenie"
```

---

## 验证部署

### 1. 查看实时日志

```bash
az webapp log tail \
    --resource-group MediaGenie-RG \
    --name mediagenie-app
```

### 2. 测试健康检查

```bash
# 后端健康检查
curl https://mediagenie-app.azurewebsites.net/health

# 预期响应
{
  "status": "healthy",
  "service": "mediagenie-backend",
  "timestamp": "2025-10-30T12:00:00Z"
}
```

### 3. 访问应用

在浏览器打开:
```
https://mediagenie-app.azurewebsites.net
```

### 4. 检查日志文件

通过Azure Portal:
1. Web App → 高级工具(Kudu) → 转到
2. 访问: `https://mediagenie-app.scm.azurewebsites.net`
3. Debug Console → PowerShell
4. 查看日志: `cd LogFiles` 或 `cd site/wwwroot/logs`

---

## 故障排除

### 问题1: 应用无法启动

**症状:** 访问URL显示"Application Error"

**排查步骤:**

1. **查看启动日志**
```bash
az webapp log tail --resource-group MediaGenie-RG --name mediagenie-app
```

2. **检查Python版本**
- 确保Web App使用Python 3.11
- 在Azure Portal检查: 配置 → 常规设置 → 堆栈设置

3. **验证启动命令**
```bash
# 检查启动命令是否正确
az webapp config show --resource-group MediaGenie-RG --name mediagenie-app --query linuxFxVersion
```

应该显示: `PYTHON|3.11`

### 问题2: 环境变量未生效

**症状:** 日志显示"Missing environment variable"

**解决方法:**

1. **检查环境变量是否已配置**
```bash
az webapp config appsettings list \
    --resource-group MediaGenie-RG \
    --name mediagenie-app
```

2. **重新配置环境变量**
```bash
az webapp config appsettings set \
    --resource-group MediaGenie-RG \
    --name mediagenie-app \
    --settings @env-settings.json
```

3. **重启应用**
```bash
az webapp restart \
    --resource-group MediaGenie-RG \
    --name mediagenie-app
```

### 问题3: 前端无法访问后端API

**症状:** 前端页面加载但API调用失败

**排查步骤:**

1. **检查CORS配置**
- 后端需要允许前端域名的跨域请求
- 检查 `backend/media-service/main.py` 中的CORS设置

2. **验证API端点**
```bash
# 测试后端API
curl https://mediagenie-app.azurewebsites.net/health
```

3. **检查前端API配置**
- 确认前端代码中API的baseURL设置正确

### 问题4: 部署后首次启动慢

**症状:** 部署完成后5-10分钟应用才能访问

**原因:** 
- Azure需要时间安装Python依赖
- 首次启动需要初始化所有服务

**解决方法:**
- 耐心等待首次启动完成
- 查看日志监控安装进度
- 后续重启会快很多

### 问题5: 文件权限错误

**症状:** 日志显示"Permission denied"

**解决方法:**

在 `startup.sh` 中添加权限设置:
```bash
chmod +x /home/site/wwwroot/startup.sh
chmod -R 755 /home/site/wwwroot/logs
```

### 获取详细诊断信息

```bash
# 下载所有日志文件
az webapp log download \
    --resource-group MediaGenie-RG \
    --name mediagenie-app \
    --log-file app-logs.zip

# 解压查看
unzip app-logs.zip
```

---

## 常用命令速查

```bash
# 查看应用状态
az webapp show --resource-group MediaGenie-RG --name mediagenie-app

# 重启应用
az webapp restart --resource-group MediaGenie-RG --name mediagenie-app

# 停止应用
az webapp stop --resource-group MediaGenie-RG --name mediagenie-app

# 启动应用
az webapp start --resource-group MediaGenie-RG --name mediagenie-app

# 查看配置
az webapp config show --resource-group MediaGenie-RG --name mediagenie-app

# 查看环境变量
az webapp config appsettings list --resource-group MediaGenie-RG --name mediagenie-app

# SSH到容器
az webapp ssh --resource-group MediaGenie-RG --name mediagenie-app
```

---

## 性能优化建议

### 1. 选择合适的定价层

| 定价层 | CPU | 内存 | 适用场景 |
|--------|-----|------|---------|
| B1     | 1核 | 1.75GB | 开发测试 |
| B2     | 2核 | 3.5GB  | 小型生产 |
| S1     | 1核 | 1.75GB | 生产环境(支持自动扩展) |
| P1V2   | 1核 | 3.5GB  | 高性能生产 |

### 2. 启用应用洞察

```bash
az monitor app-insights component create \
    --app mediagenie-insights \
    --resource-group MediaGenie-RG \
    --location eastus
```

### 3. 配置自动扩展

在Azure Portal中:
- Web App → 横向扩展(Scale out)
- 配置基于CPU/内存的自动扩展规则

---

## 技术支持

如有问题,请联系:
- **邮箱**: support@smartwebco.com
- **文档**: https://smartwebco.com/docs
- **GitHub**: https://github.com/wyzgz0528/mediagenie-demo

---

**更新时间**: 2025-10-30  
**版本**: 1.0.0
