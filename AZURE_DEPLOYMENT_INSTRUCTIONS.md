# MediaGenie Azure Marketplace 部署完整指南

## 📋 项目概述

**MediaGenie** 是一个基�?Azure 认知服务的智能媒体处理平台，提供�?- 🎤 语音转文�?(Speech-to-Text)
- 🔊 文本转语�?(Text-to-Speech)  
- 🖼�?图像分析 (Computer Vision)
- 💬 GPT 智能对话 (Azure OpenAI)

## 🎯 部署架构

```
┌─────────────────────────────────────────────────────────────�?�?                   Azure Marketplace                         �?�?                                                             �?�? ┌──────────────�?        ┌──────────────�?                �?�? �? Frontend    │────────▶│   Backend    �?                �?�? �? (React)     �?        �? (FastAPI)   �?                �?�? �? Static Web  �?        �? Web App     �?                �?�? └──────────────�?        └──────┬───────�?                �?�?                                  �?                         �?�?                   ┌──────────────┴──────────────�?         �?�?                   �?                             �?         �?�?          ┌────────▼────────�?         ┌─────────▼────────�?�?�?          �?Azure Speech    �?         �?Azure OpenAI     �?�?�?          �?Services        �?         �?Services         �?�?�?          └─────────────────�?         └──────────────────�?�?└─────────────────────────────────────────────────────────────�?```

## 📦 部署前准�?
### 1. Azure 服务要求

在部署前，你需要在 Azure Portal 创建以下服务并获取密钥：

#### �?Azure OpenAI Service
1. 访问 [Azure Portal](https://portal.azure.com)
2. 创建 "Azure OpenAI" 资源
3. 部署 GPT-4 模型（推荐：gpt-4 �?gpt-4-turbo�?4. 获取�?   - **Endpoint**: `https://your-openai.openai.azure.com/`
   - **API Key**: �?"Keys and Endpoint" 中获�?   - **Deployment Name**: 你创建的模型部署名称

#### �?Azure Speech Services
1. 创建 "Speech Services" 资源
2. 选择区域（推荐：East US �?East Asia�?3. 获取�?   - **API Key**: �?"Keys and Endpoint" 中获�?   - **Region**: 例如 `eastus` �?`eastasia`

#### �?Azure Computer Vision (可�?
1. 创建 "Computer Vision" 资源
2. 获取�?   - **Endpoint**: `https://your-vision.cognitiveservices.azure.com/`
   - **API Key**: �?"Keys and Endpoint" 中获�?
### 2. 成本估算

| 服务 | 定价�?| 月成本（估算�?|
|------|--------|----------------|
| App Service Plan | B1 (Basic) | ~$13 USD |
| Storage Account | Standard | ~$1 USD |
| Azure OpenAI | Pay-as-you-go | 按使用量 |
| Speech Services | Pay-as-you-go | 按使用量 |
| **总计** | | **~$15 USD + 使用�?* |

## 🚀 部署方法

### 方法 1: Azure Cloud Shell 一键部署（推荐�?
#### 步骤 1: 准备部署脚本

1. 打开 [Azure Cloud Shell](https://shell.azure.com)
2. 选择 **Bash** 环境
3. 上传项目文件�?   ```bash
   # 如果你有项目zip�?   # 点击 Cloud Shell 顶部�?"上传/下载文件" 图标
   # 上传 MediaGenie-Deploy.zip
   
   # 解压
   unzip MediaGenie-Deploy.zip
   cd MediaGenie-Deploy
   ```

#### 步骤 2: 配置环境变量

编辑 `deploy-cloudshell.sh` 文件，替换以下变量：

```bash
# 打开编辑�?code deploy-cloudshell.sh

# 修改以下配置�?AZURE_OPENAI_KEY="你的OpenAI密钥"
AZURE_OPENAI_ENDPOINT="https://你的openai.openai.azure.com/"
AZURE_SPEECH_KEY="你的Speech密钥"
AZURE_SPEECH_REGION="eastus"  # 你的Speech服务区域
```

#### 步骤 3: 执行部署

```bash
# 添加执行权限
chmod +x deploy-cloudshell.sh

# 运行部署脚本
./deploy-cloudshell.sh
```

部署过程大约需�?**5-10 分钟**�?
#### 步骤 4: 验证部署

部署完成后，脚本会显示：
```
🎉 部署完成!

📋 部署信息:
  应用名称:      mediagenie-abc123
  应用主页:      https://mediagenie-abc123.azurewebsites.net
  API文档:       https://mediagenie-abc123.azurewebsites.net/docs
  健康检�?      https://mediagenie-abc123.azurewebsites.net/health
```

访问健康检查URL，应该看到：
```json
{
  "status": "healthy",
  "timestamp": "2025-01-21T10:30:00Z",
  "services": {
    "speech": "available",
    "vision": "not_configured",
    "storage": "not_configured"
  }
}
```

### 方法 2: Azure Portal ARM 模板部署

#### 步骤 1: 准备 ARM 模板

1. �?Azure Portal 中，搜索 "Deploy a custom template"
2. 点击 "Build your own template in the editor"
3. 上传 `azuredeploy.json` 文件

#### 步骤 2: 填写参数

- **Site Name**: 应用名称（例如：mediagenie-prod�?- **Location**: 区域（例如：East US�?- **SKU**: 定价层（推荐：B1�?- **Azure OpenAI Key**: 你的 OpenAI API 密钥
- **Azure OpenAI Endpoint**: 你的 OpenAI 端点
- **Azure Speech Key**: 你的 Speech API 密钥
- **Azure Speech Region**: 你的 Speech 服务区域

#### 步骤 3: 部署代码

ARM 模板会创建基础设施，但你还需要部署代码：

```bash
# 在本地或 Cloud Shell �?cd backend/media-service

# 创建部署�?zip -r deploy.zip . -x "*.pyc" -x "__pycache__/*" -x "logs/*"

# 使用 Azure CLI 部署
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name your-app-name \
  --src deploy.zip
```

### 方法 3: GitHub Actions CI/CD（高级）

创建 `.github/workflows/azure-deploy.yml`�?
```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          cd backend/media-service
          pip install -r requirements.txt
      
      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ secrets.AZURE_WEBAPP_NAME }}
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: backend/media-service
```

## 🔧 部署后配�?
### 1. 配置 CORS（如果需要前端）

```bash
az webapp cors add \
  --resource-group MediaGenie-RG \
  --name your-app-name \
  --allowed-origins "https://yourdomain.com"
```

### 2. 启用应用日志

```bash
az webapp log config \
  --resource-group MediaGenie-RG \
  --name your-app-name \
  --application-logging filesystem \
  --level information
```

### 3. 查看实时日志

```bash
az webapp log tail \
  --resource-group MediaGenie-RG \
  --name your-app-name
```

## 🧪 测试部署

### 1. 健康检�?
```bash
curl https://your-app-name.azurewebsites.net/health
```

### 2. 测试文本转语�?
```bash
curl -X POST https://your-app-name.azurewebsites.net/api/speech/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{"text": "你好，这是测�?, "voice": "zh-CN-XiaoxiaoNeural"}' \
  --output test.mp3
```

### 3. 测试 GPT 对话

```bash
curl -X POST https://your-app-name.azurewebsites.net/api/gpt/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好，请介绍一下MediaGenie"}'
```

## 📊 监控和维�?
### 查看应用指标

1. 访问 [Azure Portal](https://portal.azure.com)
2. 导航到你�?Web App
3. 查看 "Metrics" �?"Logs"

### 常用监控命令

```bash
# 查看应用状�?az webapp show \
  --resource-group MediaGenie-RG \
  --name your-app-name \
  --query state

# 重启应用
az webapp restart \
  --resource-group MediaGenie-RG \
  --name your-app-name

# 查看配置
az webapp config appsettings list \
  --resource-group MediaGenie-RG \
  --name your-app-name
```

## 🐛 故障排除

### 问题 1: 应用无法启动

**症状**: 访问URL返回 503 错误

**解决方案**:
```bash
# 查看日志
az webapp log tail -n your-app-name -g MediaGenie-RG

# 检查启动命�?az webapp config show -n your-app-name -g MediaGenie-RG --query linuxFxVersion
```

### 问题 2: Azure 服务调用失败

**症状**: API 返回 "service not available"

**解决方案**:
1. 检查环境变量是否正确设�?2. 验证 Azure 服务密钥是否有效
3. 确认服务区域匹配

```bash
# 检查环境变�?az webapp config appsettings list -n your-app-name -g MediaGenie-RG
```

### 问题 3: 性能问题

**症状**: 响应缓慢

**解决方案**:
1. 升级到更高的定价层（B2 �?S1�?2. 启用 Application Insights
3. 优化代码和数据库查询

## 📚 相关文档

- [Azure App Service 文档](https://docs.microsoft.com/azure/app-service/)
- [Azure OpenAI 文档](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Azure Speech Services 文档](https://docs.microsoft.com/azure/cognitive-services/speech-service/)
- [FastAPI 文档](https://fastapi.tiangolo.com/)

## 🆘 获取帮助

如果遇到问题�?1. 查看 [GitHub Issues](https://github.com/your-org/MediaGenie/issues)
2. 联系技术支�? support@smartwebco.com
3. 查看 Azure 支持文档

---

**祝部署顺利！** 🎉

