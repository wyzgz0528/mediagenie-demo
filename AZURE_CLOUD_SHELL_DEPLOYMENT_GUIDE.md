# 🚀 MediaGenie Azure Marketplace 部署指南

## 📦 部署包信�?

- **文件�?*: `mediagenie-deploy-20251023_220909.zip`
- **文件大小**: 0.63 MB
- **Azure 订阅**: WYZ (3628daff-52ae-4f64-a310-28ad4b2158ca)
- **部署方式**: Azure Cloud Shell + App Service

---

## 🎯 快速部署步�?

### 第一�?访问 Azure Cloud Shell

1. 打开浏览器访�?[Azure Portal](https://portal.azure.com)
2. 使用你的 Azure 账号登录
3. 点击页面右上角的 **Cloud Shell** 图标 `>_`

   ![Cloud Shell 图标位置](https://docs.microsoft.com/en-us/azure/cloud-shell/media/overview/overview-cloudshell-icon.png)

4. 如果是首次使�?选择 **Bash** 环境
5. 等待 Cloud Shell 初始化完�?

### 第二�?上传部署�?

1. �?Cloud Shell 工具�?点击 **上传/下载文件** 图标(文件�?箭头)
2. 选择 **上传**
3. 浏览并选择本地文件: `mediagenie-deploy-20251023_220909.zip`
4. 等待上传完成(�?10-20 �?

### 第三�?解压并部�?

�?Cloud Shell 中依次运行以下命�?

```bash
# 1. 解压部署�?
unzip mediagenie-deploy-20251023_220909.zip -d mediagenie-deploy

# 2. 进入部署目录
cd mediagenie-deploy

# 3. 赋予脚本执行权限
chmod +x scripts/deploy.sh

# 4. 开始部�?
./scripts/deploy.sh
```

### 第四�?等待部署完成

部署过程大约需�?**5-10 分钟**,会自动完�?

- �?创建资源�?
- �?创建 App Service Plan (B1 基本�?
- �?创建后端 Web App (Python 3.10)
- �?配置后端环境变量(包含所�?Azure 服务密钥)
- �?部署后端代码
- �?创建前端 Web App (Node.js 18)
- �?配置前端环境变量
- �?部署前端代码

---

## 🎉 部署成功信息

部署完成�?会显示类似以下信�?

```
🎉 ==========================================
🎉 MediaGenie 部署成功!
🎉 ==========================================

📱 访问地址:
   �?前端应用: https://mediagenie-web-20251023220909.azurewebsites.net
   �?后端 API: https://mediagenie-api-20251023220909.azurewebsites.net
   �?API 文档: https://mediagenie-api-20251023220909.azurewebsites.net/docs
   �?健康检�? https://mediagenie-api-20251023220909.azurewebsites.net/health

🔗 Azure Marketplace 集成:
   �?Landing Page: https://mediagenie-api-20251023220909.azurewebsites.net/marketplace/landing
   �?Webhook: https://mediagenie-api-20251023220909.azurewebsites.net/marketplace/webhook
```

**重要**: 请复制并保存这些 URL,后续配置需要使�?

---

## 🔗 Azure Marketplace Partner Center 配置

### 1. 技术配�?

�?[Partner Center](https://partner.microsoft.com/dashboard/marketplace-offers/overview) �?

1. 找到你的 MediaGenie SaaS Offer
2. 进入 **Technical Configuration**
3. 填写以下信息:

| 配置�?| �?| 示例 |
|--------|-----|------|
| Landing Page URL | `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing` | 从部署输出复�?|
| Connection Webhook | `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/webhook` | 从部署输出复�?|
| Azure Active Directory Tenant ID | 你的租户 ID | �?Azure Portal 查看 |
| Azure Active Directory Application ID | 你的应用 ID | �?Azure Portal 查看 |

4. 点击 **Save Draft**

### 2. 测试 Marketplace 集成

�?Cloud Shell 或本地终端运�?

```bash
# 1. 测试 Landing Page
curl https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing

# 2. 测试健康检�?
curl https://mediagenie-api-XXXXX.azurewebsites.net/health

# 3. 测试 API 文档
# 浏览器访�? https://mediagenie-api-XXXXX.azurewebsites.net/docs
```

---

## 🧪 验证部署

### 1. 基础健康检�?

```bash
curl https://mediagenie-api-XXXXX.azurewebsites.net/health
```

预期输出:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-23T22:09:12Z",
  "services": {
    "speech": "ok",
    "vision": "ok",
    "openai": "ok",
    "storage": "ok"
  }
}
```

### 2. 前端应用访问

在浏览器中访�?
```
https://mediagenie-web-XXXXX.azurewebsites.net
```

应该看到 MediaGenie 登录页面�?

### 3. API 文档访问

在浏览器中访�?
```
https://mediagenie-api-XXXXX.azurewebsites.net/docs
```

应该看到 FastAPI Swagger UI 文档�?

---

## 🔧 管理和维�?

### 查看应用日志

```bash
# 后端日志
az webapp log tail \
  --name mediagenie-api-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX

# 前端日志
az webapp log tail \
  --name mediagenie-web-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX
```

### 重启应用

```bash
# 重启后端
az webapp restart \
  --name mediagenie-api-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX

# 重启前端
az webapp restart \
  --name mediagenie-web-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX
```

### 更新环境变量

```bash
# 更新后端环境变量
az webapp config appsettings set \
  --name mediagenie-api-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX \
  --settings KEY=VALUE
```

### 扩展应用

```bash
# 升级�?B2 计划(更多内存�?CPU)
az appservice plan update \
  --name mediagenie-plan-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX \
  --sku B2
```

---

## 🗑�?清理资源

如果需要删除所有部署的资源:

```bash
# ⚠️ 警告:这将删除所有资�?无法恢复!
az group delete \
  --name mediagenie-marketplace-XXXXX \
  --yes \
  --no-wait
```

---

## 🆘 故障排除

### 问题 1: 部署脚本权限错误

**症状**: `permission denied: ./scripts/deploy.sh`

**解决方法**:
```bash
chmod +x scripts/deploy.sh
```

### 问题 2: 应用启动失败

**症状**: 访问 URL 返回 503 Service Unavailable

**解决方法**:
```bash
# 1. 查看日志
az webapp log tail --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX

# 2. 检查启动命�?
az webapp config show --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX

# 3. 重启应用
az webapp restart --name mediagenie-api-XXXXX --resource-group mediagenie-marketplace-XXXXX
```

### 问题 3: 前端无法连接后端

**症状**: 前端显示"网络错误"�?无法连接到服务器"

**解决方法**:
```bash
# 检查前端环境变�?
az webapp config appsettings list \
  --name mediagenie-web-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX \
  | grep REACT_APP_API_URL

# 应该显示正确的后�?URL
```

### 问题 4: Azure 配额不足

**症状**: 部署失败,提示"exceeded quota"

**解决方法**:
1. �?Azure Portal 中请求增加配�?
2. 或选择不同�?Azure 区域(�?West US, East US 2)
3. 修改脚本中的 `LOCATION` 变量

### 问题 5: Cloud Shell 存储空间不足

**症状**: 上传文件失败或解压失�?

**解决方法**:
```bash
# 清理 Cloud Shell 存储
df -h  # 查看空间使用
rm -rf ~/clouddrive/old-files  # 删除旧文�?
```

---

## 📊 部署架构

```
┌─────────────────────────────────────────────────────────────�?
�?                   Azure Marketplace                         �?
�?                 (Partner Center)                            �?
└─────────────────────┬───────────────────────────────────────�?
                      �?
                      �?Webhook/Landing Page
                      �?
┌─────────────────────▼───────────────────────────────────────�?
�?                Azure App Service Plan (B1)                  �?
�? ┌─────────────────────────�? ┌──────────────────────────�?�?
�? �?  Backend Web App       �? �?  Frontend Web App       �?�?
�? �?  (Python 3.10)         �? �?  (Node.js 18)           �?�?
�? �?                        �? �?                         �?�?
�? �?  FastAPI Application   │◄─�?  React Application     �?�?
�? �?  + Marketplace Router  �? �?  + Ant Design UI        �?�?
�? └──────────┬──────────────�? └──────────────────────────�?�?
└─────────────┼──────────────────────────────────────────────�?
              �?
              �?Azure SDK
              �?
┌─────────────▼──────────────────────────────────────────────�?
�?                  Azure Services                            �?
�? ┌──────────�? ┌──────────�? ┌──────────�? ┌───────────�?�?
�? �? Speech  �? �? Vision  �? �? OpenAI  �? �? Storage  �?�?
�? �? Service �? �? Service �? �? Service �? �? Account  �?�?
�? └──────────�? └──────────�? └──────────�? └───────────�?�?
└───────────────────────────────────────────────────────────�?
```

---

## 💡 最佳实�?

### 1. 环境变量管理
- �?所有敏感信息通过 Azure App Service Settings 配置
- �?不要在代码中硬编码密�?
- �?使用 Azure Key Vault 存储生产环境密钥

### 2. 日志和监�?
- �?启用 Application Insights 监控
- �?配置日志流转�?
- �?设置告警规则

### 3. 安全�?
- �?使用 HTTPS (Azure 自动配置)
- �?启用 Azure Active Directory 认证
- �?定期更新服务密钥

### 4. 性能优化
- �?使用 Azure CDN 加速静态资�?
- �?启用 App Service 自动缩放
- �?优化数据库查询和 API 调用

---

## 📞 支持和反�?

如果在部署过程中遇到问题:

1. 查看本文档的"故障排除"部分
2. 检�?Azure Portal 中的应用日志
3. 访问 [Azure 支持](https://azure.microsoft.com/support/)
4. 查看 [Azure App Service 文档](https://docs.microsoft.com/azure/app-service/)

---

## 📝 部署信息记录

部署完成�?请填写以下信息以备后�?

- **部署时间�?*: ____________________
- **资源组名�?*: mediagenie-marketplace-____________________
- **后端应用�?*: mediagenie-api-____________________
- **前端应用�?*: mediagenie-web-____________________
- **后端 URL**: https://______________________.azurewebsites.net
- **前端 URL**: https://______________________.azurewebsites.net
- **Landing Page URL**: https://______________________/marketplace/landing
- **Webhook URL**: https://______________________/marketplace/webhook

---

## �?下一步行动清�?

- [ ] 完成 Azure Cloud Shell 部署
- [ ] 验证所有服务健康状�?
- [ ] �?Partner Center 配置 Landing Page �?Webhook URL
- [ ] 测试 Marketplace 集成流程
- [ ] 配置自定义域�?可�?
- [ ] 启用 Application Insights 监控
- [ ] 设置 CI/CD 持续部署(可�?
- [ ] 提交 Marketplace Offer 审核

---

🎊 **恭喜!** 你现在已经拥有完整的 MediaGenie Azure Marketplace 部署指南。祝部署顺利!
