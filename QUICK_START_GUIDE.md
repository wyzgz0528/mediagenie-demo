# MediaGenie Azure 快速开始指�?
## 🎯 5分钟快速部�?
### 前提条件
- �?Azure 账号（有效订阅）
- �?Azure OpenAI 服务（已创建并获取密钥）
- �?Azure Speech 服务（已创建并获取密钥）

### 部署步骤

#### 1️⃣ 打开 Azure Cloud Shell
访问: https://shell.azure.com
选择: **Bash** 环境

#### 2️⃣ 上传部署�?- 点击顶部 **↑↓** 图标
- 上传 `MediaGenie-Azure-Deploy.zip`

#### 3️⃣ 解压并配�?```bash
unzip MediaGenie-Azure-Deploy.zip
cd MediaGenie-Azure-Deploy
code deploy-cloudshell.sh
```

**修改以下配置**（第30-33行）:
```bash
AZURE_OPENAI_KEY="你的OpenAI密钥"
AZURE_OPENAI_ENDPOINT="https://你的openai.openai.azure.com/"
AZURE_SPEECH_KEY="你的Speech密钥"
AZURE_SPEECH_REGION="eastus"
```

保存: `Ctrl+S`，退�? `Ctrl+Q`

#### 4️⃣ 执行部署
```bash
chmod +x deploy-cloudshell.sh
./deploy-cloudshell.sh
```

⏱️ 等待 5-10 分钟...

#### 5️⃣ 验证部署
```bash
# 替换为你的应用名�?curl https://mediagenie-xxxxxx.azurewebsites.net/health
```

�?看到 `"status": "healthy"` 表示部署成功�?
---

## 📱 测试 API

### 1. 文本转语�?```bash
curl -X POST https://your-app.azurewebsites.net/api/speech/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{"text": "你好世界", "voice": "zh-CN-XiaoxiaoNeural"}' \
  --output test.mp3
```

### 2. GPT 对话
```bash
curl -X POST https://your-app.azurewebsites.net/api/gpt/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好"}'
```

### 3. API 文档
浏览器访�? `https://your-app.azurewebsites.net/docs`

---

## 🔧 常用命令

### 查看日志
```bash
az webapp log tail -n your-app-name -g MediaGenie-RG
```

### 重启应用
```bash
az webapp restart -n your-app-name -g MediaGenie-RG
```

### 删除资源
```bash
az group delete -n MediaGenie-RG --yes
```

---

## 💰 成本
- **App Service (B1)**: ~$13/�?- **Azure 认知服务**: 按使用量计费

---

## 🆘 遇到问题�?
1. **部署失败**: 检�?Azure 配额和区�?2. **503 错误**: 等待 2-3 分钟让应用启�?3. **API 失败**: 验证环境变量配置

详细文档: `FINAL_DEPLOYMENT_SUMMARY.md`

---

**就这么简单！** 🎉

