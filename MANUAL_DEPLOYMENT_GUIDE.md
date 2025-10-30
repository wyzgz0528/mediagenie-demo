# MediaGenie Azure Marketplace 手动部署完整指南

> **解决 Cloud Shell 超时问题的可靠部署方�?*

## 📋 部署概述

本指南提�?*完全手动**的部署流�?绕过 Cloud Shell 的超时限�?适用�?
- Cloud Shell 部署脚本超时
- 网络环境受限
- 需要精确控制部署过�?

---

## 🎯 部署架构

```
MediaGenie Marketplace 部署
├── 基础设施�?(ARM 模板)
�?  ├── App Service Plan (Linux, Python 3.11)
�?  ├── Marketplace Portal App (Flask)
�?  ├── Backend API App (FastAPI)
�?  └── Storage Account (静态网站托�?
�?
├── 应用�?(Zip Deploy)
�?  ├── marketplace-portal.zip (预打包依�?
�?  ├── backend-api.zip (预打包依�?
�?  └── frontend-build.zip (生产构建)
�?
└── 配置�?
    ├── App Settings (Azure AI Keys)
    ├── CORS 配置
    └── Startup Commands
```

---

## �?前提条件

### 1. 本地环境
- **PowerShell** 5.1+ �?**Bash**
- **Azure CLI** 2.50+ ([安装](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli))
- **Node.js** 16+ (用于前端构建)
- **Python** 3.9+ (用于依赖打包)

### 2. Azure 订阅
- 已登�? `az login`
- 有权限创建资源组�?App Service

### 3. Azure AI 服务密钥
准备以下服务�?API Key:
- **Azure OpenAI** (Endpoint + Key + Deployment Name)
- **Azure Speech** (Key + Region)
- **Azure Computer Vision** (可�? Endpoint + Key)

---

## 📦 第一�? 创建部署�?

运行以下 PowerShell 脚本自动生成所有部署包:

```powershell
.\build-deployment-packages.ps1
```

**脚本会生�?**
1. `deploy/marketplace-portal.zip` - Marketplace Portal (�?python_packages)
2. `deploy/backend-api.zip` - Backend API (�?python_packages)
3. `deploy/frontend-build.zip` - 前端生产构建
4. `deploy/azuredeploy-optimized.json` - 优化�?ARM 模板

**预计时间**: 5-10 分钟

---

## 🚀 第二�? 部署基础设施

### 2.1 登录 Azure
```bash
az login
az account set --subscription "你的订阅名称或ID"
```

### 2.2 创建资源�?
```bash
RESOURCE_GROUP="MediaGenie-Marketplace-RG"
LOCATION="eastus"

az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### 2.3 部署 ARM 模板
```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file deploy/azuredeploy-optimized.json \
  --parameters \
    appNamePrefix=mediagenie \
    location=$LOCATION \
    appServicePlanSku=B1 \
    azureOpenAIEndpoint="https://your-openai.openai.azure.com" \
    azureOpenAIKey="your-key" \
    azureOpenAIDeployment="gpt-4" \
    azureSpeechKey="your-speech-key" \
    azureSpeechRegion="eastus" \
    azureComputerVisionEndpoint="YOUR_AZURE_VISION_ENDPOINT_HERE" \
    azureComputerVisionKey="YOUR_AZURE_VISION_KEY_HERE"
```

**等待�?3-5 分钟**,直到输出:
```
�?部署完成
Marketplace Portal App: mediagenie-marketplace-abc123
Backend API App: mediagenie-backend-abc123
Storage Account: mediageniesaabc123
```

---

## 📤 第三�? 上传应用代码

### 3.1 部署 Marketplace Portal

**方式 A: 使用 Azure CLI**
```bash
PORTAL_APP="mediagenie-marketplace-abc123"  # 从上一步输出获�?

az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $PORTAL_APP \
  --src-path deploy/marketplace-portal.zip \
  --type zip \
  --restart true
```

**方式 B: 使用 Kudu (网络受限�?**
1. 打开浏览器访�? `https://$PORTAL_APP.scm.azurewebsites.net/ZipDeployUI`
2. 拖拽 `deploy/marketplace-portal.zip` 到页�?
3. 等待上传完成(�?30 �?

### 3.2 部署 Backend API

```bash
BACKEND_APP="mediagenie-backend-abc123"  # 从第二步输出获取

az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --src-path deploy/backend-api.zip \
  --type zip \
  --restart true
```

**或使�?Kudu**: `https://$BACKEND_APP.scm.azurewebsites.net/ZipDeployUI`

### 3.3 部署前端静态网�?

```bash
STORAGE_ACCOUNT="mediageniesaabc123"  # 从第二步输出获取

# 启用静态网�?
az storage blob service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --static-website \
  --index-document index.html \
  --404-document index.html

# 上传前端构建
az storage blob upload-batch \
  --account-name $STORAGE_ACCOUNT \
  --destination '$web' \
  --source deploy/frontend-build \
  --overwrite
```

---

## �?第四�? 验证部署

### 4.1 检�?Marketplace Portal
```bash
curl https://$PORTAL_APP.azurewebsites.net
```
**预期**: 返回 HTML 页面 (Landing Page)

### 4.2 检�?Backend API
```bash
curl https://$BACKEND_APP.azurewebsites.net/health
```
**预期**: `{"status": "healthy"}`

### 4.3 检查前�?
```bash
curl https://$STORAGE_ACCOUNT.z1.web.core.windows.net
```
**预期**: 返回 React 应用 HTML

### 4.4 功能测试
在浏览器打开:
- **Landing Page**: `https://$PORTAL_APP.azurewebsites.net`
- **应用界面**: `https://$STORAGE_ACCOUNT.z1.web.core.windows.net`

测试:
1. 语音转文�?
2. 文本转语�?
3. GPT 聊天
4. 图像分析

---

## 🔧 第五�? 配置 Marketplace 信息

### 5.1 获取必需�?URL

```bash
echo "Landing Page URL: https://$PORTAL_APP.azurewebsites.net"
echo "Webhook URL: https://$BACKEND_APP.azurewebsites.net/api/marketplace/webhook"
```

### 5.2 �?Azure Portal 中配�?

1. 登录 [Azure Portal](https://portal.azure.com)
2. 导航到你�?Marketplace Offer
3. 填写技术配�?
   - **Landing Page URL**: (上面输出�?URL)
   - **Webhook URL**: (上面输出�?URL)
4. 保存并发�?

---

## 🐛 故障排查

### 问题 1: Portal 返回 503 错误
**原因**: 依赖未正确安装或启动命令错误

**解决**:
```bash
# 查看日志
az webapp log tail --resource-group $RESOURCE_GROUP --name $PORTAL_APP

# 检查启动命�?
az webapp config show --resource-group $RESOURCE_GROUP --name $PORTAL_APP --query "linuxFxVersion"
```

**应该显示**: `PYTHON|3.11`

**修复启动命令**:
```bash
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $PORTAL_APP \
  --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 app:app"
```

### 问题 2: Backend API 无法连接 Azure OpenAI
**原因**: 环境变量未正确设�?

**解决**:
```bash
# 检查环境变�?
az webapp config appsettings list \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --query "[?name=='AZURE_OPENAI_KEY']"

# 重新设置
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --settings \
    AZURE_OPENAI_ENDPOINT="https://your-endpoint.openai.azure.com" \
    AZURE_OPENAI_KEY="your-key" \
    AZURE_OPENAI_DEPLOYMENT="gpt-4"
```

### 问题 3: 前端无法调用 Backend API (CORS 错误)
**原因**: CORS 未正确配�?

**解决**:
```bash
FRONTEND_URL="https://$STORAGE_ACCOUNT.z1.web.core.windows.net"

az webapp cors add \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --allowed-origins $FRONTEND_URL
```

### 问题 4: Zip Deploy 上传失败
**原因**: 文件过大或网络超�?

**解决方案 A**: 使用 Kudu 手动上传 (见第三步方式 B)

**解决方案 B**: 拆分上传
```bash
# 仅上传代�?(不含依赖)
zip -r deploy/code-only.zip marketplace-portal/*.py marketplace-portal/templates

az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $PORTAL_APP \
  --src-path deploy/code-only.zip \
  --type zip
```

---

## 💰 成本估算

| 服务 | SKU | 月费�?(美元) |
|------|-----|--------------|
| App Service Plan (B1) | 1�?.75GB | ~$13 |
| Storage Account (LRS) | Hot Tier | ~$0.50 |
| **总计** | | **~$13.50/�?* |

> �? Azure AI 服务按用量计�?未包含在上述费用�?

---

## 📚 附录

### A. 完整部署脚本 (一键执�?
参见 `deploy-manual-complete.ps1`

### B. ARM 模板参数说明
参见 `deploy/azuredeploy-optimized.json` 注释

### C. 日志查看命令
```bash
# 实时日志
az webapp log tail --resource-group $RESOURCE_GROUP --name $PORTAL_APP

# 下载日志
az webapp log download --resource-group $RESOURCE_GROUP --name $PORTAL_APP --log-file logs.zip
```

### D. 清理资源
```bash
# 删除整个资源�?(慎用!)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

---

## 📞 支持

- **文档**: [Azure App Service 文档](https://docs.microsoft.com/zh-cn/azure/app-service/)
- **问题反馈**: 在项目仓库提�?Issue
- **技术支�?*: support@mediagenie.com

---

**部署成功�?请保存以下信�?**
- Landing Page URL
- Webhook URL
- Backend API URL
- Frontend URL
- 资源组名�?
- 订阅 ID

祝部署顺�? 🎉
