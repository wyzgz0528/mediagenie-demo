# 🚀 MediaGenie 一键部署指�?

## 📦 第一�?准备配置文件

### 1. 填写 .env 配置

�?`deploy` 文件夹中,�?`.env.template` 重命名为 `.env` 并填入你的真实密�?

```bash
# deploy/.env
AZURE_OPENAI_KEY=你的OpenAI密钥
AZURE_OPENAI_ENDPOINT=https://你的openai资源.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview

AZURE_SPEECH_KEY=你的语音服务密钥
AZURE_SPEECH_REGION=eastus

RESOURCE_GROUP=MediaGenie-RG
APP_NAME_PREFIX=mediagenie
LOCATION=eastus
```

### 2. 打包上传

```powershell
# Windows PowerShell
# 方式 A: 打包整个 deploy 文件�?包含 .env)
Compress-Archive -Path deploy -DestinationPath MediaGenie-Deploy.zip

# 方式 B: �?.env 放到项目根目�?
Copy-Item deploy\.env.template .env  # 然后编辑 .env
Compress-Archive -Path deploy,.env -DestinationPath MediaGenie-Deploy.zip
```

## ☁️ 第二�?上传�?Azure Cloud Shell

1. 打开 https://shell.azure.com (选择 **Bash**)
2. 点击上传按钮 📤
3. 上传 `MediaGenie-Deploy.zip`
4. 解压:

```bash
unzip MediaGenie-Deploy.zip
cd deploy
ls -la  # 确认 .env 文件存在
```

## �?第三�?一键部�?

```bash
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
```

**就这么简�?** 脚本�?
- �?自动�?`.env` 读取所有配�?
- �?跳过所有交互式提示
- �?5-10分钟完成全部部署

## 🎯 部署完成

会看�?

```
==========================================
  MediaGenie Deployment Complete!
==========================================

Application URLs:
  Marketplace Portal: https://mediagenie-marketplace.azurewebsites.net
  Backend API:        https://mediagenie-backend.azurewebsites.net
  Frontend:           https://mediageniestorage.z1.web.core.windows.net
==========================================
```

## 🔒 安全提示

### ⚠️ 重要:.env 包含敏感信息

**不要提交�?Git:**
```bash
echo ".env" >> .gitignore
```

**上传后删除本�?.env:**
```powershell
Remove-Item deploy\.env
```

**Cloud Shell 中使用完后也删除:**
```bash
rm .env
```

## 🔄 如果没有 .env 会怎样?

脚本会自动切换到**交互模式**,逐个询问配置�?

```bash
./deploy-to-azure.sh

# 输出:
[INFO] No .env file found, will prompt for configuration
Enter Azure Resource Group name [MediaGenie-RG]: 
Enter Azure OpenAI API Key: ****
Enter Azure OpenAI Endpoint: https://...
...
```

## 📋 完整 .env 模板

```bash
# ============ Azure OpenAI ============
AZURE_OPENAI_KEY=sk-your-key-here
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ============ Azure Speech ============
AZURE_SPEECH_KEY=your-speech-key
AZURE_SPEECH_REGION=eastus

# ========== Azure Vision (可�? ==========
AZURE_VISION_KEY=YOUR_AZURE_VISION_KEY_HERE
AZURE_VISION_ENDPOINT=https://your-vision.cognitiveservices.azure.com/

# ========== 部署配置 ==========
RESOURCE_GROUP=MediaGenie-RG
APP_NAME_PREFIX=mediagenie
LOCATION=eastus
SKU=B1
```

## 🎓 高级技�?

### 多环境部�?

```bash
# 保留多个环境配置
.env.dev      # 开发环�?
.env.staging  # 测试环境  
.env.prod     # 生产环境

# 部署到生�?
cp .env.prod .env
./deploy-to-azure.sh
```

### 使用 Azure Key Vault

```bash
# �?Key Vault 获取密钥
export AZURE_OPENAI_KEY=$(az keyvault secret show \
  --vault-name MyVault \
  --name openai-key \
  --query value -o tsv)

./deploy-to-azure.sh  # 使用导出的环境变�?
```

## 📞 故障排查

### .env 未生�?

检查文件位�?
```bash
ls -la .env        # 在当前目�?
ls -la ../.env     # 在父目录
```

脚本会检查两个位�?

### 需要修改配�?

重新编辑 .env 并重新部�?
```bash
nano .env  # �?vi .env
./deploy-to-azure.sh
```

### 查看实际使用的配�?

部署开始时会显�?
```
[INFO] Found .env file, loading configuration...
[SUCCESS] Configuration loaded from .env
...
Resource Group: MediaGenie-RG
Location: eastus
Marketplace App: mediagenie-marketplace
Backend App: mediagenie-backend
```

## �?部署前检查清�?

- [ ] 已填�?`.env` 中的 `AZURE_OPENAI_KEY`
- [ ] 已填�?`.env` 中的 `AZURE_OPENAI_ENDPOINT`  
- [ ] 已填�?`.env` 中的 `AZURE_SPEECH_KEY`
- [ ] 已填�?`RESOURCE_GROUP` �?`APP_NAME_PREFIX`
- [ ] 已将 `.env` 添加�?`.gitignore`
- [ ] 已上传到 Azure Cloud Shell
- [ ] 已运�?`chmod +x deploy-to-azure.sh`

完成�?运行 `./deploy-to-azure.sh` 即可! 🎉

---

**提示**: 首次部署推荐使用 `.env` 方式,无需手动输入大量配置,更快更安�?
