# MediaGenie Azure Marketplace 部署快速参�?

> **解决 Cloud Shell 超时的完整手动部署方�?*

---

## 🚀 三步部署 (Windows)

### 步骤 1: 构建部署�?
```powershell
cd F:\project\MediaGenie1001
.\build-deployment-packages.ps1
```
**耗时**: 5-10 分钟  
**输出**: `deploy/` 目录,包含所�?ZIP 包和 ARM 模板

---

### 步骤 2: 登录 Azure 并设置订�?
```powershell
az login
az account set --subscription "你的订阅名称"
```

---

### 步骤 3: 执行部署
```powershell
# 设置变量
$RG = "MediaGenie-Marketplace-RG"
$LOCATION = "eastus"
$PREFIX = "mediagenie"

# 创建资源�?
az group create --name $RG --location $LOCATION

# 部署 ARM 模板
az deployment group create `
  --resource-group $RG `
  --template-file deploy/azuredeploy-optimized.json `
  --parameters `
    appNamePrefix=$PREFIX `
    azureOpenAIEndpoint="https://your-endpoint.openai.azure.com" `
    azureOpenAIKey="your-key" `
    azureOpenAIDeployment="gpt-4" `
    azureSpeechKey="your-speech-key" `
    azureSpeechRegion="eastus"

# 获取应用名称
$PORTAL_APP = az deployment group show --resource-group $RG --name <deployment-name> --query 'properties.outputs.marketplaceAppName.value' -o tsv
$BACKEND_APP = az deployment group show --resource-group $RG --name <deployment-name> --query 'properties.outputs.backendAppName.value' -o tsv

# 部署应用
az webapp deploy --resource-group $RG --name $PORTAL_APP --src-path deploy/marketplace-portal.zip --type zip --restart true
az webapp deploy --resource-group $RG --name $BACKEND_APP --src-path deploy/backend-api.zip --type zip --restart true
```

---

## 🐧 三步部署 (Linux/Mac)

### 步骤 1: 构建部署�?
```bash
cd /path/to/MediaGenie1001
pwsh build-deployment-packages.ps1
# 或使用本�?Python 手动打包
```

### 步骤 2-3: 执行部署
```bash
chmod +x deploy-manual-complete.sh

# 编辑脚本,填入你的 Azure AI 密钥
nano deploy-manual-complete.sh

# 执行部署
./deploy-manual-complete.sh
```

---

## 🌐 如果网络受限 (使用 Kudu)

### 方案 A: Azure Portal 上传

1. **部署基础设施**
   - 登录 [Azure Portal](https://portal.azure.com)
   - 点击 "创建资源" �?"模板部署"
   - 上传 `deploy/azuredeploy-optimized.json`
   - 填写参数并部�?

2. **上传应用代码**
   - 找到创建�?App Service
   - 打开 "高级工具" (Kudu)
   - 访问 `/ZipDeployUI`
   - 拖拽 `marketplace-portal.zip` �?`backend-api.zip`

### 方案 B: Azure Cloud Shell (短命�?

```bash
# 仅部�?ARM 模板 (不会超时)
az deployment group create -g MediaGenie-RG --template-file azuredeploy-optimized.json --parameters @params.json

# 使用 Kudu 上传代码 (见方�?A)
```

---

## �?验证部署

### 快速检�?
```bash
PORTAL_APP="mediagenie-marketplace-xxx"
BACKEND_APP="mediagenie-backend-xxx"

# 检�?Portal
curl https://$PORTAL_APP.azurewebsites.net

# 检�?API
curl https://$BACKEND_APP.azurewebsites.net/health
```

### 完整测试
1. 打开 Landing Page URL
2. 打开 Frontend URL
3. 测试语音转文�?
4. 测试文本转语�?
5. 测试 GPT 聊天
6. 测试图像分析

---

## 🐛 常见问题

| 问题 | 解决方法 |
|------|---------|
| 503 Service Unavailable | 查看日志: `az webapp log tail -g RG -n APP_NAME` |
| CORS 错误 | 检�?Backend �?CORS 设置 |
| OpenAI 调用失败 | 验证环境变量: `az webapp config appsettings list -g RG -n APP` |
| Kudu 上传失败 | 检�?ZIP 包大�?拆分上传 |

### 查看日志
```bash
# 实时日志
az webapp log tail --resource-group MediaGenie-RG --name mediagenie-marketplace-xxx

# 下载日志
az webapp log download --resource-group MediaGenie-RG --name mediagenie-marketplace-xxx --log-file logs.zip
```

### 重新部署某个应用
```bash
# 重新上传代码
az webapp deploy -g MediaGenie-RG -n mediagenie-marketplace-xxx --src-path deploy/marketplace-portal.zip --type zip --restart true

# 或使�?Kudu
open https://mediagenie-marketplace-xxx.scm.azurewebsites.net/ZipDeployUI
```

---

## 📋 Marketplace 配置

部署完成�?�?Azure Marketplace Partner Center 中配�?

| 字段 | �?|
|------|-----|
| **Landing Page URL** | `https://mediagenie-marketplace-xxx.azurewebsites.net` |
| **Webhook URL** | `https://mediagenie-backend-xxx.azurewebsites.net/api/marketplace/webhook` |

---

## 💰 成本控制

### 每月预估费用
- **App Service Plan (B1)**: ~$13
- **Storage Account**: ~$0.50
- **总计**: ~$13.50/�?

### 节省成本
```bash
# 停止 App Service (不使用时)
az webapp stop -g MediaGenie-RG -n mediagenie-marketplace-xxx
az webapp stop -g MediaGenie-RG -n mediagenie-backend-xxx

# 启动 App Service
az webapp start -g MediaGenie-RG -n mediagenie-marketplace-xxx
az webapp start -g MediaGenie-RG -n mediagenie-backend-xxx
```

---

## 📞 获取帮助

- **详细指南**: [MANUAL_DEPLOYMENT_GUIDE.md](MANUAL_DEPLOYMENT_GUIDE.md)
- **ARM 模板文档**: [Azure ARM 文档](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- **App Service 文档**: [Azure App Service 文档](https://docs.microsoft.com/azure/app-service/)
- **问题反馈**: 在项目仓库提�?Issue

---

**部署愉快! 🎉**
