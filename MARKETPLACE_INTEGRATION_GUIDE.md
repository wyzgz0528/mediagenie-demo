# 🏪 Azure Marketplace 集成完整指南

## 📋 概述

本文档提�?MediaGenie �?Azure Marketplace 集成的完整配置指�?包括 **Landing Page** �?**Connection Webhook** 的实现和配置�?

---

## 🎯 Azure Marketplace 必需的端�?

### 1. Landing Page URL (必需)
**用�?*: 用户�?Marketplace 购买后首次访问的页面

**URL**: `https://your-backend.azurewebsites.net/marketplace/landing`

**功能**:
- 欢迎新用�?
- 显示订阅信息
- 引导用户完成设置
- 激活订�?

### 2. Connection Webhook URL (必需)
**用�?*: 接收 Marketplace 订阅生命周期事件

**URL**: `https://your-backend.azurewebsites.net/marketplace/webhook`

**功能**:
- 接收订阅事件 (购买、取消、变更等)
- 验证请求签名
- 更新订阅状�?
- 触发业务逻辑

---

## 🚀 已实现的功能

### �?Landing Page (`/marketplace/landing`)

#### 功能特�?
- �?美观的欢迎页�?
- �?显示订阅信息 (token, subscription_id)
- �?快速开始步骤引�?
- �?直接链接到应用主页和文档
- �?响应式设�?移动端友�?

#### 查询参数
```
GET /marketplace/landing?token=<marketplace-token>&subscription_id=<sub-id>
```

- `token`: Marketplace 提供的临时令�?
- `subscription_id`: 订阅 ID

#### 示例访问
```bash
# 测试访问
curl https://your-backend.azurewebsites.net/marketplace/landing

# 带参数访�?
curl "https://your-backend.azurewebsites.net/marketplace/landing?token=abc123&subscription_id=sub-001"
```

---

### �?Connection Webhook (`/marketplace/webhook`)

#### 支持的事件类�?
- `Subscribe` - 新订阅创�?
- `Unsubscribe` - 订阅取消
- `ChangePlan` - 更改订阅计划
- `ChangeQuantity` - 更改订阅数量
- `Suspend` - 暂停订阅
- `Reinstate` - 恢复订阅

#### 请求格式
```json
{
  "action": "Subscribe",
  "subscriptionId": "sub-123",
  "planId": "basic",
  "quantity": 1,
  "customerId": "customer-456",
  "customerEmail": "user@example.com",
  "timestamp": "2025-10-22T10:00:00Z"
}
```

#### 响应格式
```json
{
  "status": "success",
  "message": "Event Subscribe processed successfully",
  "subscription_id": "sub-123"
}
```

#### 测试 Webhook
```bash
# 测试订阅事件
curl -X POST https://your-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "action": "Subscribe",
    "subscriptionId": "test-sub-001",
    "planId": "basic",
    "quantity": 1,
    "customerId": "test-customer",
    "customerEmail": "test@example.com"
  }'
```

---

## 📊 管理端点

### 查看所有订�?
```bash
GET /marketplace/subscriptions

# 示例
curl https://your-backend.azurewebsites.net/marketplace/subscriptions
```

### 查看特定订阅
```bash
GET /marketplace/subscriptions/{subscription_id}

# 示例
curl https://your-backend.azurewebsites.net/marketplace/subscriptions/sub-123
```

### 查看事件日志
```bash
GET /marketplace/events?limit=50

# 示例
curl https://your-backend.azurewebsites.net/marketplace/events
```

### 健康检�?
```bash
GET /marketplace/health

# 示例
curl https://your-backend.azurewebsites.net/marketplace/health
```

---

## 🔧 �?Partner Center 中配�?

### 步骤 1: 登录 Partner Center

1. 访问: https://partner.microsoft.com/dashboard
2. 选择 **Marketplace offers**
3. 找到你的 MediaGenie offer

### 步骤 2: 配置技术配�?

导航�? **Offer setup** �?**Technical configuration**

#### Landing Page URL
```
https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/landing
```

**说明**: 替换 `mediagenie-api-xxxxxx` 为你的实际后�?Web App 名称�?

#### Connection Webhook
```
https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/webhook
```

#### Azure Active Directory Tenant ID
```
你的 Azure AD Tenant ID (�?Azure Portal 获取)
```

#### Azure Active Directory Application ID
```
你的应用注册 ID (�?Azure AD 获取)
```

### 步骤 3: 配置 Webhook 密钥 (生产必需)

1. �?Partner Center 生成共享密钥
2. 将密钥存储到 Azure Key Vault
3. 配置环境变量:
   ```bash
   MARKETPLACE_WEBHOOK_SECRET=your-shared-secret
   ```

---

## 🔐 安全性配�?

### Webhook 签名验证 (生产必需)

#### 1. 获取共享密钥

�?Partner Center �?Technical Configuration �?Connection Webhook 中生成�?

#### 2. 存储�?Key Vault

```bash
az keyvault secret set \
  --vault-name your-keyvault \
  --name MarketplaceWebhookSecret \
  --value "your-shared-secret"
```

#### 3. 配置 Web App

```bash
az webapp config appsettings set \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --settings \
    MARKETPLACE_WEBHOOK_SECRET="@Microsoft.KeyVault(SecretUri=https://your-kv.vault.azure.net/secrets/MarketplaceWebhookSecret/)"
```

#### 4. 启用签名验证

�?`marketplace.py` 中启�?`verify_signature()` 函数:

```python
def verify_signature(body: bytes, signature: str) -> bool:
    shared_secret = os.getenv("MARKETPLACE_WEBHOOK_SECRET")
    expected_signature = hmac.new(
        shared_secret.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature, expected_signature)
```

---

## 📝 订阅生命周期流程

### 1. 新订�?(Subscribe)

```mermaid
sequenceDiagram
    用户->>Marketplace: 购买 MediaGenie
    Marketplace->>Webhook: POST /webhook (Subscribe)
    Webhook->>Database: 创建订阅记录
    Webhook->>Marketplace: 返回 200 OK
    Marketplace->>浏览�? 重定向到 Landing Page
    浏览�?>>Landing Page: GET /landing?token=xxx
    Landing Page->>用户: 显示欢迎页面
    用户->>应用: 点击 "开始使�?
    应用->>用户: 开始使用服�?
```

### 2. 取消订阅 (Unsubscribe)

```mermaid
sequenceDiagram
    用户->>Marketplace: 取消订阅
    Marketplace->>Webhook: POST /webhook (Unsubscribe)
    Webhook->>Database: 更新订阅状�?
    Webhook->>Application: 禁用用户访问
    Webhook->>Marketplace: 返回 200 OK
```

---

## 🧪 测试指南

### 本地测试

#### 1. 启动服务
```bash
cd backend/media-service
python main.py
```

#### 2. 测试 Landing Page
```bash
# 浏览器访�?
http://localhost:8000/marketplace/landing?token=test123&subscription_id=sub-test
```

#### 3. 测试 Webhook
```bash
curl -X POST http://localhost:8000/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "action": "Subscribe",
    "subscriptionId": "local-test-001",
    "planId": "basic",
    "quantity": 1,
    "customerId": "test-customer"
  }'
```

### 生产测试

#### 1. 使用 Partner Center 测试工具

Partner Center �?Technical Configuration �?**Test publish**

#### 2. 手动测试

```bash
# Landing Page
curl "https://your-backend.azurewebsites.net/marketplace/landing?token=test&subscription_id=test"

# Webhook
curl -X POST https://your-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"action":"Subscribe","subscriptionId":"prod-test-001","planId":"basic","quantity":1}'
```

#### 3. 查看日志

```bash
az webapp log tail \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

---

## 📊 监控和日�?

### 查看订阅统计

```bash
curl https://your-backend.azurewebsites.net/marketplace/subscriptions
```

**响应示例**:
```json
{
  "total": 5,
  "subscriptions": [
    {
      "subscription_id": "sub-001",
      "plan_id": "basic",
      "quantity": 1,
      "customer_id": "customer-123",
      "status": "Subscribed",
      "created_at": "2025-10-22T10:00:00Z"
    }
  ]
}
```

### 查看事件日志

```bash
curl https://your-backend.azurewebsites.net/marketplace/events?limit=20
```

**响应示例**:
```json
{
  "total": 15,
  "events": [
    {
      "event": "webhook_received",
      "event_type": "Subscribe",
      "subscription_id": "sub-001",
      "timestamp": "2025-10-22T10:00:00Z"
    }
  ]
}
```

---

## 🔄 Webhook 重试策略

Azure Marketplace 会在以下情况重试 Webhook:

- HTTP 5xx 错误
- 网络超时
- 无响�?

**重试间隔**: 
1. 立即
2. 1分钟�?
3. 5分钟�?
4. 15分钟�?
5. 1小时�?

**建议**: 确保 Webhook 处理�?*幂等�?*(多次执行相同结果)�?

---

## 🛠�?故障排查

### 问题 1: Landing Page 无法访问

**症状**: 404 错误

**解决方案**:
```bash
# 检查路由是否注�?
curl https://your-backend.azurewebsites.net/marketplace/health

# 查看日志
az webapp log tail -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG
```

### 问题 2: Webhook 未收到事�?

**症状**: Marketplace 报告 Webhook 失败

**解决方案**:
```bash
# 1. 验证 URL 可访�?
curl -X POST https://your-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"action":"Subscribe","subscriptionId":"test"}'

# 2. 检查防火墙规则
az webapp config access-restriction show \
  -n mediagenie-api-xxxxxx \
  -g MediaGenie-Marketplace-RG

# 3. 检�?HTTPS 证书
openssl s_client -connect your-backend.azurewebsites.net:443
```

### 问题 3: 签名验证失败

**症状**: Webhook 返回 401 Unauthorized

**解决方案**:
```bash
# 检查密钥是否正确配�?
az webapp config appsettings list \
  -n mediagenie-api-xxxxxx \
  -g MediaGenie-Marketplace-RG \
  --query "[?name=='MARKETPLACE_WEBHOOK_SECRET']"

# 重新生成和配置密�?
# 1. Partner Center �?重新生成
# 2. 更新 Key Vault
# 3. 重启 Web App
```

---

## �?发布前检查清�?

### Partner Center 配置
- [ ] Landing Page URL 已配�?
- [ ] Connection Webhook URL 已配�?
- [ ] Azure AD Tenant ID 已填�?
- [ ] Azure AD Application ID 已注�?
- [ ] Webhook 共享密钥已生�?

### 端点测试
- [ ] Landing Page 可访�?(200 OK)
- [ ] Webhook 接受 POST 请求
- [ ] 签名验证正常工作
- [ ] 所有事件类型正确处�?
- [ ] HTTPS 证书有效

### 安全�?
- [ ] Webhook 密钥存储�?Key Vault
- [ ] 启用签名验证
- [ ] HTTPS Only 已启�?
- [ ] CORS 正确配置

### 监控
- [ ] 日志记录正常
- [ ] 健康检查端点响�?
- [ ] 订阅管理端点可访�?

---

## 📚 相关文档

- [Azure Marketplace Documentation](https://docs.microsoft.com/azure/marketplace/)
- [SaaS Fulfillment APIs](https://docs.microsoft.com/azure/marketplace/partner-center-portal/pc-saas-fulfillment-api-v2)
- [Webhook Best Practices](https://docs.microsoft.com/azure/marketplace/partner-center-portal/pc-saas-fulfillment-webhook)

---

## 🆘 获取帮助

### 技术支�?
- Partner Center 支持: https://partner.microsoft.com/support
- Azure 支持: https://azure.microsoft.com/support/

### 有用的命�?

```bash
# 查看后端日志
az webapp log tail -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG

# 重启后端
az webapp restart -n mediagenie-api-xxxxxx -g MediaGenie-Marketplace-RG

# 测试 Landing Page
curl "https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/landing"

# 测试 Webhook
curl -X POST https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"action":"Subscribe","subscriptionId":"test-001","planId":"basic","quantity":1}'

# 查看订阅
curl https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/subscriptions

# 查看事件日志
curl https://mediagenie-api-xxxxxx.azurewebsites.net/marketplace/events
```

---

## 🎉 总结

你的 MediaGenie 应用现在包含完整�?Azure Marketplace 集成:

�?**Landing Page** - 欢迎新用户并引导设置  
�?**Connection Webhook** - 接收并处理订阅事�? 
�?**订阅管理** - 查看和管理所有订�? 
�?**事件日志** - 审计所�?Marketplace 事件  
�?**安全�?* - 支持签名验证�?Key Vault  

**现在可以�?Partner Center 中配置这些端点并发布�?Azure Marketplace! 🚀**
