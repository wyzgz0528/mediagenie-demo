# MediaGenie - Quick Deploy to Azure Cloud Shell

## 🚀 快速部署指�?

### 📦 第一�?生成部署�?

在本�?Windows 环境运行:

```powershell
.\build-deployment-packages.ps1
```

生成�?`deploy` 文件夹包�?
- �?marketplace-portal.zip (3.24 MB)
- �?backend-api.zip (44.96 MB)  
- �?frontend-build.zip (0.38 MB)
- �?azuredeploy-optimized.json
- �?deploy-to-azure.sh (一键部署脚�?

### 📤 第二�?上传�?Azure Cloud Shell

1. 打开 Azure Cloud Shell: https://shell.azure.com
2. 选择 **Bash** 环境
3. 点击上传按钮 (📤 图标)
4. 上传整个 `deploy` 文件�?

或者压缩后上传:
```powershell
# Windows 本地
Compress-Archive -Path deploy -DestinationPath MediaGenie-Deploy.zip
```

然后�?Cloud Shell �?
```bash
# 上传 MediaGenie-Deploy.zip �?
unzip MediaGenie-Deploy.zip
cd deploy
```

### �?第三�?一键部�?

```bash
# 设置执行权限
chmod +x deploy-to-azure.sh

# 运行部署脚本
./deploy-to-azure.sh
```

### 🔑 部署时需要提供的信息

脚本会交互式询问:

1. **Resource Group 名称** (默认: MediaGenie-RG)
2. **部署区域** (默认: eastus)
3. **应用前缀** (默认: mediagenie, 小写无空�?
4. **Azure OpenAI API Key** ⚠️ 必填
5. **Azure OpenAI Endpoint** ⚠️ 必填  
   格式: `https://your-openai.openai.azure.com`
6. **Azure Speech Service Key** ⚠️ 必填
7. **Azure Speech Region** (默认: eastus)

### 📊 部署进度

脚本自动执行:
- �?创建资源�?
- �?部署基础设施 (App Service + Storage)
- �?上传 Marketplace Portal
- �?上传 Backend API (包含所有依�?
- �?上传 Frontend �?Blob Storage
- �?验证服务可用�?

**预计时间**: 5-10 分钟

### 🎉 部署完成

完成后会显示:

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

### 🔍 验证部署

测试 API:
```bash
curl https://mediagenie-backend.azurewebsites.net/health
```

查看日志:
```bash
az webapp log tail \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend
```

## 🛠�?故障排查

### 上传超时

如果文件太大导致上传失败:

**方案 A: 使用 Azure Storage**
```bash
# 1. 创建临时存储账户用于上传
az storage account create \
  --name tempupload$RANDOM \
  --resource-group MediaGenie-RG \
  --location eastus \
  --sku Standard_LRS

# 2. 上传文件
az storage blob upload \
  --account-name tempupload12345 \
  --container-name packages \
  --file backend-api.zip \
  --name backend-api.zip

# 3. �?Cloud Shell 下载
az storage blob download \
  --account-name tempupload12345 \
  --container-name packages \
  --name backend-api.zip \
  --file backend-api.zip
```

**方案 B: 使用 Git**
```bash
# �?deploy 文件夹提交到 Git 仓库
# 然后�?Cloud Shell �?clone
git clone https://github.com/yourname/MediaGenie.git
cd MediaGenie/deploy
```

### 部署失败

手动部署步骤:

```bash
# 1. 部署基础设施
az deployment group create \
  --resource-group MediaGenie-RG \
  --template-file azuredeploy-optimized.json \
  --parameters appNamePrefix=mediagenie

# 2. 部署 Portal
az webapp deploy \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace \
  --src-path marketplace-portal.zip \
  --type zip

# 3. 配置并部�?Backend
az webapp config appsettings set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --settings \
    AZURE_OPENAI_KEY="your-key" \
    AZURE_OPENAI_ENDPOINT="https://your-endpoint"

az webapp deploy \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --src-path backend-api.zip \
  --type zip \
  --timeout 600
```

### 依赖缺失错误

所�?Python 依赖已预装在 `.python_packages` 目录中�?

如果仍有问题,检查配�?
```bash
az webapp config appsettings list \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend
```

## 🗑�?清理资源

删除所有部署的资源:

```bash
az group delete \
  --name MediaGenie-RG \
  --yes \
  --no-wait
```

## 📚 详细文档

- 完整部署指南: `CLOUDSHELL_DEPLOYMENT.md`
- 手动部署步骤: `MANUAL_DEPLOYMENT_GUIDE.md`
- 部署清单: `deploy/DEPLOYMENT_MANIFEST.md`

## 🆘 获取帮助

查看应用日志:
```bash
az webapp log tail -g MediaGenie-RG -n mediagenie-backend
```

访问 Kudu 控制�?
```
https://mediagenie-backend.scm.azurewebsites.net
```

监控指标:
- Azure Portal > App Services > mediagenie-backend > Metrics

---

**提示**: 确保已准备好 Azure OpenAI �?Speech Service �?API 密钥!
