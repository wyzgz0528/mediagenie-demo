# 🚀 MediaGenie 部署快速参�?

## 📦 部署�?
```
文件: mediagenie-deploy-20251023_220909.zip
大小: 0.63 MB
订阅: WYZ (3628daff-52ae-4f64-a310-28ad4b2158ca)
```

## �?快速部�?(5 分钟)

### 1️⃣ 上传�?Cloud Shell
```
1. 访问: https://portal.azure.com
2. 点击右上�?Cloud Shell 图标 (>_)
3. 选择 Bash 模式
4. 上传: mediagenie-deploy-20251023_220909.zip
```

### 2️⃣ 运行部署命令
```bash
unzip mediagenie-deploy-20251023_220909.zip -d mediagenie-deploy
cd mediagenie-deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 3️⃣ 等待完成 (5-10 分钟)
```
�?创建资源�?
�?创建 App Service Plan
�?部署后端 (Python FastAPI)
�?部署前端 (React)
�?配置环境变量
```

## 🔗 部署后获取的 URL

部署完成后复制这�?URL:

```
前端应用: https://mediagenie-web-XXXXX.azurewebsites.net
后端 API: https://mediagenie-api-XXXXX.azurewebsites.net
API 文档: https://mediagenie-api-XXXXX.azurewebsites.net/docs
健康检�? https://mediagenie-api-XXXXX.azurewebsites.net/health

Marketplace Landing Page: https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing
Marketplace Webhook: https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/webhook
```

## 🧪 快速验�?

```bash
# 1. 健康检�?
curl https://mediagenie-api-XXXXX.azurewebsites.net/health

# 2. 访问前端 (浏览�?
https://mediagenie-web-XXXXX.azurewebsites.net

# 3. 访问 API 文档 (浏览�?
https://mediagenie-api-XXXXX.azurewebsites.net/docs
```

## 🔧 Partner Center 配置

�?[Partner Center](https://partner.microsoft.com/dashboard) 填写:

| 字段 | �?|
|------|-----|
| Landing Page URL | `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing` |
| Connection Webhook | `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/webhook` |

## 📊 常用管理命令

```bash
# 查看日志
az webapp log tail --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX

# 重启应用
az webapp restart --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX

# 清理资源 (⚠️ 删除所�?
az group delete --name mediagenie-marketplace-XXXXX --yes --no-wait
```

## 🆘 常见问题

### Q: 部署失败?
```bash
# 查看详细日志
az webapp log tail --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX
```

### Q: 访问返回 503?
```bash
# 等待 2-3 分钟让应用完全启�?
# 然后重启
az webapp restart --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX
```

### Q: 前端无法连接后端?
```bash
# 检查环境变�?
az webapp config appsettings list --name mediagenie-web-XXXXX --resource-group mediagenie-marketplace-XXXXX | grep API_URL
```

## 📝 配置�?Azure 服务

所有服务密钥已预配�?

- �?Azure Speech Service (eastus)
- �?Azure Computer Vision (visiontest0925)
- �?Azure OpenAI (gpt-4.1)
- �?Azure Storage (mediagenie)

## 💰 成本估算

**B1 App Service Plan (基本�?**:
- 价格: ~$54.75 USD/�?
- 包含: 1 Core, 1.75 GB RAM
- 适合: 开发和测试环境

**生产环境建议**:
- 升级�?S1 标准�? ~$73.00 USD/�?
- 或使�?P1V2 高级�? ~$87.60 USD/�?

## ⏱️ 部署时间�?

```
00:00 - 上传部署�?(10-20�?
00:20 - 解压文件 (5�?
00:25 - 创建资源�?(10�?
00:35 - 创建 App Service Plan (30�?
01:05 - 创建后端 Web App (1分钟)
02:05 - 部署后端代码 (2分钟)
04:05 - 创建前端 Web App (1分钟)
05:05 - 部署前端代码 (2分钟)
07:05 - 应用启动和健康检�?(1分钟)
08:05 - �?部署完成!
```

## 📞 获取帮助

- 📖 完整指南: `AZURE_CLOUD_SHELL_DEPLOYMENT_GUIDE.md`
- 🌐 Azure Portal: https://portal.azure.com
- 📚 Azure 文档: https://docs.microsoft.com/azure
- 💬 Partner Center: https://partner.microsoft.com/dashboard

---

**准备好了�?** 开始部署吧! 🚀
