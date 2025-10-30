# MediaGenie Azure Marketplace 部署指南

## 项目概述
MediaGenie是一个基于Azure认知服务的多媒体内容智能管理平台，集成了�?
- 语音转文本服�?
- 文本转语音服�? 
- 图像分析服务
- GPT智能对话

## 部署准备
1. 精简的部署包已生成：`MediaGenie_Marketplace_Deploy.zip` (0.41MB)
2. 包含所有必要的文件和Azure ARM模板

## Cloud Shell 部署步骤

### 1. 上传部署�?
1. 打开 https://shell.azure.com
2. 点击顶部"上传/下载"图标
3. 上传 `MediaGenie_Marketplace_Deploy.zip`

### 2. 解压和准�?
```bash
unzip MediaGenie_Marketplace_Deploy.zip
cd MediaGenie_Marketplace_Deploy
chmod +x deploy_cloudshell.sh
```

### 3. 执行部署
```bash
./deploy_cloudshell.sh
```

部署脚本将自动创建：
- Azure Container Registry (ACR)
- App Service Plan (Linux B1)
- Web App for Containers (后端API)
- Storage Account (前端静态网�?

### 4. 等待部署完成
部署大约需�?-10分钟，完成后将显示：
- 后端API地址：`https://mediagenie-api-xxxxx.azurewebsites.net`
- 前端访问地址：`https://storagexxxxxxx.z13.web.core.windows.net`

## Marketplace 发布准备

### ARM 模板位置
- 主模板：`azure-deploy/mainTemplate.json`
- UI定义：`azure-deploy/createUiDefinition.json`
- 清单文件：`azure-marketplace/manifest.json`

### 所需Azure服务密钥
部署时需要提供：
1. Azure Speech Services API Key
2. Azure Computer Vision API Key  
3. Azure OpenAI API Key

### 成本估算（中国东部）
- App Service Plan B1：约�?20/�?
- Storage Account：约�?0/�?
- Container Registry：约�?5/�?
- **总计约￥155/�?*

## 测试验证

### 后端健康检�?
```bash
curl https://你的后端地址.azurewebsites.net/health
```
预期返回：`{"status": "healthy"}`

### 前端功能测试
1. 访问前端地址
2. 测试语音转文本功�?
3. 测试文本转语音功�?
4. 测试图像分析功能
5. 测试GPT对话功能

## 故障排除

### 常见问题
1. **容器启动失败**：检查ACR凭据和镜像构�?
2. **API调用失败**：确认Azure服务密钥配置正确
3. **前端空白�?*：检查静态网站配置和文件上传

### 日志查看
```bash
# 查看Web App日志
az webapp log tail --name 你的应用�?--resource-group MediaGenie
```

## 下一�?
1. �?项目精简完成
2. �?部署包生成完�?(0.41MB)
3. �?ARM模板准备完成
4. 🔄 **现在可以上传到Cloud Shell进行部署测试**
5. �?测试完成后可提交Azure Marketplace审核

---

**部署包已优化�?.41MB，可直接上传到Cloud Shell进行一键部署！**