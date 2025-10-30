# MediaGenie - Azure Marketplace 部署版本

## 📋 项目简�?

MediaGenie 是一个基�?Azure AI 服务的智能媒体处理平台，提供�?

- 🎤 **语音转文�?* - 高精度语音识�?
- 🔊 **文字转语�?* - 自然语音合成
- 🖼�?**图像分析** - AI 驱动的图像理�?
- 💬 **GPT 聊天** - 智能对话助手

## 🏗�?架构

```
MediaGenie
├── Marketplace Portal (Flask)    �?Landing Page URL
├── Backend API (FastAPI)         �?Webhook URL
└── Frontend (React)              �?Web 应用
```

## 🚀 快速部�?

### 方式 1：一键部署（推荐�?

```powershell
# 执行一键部署脚�?
.\deploy-all.ps1 -ResourceGroupName "MediaGenie-RG" -Location "eastus"
```

这将自动完成�?
1. �?创建资源�?
2. �?部署 ARM 模板
3. �?部署 Marketplace Portal
4. �?部署 Backend API
5. �?部署 Frontend
6. �?配置静态网�?
7. �?输出 Marketplace 所需的两�?URL

### 方式 2：分步部�?

详见 [arm-templates/DEPLOYMENT_GUIDE.md](arm-templates/DEPLOYMENT_GUIDE.md)

## 📦 部署输出

部署完成后，您将获得�?

### Azure Marketplace 提交所需的两�?URL�?

1. **Landing Page URL**: `https://<marketplace-app>.azurewebsites.net`
   - 产品展示页面
   - 用于 Partner Center �?"Landing page URL"

2. **Webhook URL**: `https://<backend-app>.azurewebsites.net/api/marketplace/webhook`
   - Azure Marketplace 集成接口
   - 用于 Partner Center �?"Connection webhook"

3. **Frontend URL**: `https://<storage-account>.z1.web.core.windows.net`
   - React Web 应用界面

## 🔧 前提条件

- Azure 订阅
- Azure CLI
- PowerShell 5.1+（Windows）或 Bash（Linux/macOS�?
- Node.js 16+（用于构建前端）

## ⚙️ 配置 Azure AI 服务

部署后，可通过以下命令配置 Azure AI 服务�?

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

## 📊 成本估算

基于 B1 App Service Plan�?

- App Service Plan (B1): ~$13 USD/�?
- Storage Account: ~$0.02 USD/GB
- **总计**: ~$13-15 USD/�?

*不包�?Azure AI 服务费用（按使用量计费）*

## 📝 提交�?Azure Marketplace

1. 登录 [Partner Center](https://partner.microsoft.com/dashboard/marketplace-offers/overview)
2. 找到您的产品
3. 导航�?"Technical configuration"
4. 输入�?
   - Landing page URL: `<部署输出�?Landing Page URL>`
   - Connection webhook: `<部署输出�?Webhook URL>`
5. 保存并提交审�?

## 🗂�?项目结构

```
MediaGenie1001/
├── arm-templates/              # ARM 模板和部署脚�?
�?  ├── azuredeploy.json       # ARM 模板
�?  ├── azuredeploy.parameters.json
�?  ├── createUiDefinition.json
�?  ├── deploy.ps1
�?  ├── deploy.sh
�?  └── DEPLOYMENT_GUIDE.md    # 详细部署指南
├── marketplace-portal/         # Flask Landing Page
�?  ├── app.py
�?  ├── templates/
�?  └── requirements.txt
├── backend/
�?  └── media-service/         # FastAPI Backend
�?      ├── main.py
�?      └── requirements.txt
├── frontend/                   # React Frontend
�?  ├── src/
�?  ├── public/
�?  └── package.json
├── deploy-all.ps1             # 一键部署脚�?
└── README.md                  # 本文�?
```

## 🔍 验证部署

### 验证 Landing Page
```bash
curl https://<marketplace-app>.azurewebsites.net/health
```

### 验证 Backend API
```bash
curl https://<backend-app>.azurewebsites.net/health
```

### 验证 Webhook
```bash
curl -X POST https://<backend-app>.azurewebsites.net/api/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"action":"subscribe","id":"test-123"}'
```

## 🛠�?故障排查

### 问题：App Service 无法启动

**解决方案**�?
```bash
# 查看日志
az webapp log tail --resource-group MediaGenie-RG --name <app-name>
```

### 问题：Frontend 404 错误

**解决方案**�?
```bash
# 配置静态网站路�?
az storage blob service-properties update \
  --account-name <storage-account> \
  --static-website \
  --404-document index.html \
  --index-document index.html
```

### 问题：CORS 错误

**解决方案**�?
```bash
# 添加 CORS 允许的源
az webapp cors add \
  --resource-group MediaGenie-RG \
  --name <backend-app> \
  --allowed-origins "https://<frontend-url>"
```

## 📚 文档

- [完整部署指南](arm-templates/DEPLOYMENT_GUIDE.md)
- [ARM 模板说明](arm-templates/azuredeploy.json)
- [API 文档](https://<backend-app>.azurewebsites.net/docs)

## 📧 支持

- 技术支持：support@smartwebco.com
- 公司网站：https://smartwebco.com

## 📄 许可�?

版权所�?© 2024 智网同盛。保留所有权利�?

---

**祝部署顺利！** 🎉
