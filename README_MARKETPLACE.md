# 🎯 MediaGenie - Azure AI Marketplace Solution

MediaGenie是一个功能强大的AI多模态应�?集成了Azure OpenAI、Azure Speech Services和Azure Computer Vision,提供对话、语音转换和图像分析功能�?

## �?核心功能

### 1. 💬 智能对话
- 基于Azure OpenAI GPT-4
- 支持上下文对�?
- 多轮对话记忆

### 2. 🔊 语音转换
- **文字转语�?(TTS)**: 
  - 支持中文神经语音(晓晓)
  - 自然流畅的语音合�?
  - 建议使用短文�?1-10�?
  
- **语音转文�?(STT)**: 
  - 高准确度语音识别
  - 支持WAV格式(16kHz, 16-bit, mono)
  - 实时识别

### 3. 🖼�?图像分析
- Azure Computer Vision集成
- 图像内容识别
- OCR文字提取

## 🚀 快速部�?

### 方式1: Azure Cloud Shell (推荐)

```bash
# 1. 打开Azure Cloud Shell
# 2. 上传项目文件
# 3. 执行部署脚本
chmod +x deploy-cloudshell.sh
./deploy-cloudshell.sh
```

### 方式2: Azure ARM Template

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/YOUR_TEMPLATE_URI)

## 📋 前置要求

需要以下Azure资源:
- �?Azure OpenAI Service
- �?Azure Speech Services
- ⚠️ Azure Computer Vision (可�?

## 🌐 访问URL

部署完成�?你将获得:

1. **应用主页**: `https://[your-app].azurewebsites.net`
2. **API文档**: `https://[your-app].azurewebsites.net/docs`
3. **健康检�?*: `https://[your-app].azurewebsites.net/health`

## 🔧 配置参数

| 参数 | 描述 | 必需 |
|------|------|------|
| `azureOpenAIKey` | Azure OpenAI API密钥 | �?|
| `azureOpenAIEndpoint` | Azure OpenAI端点 | �?|
| `azureSpeechKey` | Azure Speech密钥 | �?|
| `azureSpeechRegion` | Azure Speech区域 | �?|
| `azureVisionKey` | Azure Vision密钥 | ⚠️ |
| `azureVisionEndpoint` | Azure Vision端点 | ⚠️ |

## 📊 定价�?

| SKU | vCPU | RAM | 价格/�?| 推荐用�?|
|-----|------|-----|---------|----------|
| F1 | 共享 | 1GB | 免费 | 开发测�?|
| B1 | 1 | 1.75GB | ~$13 | 小型应用 |
| B2 | 2 | 3.5GB | ~$26 | 中型应用 |
| S1 | 1 | 1.75GB | ~$70 | 生产环境 |

## 🧪 API端点

### GPT对话
```bash
POST /api/gpt/chat
Content-Type: application/json

{
  "messages": [
    {"role": "user", "content": "你好"}
  ]
}
```

### 文字转语�?
```bash
POST /api/speech/text-to-speech
Content-Type: application/json

{
  "text": "你好",
  "language": "zh-CN"
}
```

### 语音转文�?
```bash
POST /api/speech/speech-to-text-file
Content-Type: multipart/form-data

file: [audio.wav]
language: zh-CN
```

### 图像分析
```bash
POST /api/vision/analyze-image
Content-Type: multipart/form-data

file: [image.jpg]
```

## 📈 性能优化

1. **启用Always On**: 避免Cold Start
2. **使用B2或更高SKU**: 更好的性能
3. **短文本TTS**: 避免超时问题
4. **CDN加�?*: 静态资源分�?

## 🐛 故障排查

### 查看日志
```bash
az webapp log tail --name [your-app] --resource-group MediaGenie-RG
```

### 重启应用
```bash
az webapp restart --name [your-app] --resource-group MediaGenie-RG
```

### 查看设置
```bash
az webapp config appsettings list --name [your-app] --resource-group MediaGenie-RG
```

## 🔒 安全�?

- �?HTTPS Only
- �?环境变量存储密钥
- �?Azure Managed Identity支持
- �?最小TLS 1.2

## 📞 技术支�?

- 📖 [完整部署指南](./AZURE_DEPLOYMENT_GUIDE.md)
- 📖 [手动测试指南](./MANUAL_TEST_GUIDE.md)
- 🐛 [GitHub Issues](https://github.com/yourrepo/issues)
- 📧 Email: support@yourdomain.com

## 📄 许可�?

MIT License

---

**由Azure AI驱动 | 适用于Azure Marketplace**
