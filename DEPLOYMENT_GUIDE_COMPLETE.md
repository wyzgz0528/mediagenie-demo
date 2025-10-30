# 📘 MediaGenie Azure Marketplace 部署完整指南

## 🎯 概述

本指南提�?**MediaGenie** 项目完整�?Azure Marketplace 部署方案,解决了之前部署失败的所有问�?

### �?解决的问�?
1. �?**资源不足** - 使用 B1 SKU 替代 F1 免费�?
2. �?**部署包不完整** - 包含前端 build 产物和后端完整代�?
3. �?**路径问题** - 前后端分�?独立 URL,正确�?API 路径配置
4. �?**前端访问错误** - 配置 web.config 支持 React Router
5. �?**�?URL 要求** - 提供前端和后端两个独立的公网 URL

---

## 🏗�?部署架构

```
┌─────────────────────────────────────────────────────�?
�?        Azure Marketplace 部署架构                  �?
├─────────────────────────────────────────────────────�?
�?                                                    �?
�? ┌──────────────────�?       ┌──────────────────�?�?
�? �? Frontend Web App�?       �?Backend Web App  �?�?
�? �? (Node.js 18)    │◄──────►│ (Python 3.10)    �?�?
�? �? React SPA       �?HTTPS  �?FastAPI          �?�?
�? └──────────────────�?       └──────────────────�?�?
�?        �?                          �?             �?
�?        �?                          �?             �?
�?        �?   App Service Plan (B1)  �?             �?
�?        └───────────────────────────�?             �?
�?                                                    �?
�? ┌──────────────────────────────────────────────�?�?
�? �?        Azure 认知服务                        �?�?
�? �? �?OpenAI (GPT-4)                            �?�?
�? �? �?Speech Service (语音转文�?文本转语�?    �?�?
�? �? �?Computer Vision (图像分析)               �?�?
�? └──────────────────────────────────────────────�?�?
└─────────────────────────────────────────────────────�?
```

### 🌐 输出�?2 �?URL (符合 Marketplace 要求)

1. **前端应用 URL** (�?URL)
   - 格式: `https://mediagenie-web-xxxxxx.azurewebsites.net`
   - 用�? 用户访问�?Web 界面

2. **后端 API URL**
   - 格式: `https://mediagenie-api-xxxxxx.azurewebsites.net`
   - 用�? API 服务、健康检查、文�?

---

## 📋 前置要求

### 1. Azure 订阅
- 有效�?Azure 订阅
- 订阅中有足够的配额创�?Web App (B1 SKU)

### 2. Azure 认知服务密钥
确保你已经创建了以下服务并获取密�?

- **Azure OpenAI Service**
  - API Key
  - Endpoint (�? `https://your-openai.openai.azure.com/`)
  - Deployment Name (�? `gpt-4.1`)

- **Azure Speech Service**
  - API Key
  - Region (�? `eastus`)

- **Azure Computer Vision** (可�?
  - API Key
  - Endpoint

### 3. 本地环境 (可�?用于测试)
如果要在本地测试构建:
- Node.js 16+ (前端构建)
- Python 3.10+ (后端测试)

---

## 🚀 部署步骤

### 方式 1: Cloud Shell 自动部署 (推荐)

#### 步骤 1: 准备项目文件

1. 打开 Azure Portal: https://portal.azure.com
2. 点击右上角的 Cloud Shell 图标 (>_)
3. 选择 **Bash** 模式

#### 步骤 2: 上传项目�?Cloud Shell

```bash
# �?Cloud Shell 中创建工作目�?
mkdir -p ~/mediagenie
cd ~/mediagenie
```

**上传文件方式 A: 使用 Cloud Shell 上传功能**
1. 点击 Cloud Shell 工具栏的 "上传/下载文件" 图标
2. 选择本地项目文件夹中的以下内�?
   - `backend/` 文件�?
   - `frontend/` 文件�?
   - `deploy-marketplace-complete.sh` 脚本

**上传文件方式 B: 使用 Git (如果项目�?GitHub)**
```bash
git clone https://github.com/your-username/mediagenie.git
cd mediagenie
```

#### 步骤 3: 配置密钥

编辑部署脚本,替换你的实际密钥:

```bash
nano deploy-marketplace-complete.sh
```

修改以下变量:
```bash
AZURE_OPENAI_KEY="你的-OpenAI-密钥"
AZURE_OPENAI_ENDPOINT="https://你的-openai.openai.azure.com/"
AZURE_SPEECH_KEY="你的-Speech-密钥"
AZURE_SPEECH_REGION="eastus"
```

保存并退�?(Ctrl+O, Enter, Ctrl+X)

#### 步骤 4: 执行部署

```bash
# 添加执行权限
chmod +x deploy-marketplace-complete.sh

# 执行部署
./deploy-marketplace-complete.sh
```

#### 步骤 5: 等待部署完成

脚本会自动执行以下操�?
1. �?验证 Azure CLI 环境
2. �?生成唯一的应用名�?
3. �?创建资源�?
4. �?创建 App Service Plan (B1)
5. �?创建后端 Web App (Python)
6. �?配置后端环境变量�?CORS
7. �?部署后端代码
8. �?构建前端 React 应用
9. �?创建前端 Web App (Node.js)
10. �?部署前端静态文�?
11. �?验证部署健康状�?

**预计时间: 5-10 分钟**

---

### 方式 2: 本地构建 + 手动部署

如果 Cloud Shell �?Node.js 不可�?可以本地构建前端:

#### 本地构建前端

```bash
# 在本地项目目�?
cd frontend

# 创建生产环境配置 (临时,后续会被脚本覆盖)
echo "REACT_APP_MEDIA_SERVICE_URL=https://your-backend.azurewebsites.net" > .env.production

# 安装依赖
npm install

# 构建
npm run build
```

#### 压缩 build 文件�?

```powershell
# Windows PowerShell
Compress-Archive -Path frontend\build\* -DestinationPath frontend-build.zip
```

#### 上传�?Cloud Shell 并部�?

1. 上传 `frontend-build.zip` �?Cloud Shell
2. 修改脚本跳过前端构建步骤
3. 手动解压并部�?

---

## 🔍 部署后验�?

### 1. 检查后�?API

```bash
# 后端健康检�?
curl https://mediagenie-api-xxxxxx.azurewebsites.net/health

# 预期输出:
{
  "status": "healthy",
  "service": "MediaGenie API",
  "version": "1.0.0"
}
```

```bash
# 访问 API 文档
curl https://mediagenie-api-xxxxxx.azurewebsites.net/docs
```

### 2. 检查前端页�?

在浏览器中访�?
```
https://mediagenie-web-xxxxxx.azurewebsites.net
```

应该看到 MediaGenie 的登�?主页面�?

### 3. 测试前后端连�?

1. 打开前端 URL
2. 尝试使用功能 (�? 文本转语�?
3. 打开浏览器开发者工�?(F12)
4. 检�?Network 标签,确认请求发送到正确的后�?URL

### 4. 查看日志 (如果有问�?

```bash
# 查看后端日志
az webapp log tail \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG

# 查看前端日志
az webapp log tail \
  --name mediagenie-web-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

---

## 🛠�?常见问题排查

### 问题 1: 后端健康检查失�?(HTTP 500/503)

**原因**: 环境变量配置错误或依赖安装失�?

**解决方案**:
```bash
# 检查应用设�?
az webapp config appsettings list \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG

# 查看日志
az webapp log tail \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

### 问题 2: 前端 API 调用失败 (CORS 错误)

**原因**: CORS 配置未正确设�?

**解决方案**:
```bash
# 添加 CORS 允许�?
az webapp cors add \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --allowed-origins "https://mediagenie-web-xxxxxx.azurewebsites.net"

# 重启后端
az webapp restart \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

### 问题 3: 前端路由 404 错误

**原因**: web.config 未正确部�?

**解决方案**:
部署脚本已包�?web.config 创建,如果仍有问题:

1. 手动创建 `web.config` 文件
2. 重新部署前端

### 问题 4: B1 SKU 资源不足

**症状**: 部署时提示配额不�?

**解决方案**:
```bash
# 选项 1: 更换区域
LOCATION="westus"  # �?centralus, westeurope

# 选项 2: 升级�?B2
SKU="B2"

# 选项 3: 请求配额增加
# 访问 Azure Portal �?Support �?New support request
```

### 问题 5: 前端构建失败 (内存不足)

**症状**: `JavaScript heap out of memory`

**解决方案**:
```bash
# 增加 Node.js 内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

# 重新构建
npm run build
```

---

## 📊 资源成本估算

### B1 定价�?(推荐)

| 资源类型 | 数量 | 月费�?(USD) |
|---------|------|-------------|
| App Service Plan (B1) | 1 | ~$13 |
| Web App (前端) | 1 | 包含�?Plan �?|
| Web App (后端) | 1 | 包含�?Plan �?|
| Azure OpenAI (GPT-4) | - | 按使用量 |
| Azure Speech Service | - | 免费�?5小时/�?|
| **总计** | | ~$13-50/�?|

### 成本优化建议

1. **开�?测试环境**: 使用 F1 免费�?(有限�?
2. **生产环境**: B1 �?B2
3. **高流�?*: P1V2 + CDN

---

## 🔄 更新部署

### 更新后端代码

```bash
# 重新打包后端
cd backend
zip -r backend.zip .

# 上传
az webapp deployment source config-zip \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --src backend.zip
```

### 更新前端代码

```bash
# 重新构建
cd frontend
npm run build

# 打包
cd build
zip -r ../frontend.zip .

# 上传
az webapp deployment source config-zip \
  --name mediagenie-web-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --src frontend.zip
```

---

## 🧹 清理资源

### 删除所有部署的资源

```bash
# 删除整个资源�?(包含所有资�?
az group delete \
  --name MediaGenie-Marketplace-RG \
  --yes \
  --no-wait
```

### 仅删除特定资�?

```bash
# 删除前端 Web App
az webapp delete \
  --name mediagenie-web-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG

# 删除后端 Web App
az webapp delete \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

---

## 📚 相关文档

- [Azure App Service 文档](https://docs.microsoft.com/azure/app-service/)
- [Azure OpenAI Service](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Azure Speech Service](https://docs.microsoft.com/azure/cognitive-services/speech-service/)
- [Azure Marketplace 发布指南](https://docs.microsoft.com/azure/marketplace/)

---

## 🆘 获取帮助

### 技术支�?
- Azure 支持: https://azure.microsoft.com/support/
- GitHub Issues: https://github.com/your-repo/issues

### 联系方式
- 邮箱: support@mediagenie.com
- 文档: https://docs.mediagenie.com

---

## �?检查清�?

部署前确�?

- [ ] Azure 订阅已激�?
- [ ] OpenAI Service 密钥已获�?
- [ ] Speech Service 密钥已获�?
- [ ] 项目文件已上传到 Cloud Shell
- [ ] 部署脚本中的密钥已更�?
- [ ] 脚本有执行权�?(`chmod +x`)

部署后验�?

- [ ] 后端健康检查返�?200
- [ ] 前端页面可以访问
- [ ] API 文档页面可以打开
- [ ] 前端可以成功调用后端 API
- [ ] 语音转文本功能正�?
- [ ] 文本转语音功能正�?
- [ ] 图像分析功能正常
- [ ] GPT 聊天功能正常

---

## 📝 更新日志

### v1.0.0 (2025-10-22)
- �?初始版本
- �?前后端分离部�?
- �?支持 Azure Marketplace �?URL 要求
- �?修复资源不足问题 (B1 SKU)
- �?修复部署包完整性问�?
- �?修复 API 路径配置问题
- �?添加完整的错误处理和验证

---

**🎉 祝部署顺�?**
