# MediaGenie Azure Web App 快速开始 🚀

## ⚡ 5分钟快速部署

### 前提条件
- ✅ Azure账号
- ✅ Azure CLI已安装
- ✅ 前端已构建(存在 `frontend/build` 目录)

### 一键部署命令

```powershell
# 1. 登录Azure
az login

# 2. 准备环境变量配置
Copy-Item env-settings-template.json env-settings.json
# 编辑 env-settings.json,填入你的Azure服务密钥

# 3. 一键部署(使用现有Web App)
.\deploy_to_azure_webapp.ps1 `
    -ResourceGroup "MediaGenie-RG" `
    -WebAppName "mediagenie-app" `
    -EnvSettingsFile "env-settings.json"

# 或者创建新资源并部署
.\deploy_to_azure_webapp.ps1 `
    -ResourceGroup "MediaGenie-RG" `
    -WebAppName "mediagenie-app" `
    -CreateResources `
    -EnvSettingsFile "env-settings.json"
```

### 部署后访问

```
应用URL: https://your-webapp-name.azurewebsites.net
健康检查: https://your-webapp-name.azurewebsites.net/health
```

---

## 📁 项目结构

```
MediaGenie1001/
├── backend/media-service/       # FastAPI后端
│   ├── main.py                 # 主应用
│   ├── requirements.txt        # Python依赖
│   └── ...
├── frontend/                   # React前端
│   ├── build/                  # 构建输出
│   ├── server.js              # Express服务器
│   └── package.json
├── marketplace-portal/         # Marketplace门户
├── create_azure_deployment_package.ps1  # 创建部署包
├── deploy_to_azure_webapp.ps1          # 一键部署
├── env-settings-template.json          # 环境变量模板
└── AZURE_WEBAPP_DEPLOYMENT_GUIDE.md   # 详细部署文档
```

---

## 🎯 部署方案选择

### 方案1: 一键自动部署 ⭐ 推荐

**优点**: 全自动,无需手动操作  
**适用**: 有完整Azure权限的场景

```powershell
.\deploy_to_azure_webapp.ps1 -ResourceGroup "RG" -WebAppName "app"
```

### 方案2: 手动ZIP部署

**优点**: 灵活,可检查部署包内容  
**适用**: 需要自定义配置的场景

```powershell
# 创建部署包
.\create_azure_deployment_package.ps1

# 压缩
cd azure-webapp-deploy
Compress-Archive -Path * -DestinationPath ..\app.zip

# 部署
az webapp deploy --resource-group RG --name app --src-path app.zip --type zip
```

### 方案3: GitHub Actions

**优点**: CI/CD自动化  
**适用**: 团队协作,持续部署

参考 `.github/workflows/azure-deploy.yml`

---

## 🔧 必需的Azure服务

### 1. Web App (Python 3.11 Linux)

```bash
# 创建App Service Plan
az appservice plan create \
    --name mediagenie-plan \
    --resource-group MediaGenie-RG \
    --is-linux \
    --sku B1

# 创建Web App
az webapp create \
    --name mediagenie-app \
    --resource-group MediaGenie-RG \
    --plan mediagenie-plan \
    --runtime "PYTHON:3.11"
```

### 2. Azure认知服务

#### Speech Service
```bash
az cognitiveservices account create \
    --name mediagenie-speech \
    --resource-group MediaGenie-RG \
    --kind SpeechServices \
    --sku F0 \
    --location eastus
```

#### Computer Vision
```bash
az cognitiveservices account create \
    --name mediagenie-vision \
    --resource-group MediaGenie-RG \
    --kind ComputerVision \
    --sku F0 \
    --location eastus
```

#### Azure OpenAI
```bash
# 需要申请访问权限
# Portal: https://aka.ms/oai/access
```

### 3. PostgreSQL数据库(可选)

```bash
az postgres flexible-server create \
    --name mediagenie-db \
    --resource-group MediaGenie-RG \
    --location eastus \
    --admin-user admin \
    --admin-password YourPassword123! \
    --sku-name Standard_B1ms
```

---

## 📝 环境变量快速配置

### 最小配置(必需)

```json
{
  "AZURE_SPEECH_KEY": "你的密钥",
  "AZURE_SPEECH_REGION": "eastus",
  "AZURE_VISION_KEY": "你的密钥",
  "AZURE_VISION_ENDPOINT": "https://xxx.cognitiveservices.azure.com/",
  "AZURE_OPENAI_KEY": "你的密钥",
  "AZURE_OPENAI_ENDPOINT": "https://xxx.openai.azure.com/",
  "AZURE_OPENAI_DEPLOYMENT": "gpt-4.1"
}
```

### 获取密钥位置

| 服务 | Portal路径 |
|------|-----------|
| Speech | 认知服务 → Speech Services → 密钥和终结点 |
| Vision | 认知服务 → Computer Vision → 密钥和终结点 |
| OpenAI | Azure OpenAI → 密钥和终结点 |

---

## 🔍 验证部署

### 1. 查看日志

```bash
az webapp log tail --resource-group MediaGenie-RG --name mediagenie-app
```

### 2. 测试健康检查

```bash
curl https://mediagenie-app.azurewebsites.net/health
```

预期响应:
```json
{
  "status": "healthy",
  "service": "mediagenie-backend",
  "timestamp": "2025-10-30T12:00:00Z"
}
```

### 3. 浏览器访问

```
https://mediagenie-app.azurewebsites.net
```

---

## 🛠️ 常见问题

### Q1: 前端未构建怎么办?

```bash
cd frontend
npm install
npm run build
```

### Q2: 部署失败?

```bash
# 查看详细日志
az webapp log tail --name app --resource-group RG

# 检查配置
az webapp show --name app --resource-group RG
```

### Q3: 环境变量未生效?

```bash
# 重新设置
az webapp config appsettings set --name app --resource-group RG --settings @env-settings.json

# 重启应用
az webapp restart --name app --resource-group RG
```

### Q4: 应用启动慢?

首次部署需要5-10分钟:
- 安装Python依赖
- 安装Node.js依赖  
- 初始化服务

后续启动会更快。

---

## 📚 更多资源

- 📖 [完整部署指南](AZURE_WEBAPP_DEPLOYMENT_GUIDE.md)
- 🔧 [故障排除文档](AZURE_WEBAPP_DEPLOYMENT_GUIDE.md#故障排除)
- 💬 技术支持: support@smartwebco.com

---

## 🎉 部署成功检查清单

- [ ] Azure CLI已安装并登录
- [ ] 前端已构建(`frontend/build`存在)
- [ ] 环境变量已配置(`env-settings.json`)
- [ ] 运行一键部署脚本
- [ ] 等待部署完成(5-10分钟)
- [ ] 访问健康检查端点
- [ ] 浏览器测试应用功能

---

**祝部署顺利! 🚀**

如遇问题,请查看[完整部署指南](AZURE_WEBAPP_DEPLOYMENT_GUIDE.md)或联系技术支持。
