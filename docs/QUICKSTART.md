# MediaGenie Azure Marketplace SaaS 集成 - 快速开始指�?

> 📚 **完整文档**: 请先阅读 `AZURE_MARKETPLACE_SAAS_IMPLEMENTATION_GUIDE.md`  
> ⏱️ **预计时间**: 5-7 个工作日  
> 🎯 **目标**: �?MediaGenie 部署为可交易�?Azure Marketplace SaaS 产品

---

## 📋 前置条件检查清�?

在开始之�?确保已完�?

- [ ] Azure 订阅 (用于开发和测试)
- [ ] Partner Center 账号 (已启用商业市�?
- [ ] SaaS Offer 已在 Partner Center 创建
- [ ] PostgreSQL 数据�?(已部�?
- [ ] Azure App Service (backend, frontend, marketplace-portal)
- [ ] 现有 Azure Cognitive Services 配置 (OpenAI, Speech, Vision)

---

## 🚀 Phase 1: Azure AD 应用注册 (1小时)

### 步骤 1: 创建 Azure AD 应用

```bash
# 登录 Azure Portal
https://portal.azure.com

# 导航�?Azure Active Directory �?App registrations �?New registration
```

**配置信息**:
```
Name: MediaGenie-Production
Supported account types: Multitenant (任何组织目录中的账户)
Redirect URI:
  - Web: https://mediagenie-backend.azurewebsites.net/auth/callback
  - SPA: https://mediagenie-frontend.azurewebsites.net
```

### 步骤 2: 配置 API 权限

```
进入应用 �?API permissions �?Add a permission
  �?Microsoft Graph �?Delegated permissions
  �?勾�? User.Read, email, profile, openid
  �?Grant admin consent (管理员同�?
```

### 步骤 3: 创建 Client Secret

```
进入应用 �?Certificates & secrets �?New client secret
  描述: MediaGenie-Backend-Secret
  过期时间: 24 months
  
⚠️ 记录 Secret Value (只显示一�?
```

### 步骤 4: 更新 .env 配置

在项目根目录�?`.env` 文件中添�?

```bash
# Azure AD 配置
AZURE_AD_TENANT_ID=<你的 Tenant ID>
AZURE_AD_CLIENT_ID=<你的 Application (client) ID>
AZURE_AD_CLIENT_SECRET=<你的 Client Secret>
AZURE_AD_AUTHORITY=https://login.microsoftonline.com/<Tenant ID>

# Marketplace API 配置
MARKETPLACE_API_BASE_URL=https://marketplaceapi.microsoft.com/api
MARKETPLACE_API_VERSION=2018-08-31
```

---

## 🗄�?Phase 2: 数据库迁�?(30分钟)

### 步骤 1: 连接到数据库

```bash
# 使用 Azure Portal �?Cloud Shell 或本�?psql 客户�?
psql "postgresql://user:password@host:5432/mediagenie?sslmode=require"
```

### 步骤 2: 执行迁移脚本

```bash
# 在项目目录中
cd backend/media-service

# 执行迁移
psql $DATABASE_URL -f migrations/001_marketplace_tables.sql
```

### 步骤 3: 验证表创�?

```sql
-- 列出新创建的�?
\dt

-- 应该看到:
-- users
-- subscriptions
-- user_subscriptions
-- webhook_events

-- 验证视图
\dv

-- 应该看到:
-- v_user_subscriptions
-- v_active_subscriptions
```

---

## 💻 Phase 3: 部署新代�?(2小时)

### 步骤 1: 安装新依�?

```bash
cd backend/media-service

# 激活虚拟环�?
python -m venv venv
source venv/bin/activate  # Linux/Mac
# �?
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt
```

### 步骤 2: 本地测试 (可�?

```bash
# 设置环境变量
export DATABASE_URL="postgresql+asyncpg://..."
export AZURE_AD_TENANT_ID="..."
export AZURE_AD_CLIENT_ID="..."
export AZURE_AD_CLIENT_SECRET="..."

# 启动服务
uvicorn main:app --reload --port 8000

# 测试健康检�?
curl http://localhost:8000/health
curl http://localhost:8000/marketplace/webhook/health
```

### 步骤 3: 部署�?Azure

#### 方法 A: ZIP 部署 (推荐)

```powershell
# �?PowerShell 中执�?
cd backend/media-service

# 打包
Compress-Archive -Path * -DestinationPath backend-api.zip -Force

# 部署
az webapp deployment source config-zip `
  --resource-group MediaGenie-RG `
  --name mediagenie-backend `
  --src backend-api.zip
```

#### 方法 B: VS Code 部署

1. 安装 Azure App Service 扩展
2. 右键点击 `backend/media-service` 文件�?
3. 选择 "Deploy to Web App..."
4. 选择 `mediagenie-backend`

### 步骤 4: 配置启动命令

```bash
# �?Azure Portal �?Azure CLI 中设�?
az webapp config set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --startup-file "gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind=0.0.0.0:8000 --timeout 600"
```

### 步骤 5: 配置环境变量

�?Azure Portal �?App Service 配置中添加所有环境变�?(参考技术文档第 9 �?

---

## 🏗�?Phase 4: Partner Center 配置 (30分钟)

### 步骤 1: 配置 Technical Configuration

```
登录 Partner Center: https://partner.microsoft.com/dashboard

进入 SaaS Offer �?Technical configuration

填写:
  Landing page URL: https://mediagenie-marketplace-portal.azurewebsites.net/landing
  Connection webhook: https://mediagenie-backend.azurewebsites.net/marketplace/webhook
  Azure Active Directory tenant ID: <上面�?Tenant ID>
  Azure Active Directory application ID: <上面�?Client ID>
  
保存草稿
```

### 步骤 2: 配置 Plans and Pricing

```
创建至少 3 个计�?

1. Basic Plan
   - Plan ID: basic
   - 价格: $29/month
   - 功能: 基础媒体处理功能

2. Standard Plan
   - Plan ID: standard
   - 价格: $99/month
   - 功能: 完整功能 + 更高配额

3. Premium Plan
   - Plan ID: premium
   - 价格: $299/month
   - 功能: 所有功�?+ 企业支持
```

---

## 🧪 Phase 5: 测试验证 (2小时)

### 测试 1: Azure AD 登录

```bash
# 1. 访问前端
https://mediagenie-frontend.azurewebsites.net

# 2. 点击"登录"按钮
# 3. 应该重定向到 Microsoft 登录页面
# 4. 登录后应该显示用户名

# 5. 检�?API 调用
# 打开浏览器开发者工�?�?Network
# 应该看到 API 请求携带 Authorization: Bearer <token>
```

### 测试 2: Landing Page 流程

```bash
# 1. �?Partner Center 创建测试购买
# 2. 应该重定向到 Landing Page 并携�?token �?subscription_id
# 3. Landing Page 应该显示订阅详情
# 4. 点击"激�?按钮
# 5. 应该成功激活并重定向到主应�?

# 6. 验证数据�?
psql $DATABASE_URL -c "SELECT subscription_id, status FROM subscriptions;"
# 应该看到状态为 'Subscribed'
```

### 测试 3: Webhook 接收

```bash
# 使用 curl 模拟 Marketplace Webhook
curl -X POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -H "x-ms-marketplace-token: test-signature" \
  -d '{
    "id": "test-event-1",
    "activityId": "test-activity-1",
    "subscriptionId": "test-sub-123",
    "offerId": "mediagenie",
    "publisherId": "your-publisher-id",
    "planId": "standard",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'

# 应该返回: {"status": "accepted", ...}

# 验证数据�?
psql $DATABASE_URL -c "SELECT event_id, event_type, processing_status FROM webhook_events;"
```

### 测试 4: 订阅状态同�?

```bash
# 测试 SaaS API 调用 (使用 Python)
python3 << EOF
import asyncio
from saas_fulfillment_client import get_saas_client

async def test():
    client = get_saas_client()
    
    # 列出所有订�?
    subscriptions = await client.list_subscriptions()
    print(f"Found {len(subscriptions)} subscriptions")
    
    for sub in subscriptions:
        print(f"  - {sub.id}: {sub.saas_subscription_status}")

asyncio.run(test())
EOF
```

---

## 📊 Phase 6: 监控和日�?(1小时)

### 配置 Application Insights

```bash
# �?Azure Portal 创建 Application Insights

# 获取连接字符�?
az monitor app-insights component show \
  --app mediagenie-appinsights \
  --resource-group MediaGenie-RG \
  --query connectionString

# 添加�?App Service 环境变量
APPLICATIONINSIGHTS_CONNECTION_STRING=<连接字符�?
```

### 查看日志

```bash
# 实时日志�?
az webapp log tail \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend

# 或在 Azure Portal
App Service �?Log stream
```

---

## �?完成检查清�?

部署完成�?确认以下项目:

- [ ] Azure AD 应用已创建并配置
- [ ] 数据库迁移已成功执行
- [ ] Backend 服务正常运行 (`/health` 返回 200)
- [ ] Webhook 端点可访�?(`/marketplace/webhook/health` 返回 200)
- [ ] Partner Center Technical Configuration 已填�?
- [ ] 测试购买流程成功 (Landing Page �?Activate)
- [ ] Webhook 事件正常接收和处�?
- [ ] Azure AD 登录流程正常
- [ ] API 请求携带正确�?JWT token
- [ ] Application Insights 收集到日�?

---

## 🐛 常见问题排查

### 问题 1: Token 验证失败 (401 Unauthorized)

```bash
# 检�?Azure AD 配置
echo "Tenant ID: $AZURE_AD_TENANT_ID"
echo "Client ID: $AZURE_AD_CLIENT_ID"

# 验证 JWKS 端点
curl https://login.microsoftonline.com/$AZURE_AD_TENANT_ID/discovery/v2.0/keys

# 检�?token 内容
# 访问 https://jwt.io/ 粘贴 token 查看 claims
```

### 问题 2: Resolve API 返回 404

```bash
# 检�?Service Principal Token
# 查看日志中是否有 "Access token obtained" 消息

# 验证 Marketplace token 是否有效
# Marketplace token 只能使用一�?重新创建测试购买
```

### 问题 3: Webhook 未触�?

```bash
# 1. 检�?Webhook URL 是否可访�?
curl https://mediagenie-backend.azurewebsites.net/marketplace/webhook/health

# 2. 查看 App Service 日志
az webapp log tail --resource-group MediaGenie-RG --name mediagenie-backend

# 3. �?Partner Center 查看 Webhook 调用历史
# Offer �?Technical configuration �?Webhook logs
```

### 问题 4: 数据库连接失�?

```bash
# 测试数据库连�?
psql $DATABASE_URL -c "SELECT 1;"

# 检查连接字符串格式
# 应该�? postgresql+asyncpg://user:pass@host:5432/dbname?sslmode=require
```

---

## 📞 获取帮助

遇到问题�?

1. **查看完整文档**: `AZURE_MARKETPLACE_SAAS_IMPLEMENTATION_GUIDE.md`
2. **检查日�?*: Azure Portal �?App Service �?Log stream
3. **参考代码注�?*: 所有生成的代码都包含详细注�?
4. **Azure 支持**: https://azure.microsoft.com/support/
5. **Partner Center 支持**: https://partner.microsoft.com/support

---

## 🎓 学习资源

- [Azure Marketplace SaaS Offer 文档](https://learn.microsoft.com/en-us/azure/marketplace/plan-saas-offer)
- [SaaS Fulfillment API v2](https://learn.microsoft.com/en-us/azure/marketplace/partner-center-portal/pc-saas-fulfillment-api-v2)
- [Azure AD 认证](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [Mastering the Marketplace - SaaS](https://aka.ms/MasteringTheMarketplace/saas-accelerator)

---

## 🎉 恭喜!

如果您完成了所有步�?MediaGenie 现在已经是一个完整的 Azure Marketplace SaaS 产品!

**下一�?*:
1. �?Partner Center 提交 Offer 审核
2. 完善用户文档和支持流�?
3. 配置监控和告�?
4. 准备市场推广材料

**部署版本**: v1.0  
**最后更�?*: 2025�?0�?7�?
