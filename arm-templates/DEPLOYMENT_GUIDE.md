# MediaGenie Azure Marketplace 部署指南

## 概述

本指南将帮助您使�?ARM 模板�?MediaGenie 部署�?Azure，并准备 Azure Marketplace 提交所需的两个关�?URL�?

1. **Landing Page URL** - 产品展示页面
2. **Webhook URL** - Azure Marketplace 集成接口

## 架构说明

部署将创建以�?Azure 资源�?

```
MediaGenie 部署架构
├── App Service Plan (Linux, Python 3.11)
�?  ├── Marketplace Portal (Flask)
�?  �?  ├── Landing Page (/)
�?  �?  └── Webhook (/api/marketplace/webhook)
�?  └── Backend API (FastAPI)
�?      ├── Media Processing APIs
�?      └── Marketplace Webhook (/api/marketplace/webhook)
└── Storage Account
    └── Static Website ($web 容器)
        └── Frontend (React SPA)
```

### 关键 URL 映射

- **Landing Page URL**: `https://<marketplace-app-name>.azurewebsites.net`
- **Webhook URL**: `https://<backend-app-name>.azurewebsites.net/api/marketplace/webhook`
- **Frontend URL**: `https://<storage-account-name>.z1.web.core.windows.net`

## 前提条件

1. **Azure 订阅** - 需要有效的 Azure 订阅
2. **Azure CLI** - 已安装并配置
3. **Node.js** - 用于构建前端（v16 或更高版本）
4. **Python** - 用于本地测试（v3.11�?
5. **Git** - 用于克隆代码

## 第一步：准备环境

### 1.1 登录 Azure

```bash
az login
```

### 1.2 设置默认订阅（可选）

```bash
# 查看所有订�?
az account list --output table

# 设置默认订阅
az account set --subscription "<订阅 ID>"
```

### 1.3 验证登录状�?

```bash
az account show
```

## 第二步：配置部署参数

编辑 `arm-templates/azuredeploy.parameters.json`，配置以下参数：

```json
{
  "parameters": {
    "appNamePrefix": {
      "value": "mediagenie"
    },
    "appServicePlanSku": {
      "value": "B1"
    },
    "azureOpenAIEndpoint": {
      "value": "https://your-openai.openai.azure.com/"
    },
    "azureOpenAIKey": {
      "value": "your-openai-key"
    },
    "azureSpeechKey": {
      "value": "your-speech-key"
    },
    "azureSpeechRegion": {
      "value": "eastus"
    },
    "azureComputerVisionEndpoint": {
      "value": "https://your-vision.cognitiveservices.azure.com/"
    },
    "azureComputerVisionKey": {
      "value": "YOUR_AZURE_VISION_KEY_HERE"
    }
  }
}
```

**注意**：Azure AI 服务配置为可选项，可在部署后通过 Azure Portal 配置�?

## 第三步：执行部署

### 方式 1：使�?PowerShell 脚本（推荐）

```powershell
cd F:\project\MediaGenie1001

# 执行部署
.\arm-templates\deploy.ps1 -ResourceGroupName "MediaGenie-RG" -Location "eastus"
```

### 方式 2：使�?Bash 脚本

```bash
cd /mnt/f/project/MediaGenie1001

# 添加执行权限
chmod +x arm-templates/deploy.sh

# 执行部署
./arm-templates/deploy.sh MediaGenie-RG eastus
```

### 方式 3：手动部�?

```bash
# 创建资源�?
az group create --name MediaGenie-RG --location eastus

# 部署 ARM 模板
az deployment group create \
  --resource-group MediaGenie-RG \
  --template-file arm-templates/azuredeploy.json \
  --parameters arm-templates/azuredeploy.parameters.json \
  --name mediagenie-deployment
```

## 第四步：部署应用代码

### 4.1 部署 Marketplace Portal

```bash
# 进入 marketplace-portal 目录
cd marketplace-portal

# 创建部署�?
zip -r ../marketplace-portal.zip .

# 部署�?App Service
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name <marketplace-app-name> \
  --src ../marketplace-portal.zip
```

**PowerShell 版本�?*

```powershell
cd marketplace-portal
Compress-Archive -Path * -DestinationPath ../marketplace-portal.zip -Force
az webapp deployment source config-zip `
  --resource-group MediaGenie-RG `
  --name <marketplace-app-name> `
  --src ../marketplace-portal.zip
```

### 4.2 部署 Backend API

```bash
# 进入 backend/media-service 目录
cd backend/media-service

# 创建部署�?
zip -r ../../backend-api.zip .

# 部署�?App Service
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name <backend-app-name> \
  --src ../../backend-api.zip
```

**PowerShell 版本�?*

```powershell
cd backend\media-service
Compress-Archive -Path * -DestinationPath ..\..\backend-api.zip -Force
az webapp deployment source config-zip `
  --resource-group MediaGenie-RG `
  --name <backend-app-name> `
  --src ..\..\backend-api.zip
```

### 4.3 部署 Frontend

```bash
# 进入 frontend 目录
cd frontend

# 安装依赖
npm install

# 设置环境变量并构�?
export REACT_APP_MEDIA_SERVICE_URL="https://<backend-app-name>.azurewebsites.net"
npm run build

# 上传�?Storage Account
az storage blob upload-batch \
  --account-name <storage-account-name> \
  --destination '$web' \
  --source build/ \
  --overwrite

# 配置静态网�?
az storage blob service-properties update \
  --account-name <storage-account-name> \
  --static-website \
  --404-document index.html \
  --index-document index.html
```

**PowerShell 版本�?*

```powershell
cd frontend

npm install

$env:REACT_APP_MEDIA_SERVICE_URL="https://<backend-app-name>.azurewebsites.net"
npm run build

az storage blob upload-batch `
  --account-name <storage-account-name> `
  --destination '$web' `
  --source build/ `
  --overwrite

az storage blob service-properties update `
  --account-name <storage-account-name> `
  --static-website `
  --404-document index.html `
  --index-document index.html
```

## 第五步：验证部署

### 5.1 验证 Marketplace Portal

访问 Landing Page URL�?
```
https://<marketplace-app-name>.azurewebsites.net
```

应该看到 MediaGenie 产品展示页面�?

### 5.2 验证 Backend API

访问 API 文档�?
```
https://<backend-app-name>.azurewebsites.net/docs
```

应该看到 FastAPI Swagger UI�?

### 5.3 验证 Webhook

测试 Webhook 接口�?
```bash
curl -X POST https://<backend-app-name>.azurewebsites.net/api/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"action":"subscribe","id":"test-123"}'
```

应该返回成功响应�?

### 5.4 验证 Frontend

访问 Frontend URL�?
```
https://<storage-account-name>.z1.web.core.windows.net
```

应该看到 React 应用界面�?

## 第六步：配置 Azure AI 服务（可选）

如果在部署时未配�?Azure AI 服务，可以通过以下步骤配置�?

### 6.1 通过 Azure Portal 配置

1. 登录 Azure Portal
2. 导航�?Backend App Service
3. 选择"配置" �?"应用程序设置"
4. 添加以下环境变量�?
   - `AZURE_OPENAI_ENDPOINT`
   - `AZURE_OPENAI_KEY`
   - `AZURE_SPEECH_KEY`
   - `AZURE_SPEECH_REGION`
   - `AZURE_COMPUTER_VISION_ENDPOINT`
   - `AZURE_COMPUTER_VISION_KEY`
5. 点击"保存"并重启应�?

### 6.2 通过 Azure CLI 配置

```bash
az webapp config appsettings set \
  --resource-group MediaGenie-RG \
  --name <backend-app-name> \
  --settings \
    AZURE_OPENAI_ENDPOINT="https://your-openai.openai.azure.com/" \
    AZURE_OPENAI_KEY="your-key" \
    AZURE_SPEECH_KEY="your-key" \
    AZURE_SPEECH_REGION="eastus" \
    AZURE_COMPUTER_VISION_ENDPOINT="https://your-vision.cognitiveservices.azure.com/" \
    AZURE_COMPUTER_VISION_KEY="your-key"
```

## 第七步：提交�?Azure Marketplace

### 7.1 准备提交信息

从部署输出中获取以下 URL�?

1. **Landing Page URL**: `https://<marketplace-app-name>.azurewebsites.net`
2. **Connection Webhook**: `https://<backend-app-name>.azurewebsites.net/api/marketplace/webhook`

### 7.2 �?Partner Center 中配�?

1. 登录 [Partner Center](https://partner.microsoft.com/dashboard/marketplace-offers/overview)
2. 找到您的 MediaGenie 产品
3. 导航�?Technical configuration"
4. 输入以下信息�?
   - **Landing page URL**: 上面获取�?Landing Page URL
   - **Connection webhook**: 上面获取�?Webhook URL
5. 保存并提交审�?

## 故障排查

### 问题 1：部署失�?- 配额不足

**解决方案**�?
```bash
# 检查配�?
az vm list-usage --location eastus --output table

# 更换区域或升级订�?
```

### 问题 2：App Service 无法启动

**解决方案**�?
1. 检查应用日志：
   ```bash
   az webapp log tail --resource-group MediaGenie-RG --name <app-name>
   ```
2. 验证 Python 版本和依�?

### 问题 3：Frontend 路由 404 错误

**解决方案**�?
确保已配置静态网站的错误文档�?
```bash
az storage blob service-properties update \
  --account-name <storage-account-name> \
  --static-website \
  --404-document index.html \
  --index-document index.html
```

### 问题 4：CORS 错误

**解决方案**�?
检�?Backend App Service �?CORS 设置�?
```bash
az webapp cors add \
  --resource-group MediaGenie-RG \
  --name <backend-app-name> \
  --allowed-origins "https://<frontend-url>"
```

## 成本估算

基于 B1 App Service Plan�?

| 资源 | SKU | 月费用（估算�?|
|------|-----|---------------|
| App Service Plan | B1 | ~$13 USD |
| App Service (Marketplace) | - | 包含�?Plan �?|
| App Service (Backend) | - | 包含�?Plan �?|
| Storage Account | Standard LRS | ~$0.02 USD/GB |
| **总计** | | **~$13-15 USD/�?* |

**注意**：不包括 Azure AI 服务费用（按使用量计费）�?

## 下一�?

1. �?完成部署和验�?
2. �?提交 URL �?Azure Marketplace Partner Center
3. �?等待 Microsoft 审核（通常 3-5 个工作日�?
4. �?审核通过后，产品将在 Azure Marketplace 上线

## 支持

如有问题，请联系�?
- 技术支持：support@smartwebco.com
- 文档：查看本指南
- GitHub：提�?Issue

---

**祝部署顺利！** 🚀
