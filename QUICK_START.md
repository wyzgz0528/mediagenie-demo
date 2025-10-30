# 🚀 MediaGenie Azure Marketplace 部署快速指�?

## �?5分钟快速部�?

### �?�? 打开 Azure Cloud Shell
- 访问: https://portal.azure.com
- 点击右上�?Cloud Shell 图标 `>_`
- 选择 **Bash** 模式

### �?�? 上传项目
```bash
# 创建工作目录
mkdir -p ~/mediagenie && cd ~/mediagenie

# 使用 Cloud Shell 上传功能上传以下文件:
# �?backend/ 文件�?
# �?frontend/ 文件�? 
# �?deploy-marketplace-complete.sh
```

### �?�? 配置密钥 (符合 Azure Marketplace 安全要求)

**⚠️ 重要**: 为了符合 Azure Marketplace 安全规范,我们使用**环境变量或交互式输入**,而非硬编码密钥�?

#### 方式 A: 使用环境变量 (推荐)

```bash
# 设置环境变量
export AZURE_OPENAI_KEY="你的OpenAI密钥"
export AZURE_OPENAI_ENDPOINT="https://你的.openai.azure.com/"
export AZURE_SPEECH_KEY="你的Speech密钥"
export AZURE_SPEECH_REGION="eastus"

# 或从 .env 文件加载 (不要提交 .env �?Git!)
export $(cat .env | xargs)
```

#### 方式 B: 交互式输�?(脚本会提�?

```bash
# 直接运行脚本,它会提示你输入密�?
./deploy-marketplace-complete.sh

# 脚本会依次询�?
# - Azure OpenAI Key
# - Azure OpenAI Endpoint
# - Azure Speech Key
# - Azure Speech Region
```

### �?�? 执行部署
```bash
chmod +x deploy-marketplace-complete.sh
./deploy-marketplace-complete.sh
```

### �?�? 等待完成 (5-10分钟)
脚本会自�?
- �?创建资源�?`MediaGenie-Marketplace-RG`
- �?创建 B1 App Service Plan
- �?部署后端 API (Python)
- �?构建并部署前�?(React)
- �?配置 CORS �?HTTPS
- �?输出2个公网URL

---

## 📝 你会得到�?个URL

### 1️⃣ 前端 URL (用户访问)
```
https://mediagenie-web-xxxxxx.azurewebsites.net
```

### 2️⃣ 后端 API URL
```
https://mediagenie-api-xxxxxx.azurewebsites.net
```

### 🔗 Azure Marketplace 集成端点 (重要!)

**Landing Page URL** (�?Partner Center 配置):
```
https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/landing
```

**Connection Webhook URL** (�?Partner Center 配置):
```
https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/webhook
```

📖 **详细配置指南**: 参见 `MARKETPLACE_INTEGRATION_GUIDE.md`

---

## �?部署后验�?

### 检查后端健�?
```bash
curl https://mediagenie-api-xxxxxx.azurewebsites.net/health
```
预期输出: `{"status":"healthy",...}`

### 检查前�?
在浏览器中打开前端URL,应该看到 MediaGenie 界面�?

### 查看日志 (如果有问�?
```bash
# 后端日志
az webapp log tail -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG

# 前端日志
az webapp log tail -n mediagenie-web-xxxxxx -g MediaGenie-Marketplace-RG
```

---

## 🛠�?常见问题快速修�?

### 问题: 后端健康检查失�?
```bash
# 检查环境变�?
az webapp config appsettings list -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG

# 重启后端
az webapp restart -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG
```

### 问题: 前端 CORS 错误
```bash
# 添加 CORS
az webapp cors add \
  -n mediagenie-api-xxxxxx \
  -g MediaGenie-Marketplace-RG \
  --allowed-origins "https://mediagenie-web-xxxxxx.azurewebsites.net"
```

### 问题: B1 资源不足
修改脚本�?2�?
```bash
SKU="B2"  # �?S1
```

---

## 🧹 清理资源

```bash
# 删除所有资�?
az group delete -n MediaGenie-Marketplace-RG --yes --no-wait
```

---

## 📊 成本估算

| 资源 | 定价 |
|------|------|
| B1 App Service Plan | ~$13/�?|
| 2�?Web Apps | 包含�?Plan �?|
| OpenAI API | 按使用量计费 |
| Speech API | 免费�?5小时/�?|

**总计: ~$13-50/�?*

---

## 📚 完整文档

详细步骤和故障排�? `DEPLOYMENT_GUIDE_COMPLETE.md`

---

## �?关键改进�?

�?**解决资源不足** - 使用 B1 替代 F1  
�?**解决部署包问�?* - 包含前端 build 和后端完整代�? 
�?**解决路径问题** - 前后端分�?独立 URL  
�?**解决前端错误** - 配置 web.config 支持路由  
�?**符合 Marketplace** - 提供2个独立的公网 URL  

---

**🎉 准备好了�? 开始部署吧!**
