# MediaGenie Azure Marketplace 完整部署指南

## �?已完成的工作

### 1. 代码修复 �?- [x] **前端 API 路径**：修改为动态获取，支持相对路径
- [x] **后端环境变量**：已使用 `os.getenv()`，无硬编�?- [x] **生产环境配置**：创�?`.env.production`
- [x] **前端构建**：成功构建生产版本（1.26 MB�?
### 2. 部署包准�?�?- [x] **完整部署�?*：`MediaGenie-Marketplace-Deploy.zip` (0.41 MB)
- [x] **包含内容**�?  - backend/media-service/ (完整后端代码)
  - frontend/build/ (生产构建)
  - azuredeploy.json (ARM 模板)
  - deploy-cloudshell.sh (部署脚本)
  - .deployment (Kudu 配置)

---

## 🎯 部署方案：Solution Template（推荐）

### 为什么选择 Solution Template�?
| 特�?| SaaS Offer | Solution Template | MediaGenie |
|------|-----------|------------------|------------|
| 部署位置 | 你的订阅 | 客户订阅 | **客户订阅** �?|
| Landing Page | 必需 | 不需�?| **不需�?* �?|
| Webhook | 必需 | 不需�?| **不需�?* �?|
| 复杂�?| �?| �?| **�?* �?|
| 上线速度 | �?| �?| **�?* �?|

**结论**：MediaGenie 适合使用 **Solution Template**，不需�?SaaS Accelerator�?
---

## 📦 部署包验�?
### 当前部署包状�?
```
�?文件�? MediaGenie-Marketplace-Deploy.zip
�?大小: 0.41 MB (合理)
�?结构: 正确

包含内容:
├── backend/
�?  └── media-service/          �?完整后端代码
�?      ├── main.py             �?使用环境变量
�?      ├── requirements.txt
�?      └── ...
├── frontend/
�?  └── build/                  �?生产构建 (1.26 MB)
�?      ├── index.html
�?      ├── static/
�?      └── ...
├── azuredeploy.json            �?ARM 模板
├── deploy-cloudshell.sh        �?部署脚本
├── .deployment                 �?Kudu 配置
├── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## 🚀 部署架构

### 推荐架构：前后端同域

```
Azure Web App: mediagenie-xxxxx.azurewebsites.net
�?├── /                           �?前端 (React)
�?  ├── /dashboard
�?  ├── /text-to-speech
�?  └── ...
�?└── /api/                       �?后端 (FastAPI)
    ├── /api/speech/text-to-speech
    ├── /api/gpt/chat
    └── ...
```

**优点**�?- �?�?CORS 问题
- �?前端自动使用 `window.location.origin`
- �?部署简�?- �?成本低（单个 Web App�?
---

## 🔧 部署步骤

### 方式1：使�?Cloud Shell 脚本（推荐）

#### 步骤1：上传部署包

1. 打开 Azure Cloud Shell (https://shell.azure.com)
2. 上传 `MediaGenie-Marketplace-Deploy.zip`
3. 解压�?   ```bash
   unzip MediaGenie-Marketplace-Deploy.zip -d mediagenie-deploy
   cd mediagenie-deploy
   ```

#### 步骤2：配�?API Keys

编辑 `deploy-cloudshell.sh`，更新以下变量：

```bash
# Azure OpenAI
AZURE_OPENAI_KEY="your-openai-key-here"
AZURE_OPENAI_ENDPOINT="https://your-openai.openai.azure.com/"

# Azure Speech
AZURE_SPEECH_KEY="your-speech-key-here"
AZURE_SPEECH_REGION="eastus"
```

#### 步骤3：运行部�?
```bash
chmod +x deploy-cloudshell.sh
./deploy-cloudshell.sh
```

#### 步骤4：验证部�?
部署完成后，访问�?- 应用主页: `https://mediagenie-xxxxx.azurewebsites.net/`
- API 文档: `https://mediagenie-xxxxx.azurewebsites.net/docs`
- 健康检�? `https://mediagenie-xxxxx.azurewebsites.net/health`

---

### 方式2：使�?ARM 模板

#### 步骤1：在 Azure Portal �?
1. 登录 Azure Portal
2. 点击"创建资源"
3. 搜索"模板部署"
4. 选择"在编辑器中生成自己的模板"

#### 步骤2：上�?ARM 模板

1. 上传 `azuredeploy.json`
2. 填写参数�?   - **siteName**: 应用名称
   - **azureOpenAIKey**: Azure OpenAI API Key
   - **azureOpenAIEndpoint**: Azure OpenAI Endpoint
   - **azureSpeechKey**: Azure Speech Key
   - **azureSpeechRegion**: Azure Speech Region

#### 步骤3：部�?
1. 选择订阅和资源组
2. 点击"审阅 + 创建"
3. 点击"创建"

---

## 🔐 安全配置

### API Keys 管理

**�?正确做法**（当前实现）�?
```python
# backend/media-service/main.py
AZURE_OPENAI_KEY = os.getenv("AZURE_OPENAI_API_KEY")
AZURE_SPEECH_KEY = os.getenv("AZURE_SPEECH_KEY")
```

**配置方式**�?
1. **App Service 应用设置**（推荐）�?   ```bash
   az webapp config appsettings set \
     --name mediagenie-xxxxx \
     --resource-group MediaGenie-RG \
     --settings \
       AZURE_OPENAI_API_KEY="your-key" \
       AZURE_SPEECH_KEY="your-key"
   ```

2. **ARM 模板参数**（部署时）：
   ```json
   "azureOpenAIKey": {
     "type": "securestring",
     "metadata": {
       "description": "Azure OpenAI API Key"
     }
   }
   ```

3. **Azure Key Vault**（最安全）：
   - �?Keys 存储�?Key Vault
   - App Service 通过 Managed Identity 访问

---

## 🌐 前端 API 路径配置

### 当前实现（已修复�?
```typescript
// frontend/src/services/api.ts
const getMediaServiceURL = (): string => {
  // 优先使用环境变量
  if (process.env.REACT_APP_MEDIA_SERVICE_URL) {
    return process.env.REACT_APP_MEDIA_SERVICE_URL;
  }
  
  // 生产环境：使用相对路�?  if (process.env.NODE_ENV === 'production') {
    return window.location.origin;  // �?动态获�?  }
  
  // 开发环�?  return 'http://localhost:9001';
};
```

### API 路径

所�?API 调用都使�?`/api/` 前缀�?
```typescript
// �?正确
mediaClient.post('/api/speech/text-to-speech', ...)
mediaClient.post('/api/gpt/chat', ...)

// �?错误（旧版本�?mediaClient.post('/speech/text-to-speech', ...)
```

---

## 📋 部署检查清�?
### 部署前检�?
- [x] 代码中无硬编码的 API Keys
- [x] 前端使用相对路径或环境变�?- [x] 部署包包含完整的前后端代�?- [x] 前端已构建生产版�?- [x] ARM 模板使用 securestring 参数
- [x] .deployment 文件配置正确

### 部署后验�?
- [ ] 应用主页可访�?- [ ] API 文档可访�?(/docs)
- [ ] 健康检查返�?200 (/health)
- [ ] 前端可以调用后端 API
- [ ] 文本转语音功能正�?- [ ] GPT 对话功能正常
- [ ] 语音转文本功能正�?- [ ] 图像分析功能正常

---

## 🐛 常见问题解决

### 问题1：前端无法访�?
**症状**：访问主页返�?404

**原因**：前端未正确部署

**解决方案**�?1. 检�?`frontend/build` 是否在部署包�?2. 检�?Web App 配置是否正确
3. 查看部署日志

### 问题2：前端无法调用后�?API

**症状**：前端显�?网络错误"

**原因**：API 路径不正确或 CORS 问题

**解决方案**�?1. 检查浏览器控制台的网络请求
2. 确认 API 路径�?`/api/...`
3. 检查后�?CORS 配置

### 问题3：API Keys 无效

**症状**：API 调用返回 401 �?403

**原因**：环境变量未正确配置

**解决方案**�?```bash
# 检查环境变�?az webapp config appsettings list \
  --name mediagenie-xxxxx \
  --resource-group MediaGenie-RG

# 更新环境变量
az webapp config appsettings set \
  --name mediagenie-xxxxx \
  --resource-group MediaGenie-RG \
  --settings AZURE_OPENAI_API_KEY="new-key"
```

---

## 📊 成本估算

### 基础配置（B1 SKU�?
| 资源 | 配置 | 月成本（USD�?|
|------|------|--------------|
| App Service Plan | B1 (1 Core, 1.75 GB RAM) | ~$13 |
| Azure OpenAI | 按使用量 | ~$10-20 |
| Azure Speech | 按使用量 | ~$5-10 |
| **总计** | | **~$30-45** |

### 优化建议

- 使用 F1 (Free) SKU 进行测试
- 生产环境使用 B1 或更�?- 启用 Auto-scaling 应对流量高峰

---

## 🎉 下一�?
### 1. 测试部署（立即执行）

```bash
# �?Cloud Shell �?unzip MediaGenie-Marketplace-Deploy.zip -d mediagenie-deploy
cd mediagenie-deploy
./deploy-cloudshell.sh
```

### 2. 发布�?Marketplace（可选）

如果要发布到 Azure Marketplace�?
1. �?Partner Center 创建 Offer
2. 选择 "Azure Application" �?"Solution Template"
3. 上传 ARM 模板和部署包
4. 填写 Marketplace 信息
5. 提交审核

---

## 📞 支持

### 查看日志

```bash
# 实时日志
az webapp log tail \
  --name mediagenie-xxxxx \
  --resource-group MediaGenie-RG

# 下载日志
az webapp log download \
  --name mediagenie-xxxxx \
  --resource-group MediaGenie-RG
```

### 重启应用

```bash
az webapp restart \
  --name mediagenie-xxxxx \
  --resource-group MediaGenie-RG
```

---

## �?总结

### 已解决的问题

1. �?**部署包不完整** �?创建了包含前后端的完整部署包
2. �?**路径硬编�?* �?前端使用动态路径，后端使用环境变量
3. �?**API Key 硬编�?* �?使用环境变量�?ARM 模板参数
4. �?**缺少 Landing Page/Webhook** �?使用 Solution Template，不需�?5. �?**前端 URL 报错** �?修复�?API 路径配置

### 当前状�?
- �?代码已修�?- �?部署包已创建
- �?部署脚本已准�?- �?等待测试部署

**现在可以开始测试部署了�?* 🚀

