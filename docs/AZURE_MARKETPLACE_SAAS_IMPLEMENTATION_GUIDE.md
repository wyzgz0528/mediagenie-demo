# Azure Marketplace SaaS 集成技术实施指�?

> **项目**: MediaGenie - Azure Marketplace SaaS 部署  
> **日期**: 2025�?0�?7�? 
> **技术栈**: Python 3.11 + FastAPI + React + PostgreSQL  
> **目标**: 实现完整�?Azure Marketplace 可交�?SaaS 产品

---

## 📋 目录

1. [概述](#概述)
2. [架构设计](#架构设计)
3. [核心功能模块](#核心功能模块)
4. [实施步骤](#实施步骤)
5. [数据库设计](#数据库设�?
6. [API 集成流程](#api-集成流程)
7. [安全性配置](#安全性配�?
8. [测试验证](#测试验证)
9. [部署清单](#部署清单)
10. [常见问题](#常见问题)

---

## 概述

### 🎯 实施目标

�?MediaGenie �?*演示模式**升级�?*生产�?Azure Marketplace SaaS 产品**,实现:

- �?**Azure AD 单点登录 (SSO)**: 用户通过 Microsoft 账号登录
- �?**订阅生命周期管理**: Resolve �?Activate �?Update �?Cancel �?Delete
- �?**Webhook 事件处理**: 实时接收订阅状态变�?
- �?**多租户数据隔�?*: 按用�?订阅分离数据
- �?**计量计费集成**: 支持按用量计�?可�?

### 📊 当前状�?vs 目标状�?

| 功能 | 当前状�?| 目标状�?|
|------|---------|---------|
| 用户认证 | �?Mock 演示用户 | �?Azure AD OAuth 2.0 |
| 订阅管理 | �?内存存储 | �?PostgreSQL + SaaS API |
| Landing Page | ⚠️ 静�?HTML | �?动态激活流�?|
| Webhook | ⚠️ 空实�?| �?签名验证 + 事件处理 |
| 数据隔离 | ⚠️ �?userId 字段 | �?多租户架�?|

### ⏱️ 预计工期

- **Phase 1 - 认证基础** (2�?: Azure AD 注册 + JWT 中间�?
- **Phase 2 - SaaS API** (2�?: Fulfillment API 客户�?
- **Phase 3 - 订阅流程** (2�?: Landing Page + Webhook
- **Phase 4 - 测试部署** (1�?: 集成测试 + 上线准备

**总计**: 5-7 个工作日

---

## 架构设计

### 🏗�?系统架构�?

```
┌──────────────────────────────────────────────────────────────�?
�?                 Azure Marketplace Portal                     �?
�? (用户�?Azure Portal �?AppSource 购买 MediaGenie)          �?
└────────────────────┬─────────────────────────────────────────�?
                     �?
                     �?�?重定向到 Landing Page
                     �?   (token + subscription_id)
                     �?
┌──────────────────────────────────────────────────────────────�?
�?             Marketplace Portal (Flask)                       �?
�? - 接收 token + subscription_id                               �?
�? - 调用 SaaS API Resolve (获取订阅详情)                      �?
�? - 创建用户账号 (Azure AD 信息)                               �?
�? - 显示激活页�?                                              �?
└────────────────────┬─────────────────────────────────────────�?
                     �?
                     �?�?Activate 订阅
                     �?
┌────────────────────↓─────────────────────────────────────────�?
�?        Azure Marketplace SaaS Fulfillment API v2             �?
�? - Resolve: 解析 token,获取订阅信息                          �?
�? - Activate: 激活订�?使其可用                               �?
�? - Update: 变更计划或数�?                                    �?
�? - Delete: 取消订阅                                           �?
└────────────────────┬─────────────────────────────────────────�?
                     �?
                     �?�?Webhook 通知
                     �?   (订阅状态变�?
                     �?
┌──────────────────────────────────────────────────────────────�?
�?             Backend Service (FastAPI)                        �?
�? - 接收 Webhook 事件                                          �?
�? - 验证签名 (HMAC-SHA256)                                     �?
�? - 更新订阅状态到数据�?                                      �?
�? - 控制用户访问权限                                           �?
└────────────────────┬─────────────────────────────────────────�?
                     �?
                     �?�?用户登录使用
                     �?
┌────────────────────↓─────────────────────────────────────────�?
�?               Frontend (React)                               �?
�? - Azure AD MSAL.js 登录                                      �?
�? - 获取 JWT token                                             �?
�? - 调用 Backend API (�?Authorization header)                �?
�? - 检查订阅状�?控制功能访问                                  �?
└──────────────────────────────────────────────────────────────�?
```

### 🔄 订阅生命周期流程

```
用户�?Marketplace 购买
         �?
    PendingFulfillmentStart (待激�?
         �?
    重定向到 Landing Page
         �?
    调用 Resolve API (解析 token)
         �?
    显示订阅详情,用户确认
         �?
    调用 Activate API (激活订�?
         �?
    Subscribed (已激�?
         �?
    用户可以使用 MediaGenie
         �?
    ┌─────────────┬─────────────�?
    �?            �?            �?
变更计划     续费成功      取消订阅
    �?            �?            �?
  Update      Webhook:     Webhook:
  API        Renew         Unsubscribe
    �?            �?            �?
    └─────────────┴─────────────�?
                  �?
            最终状态更�?
```

---

## 核心功能模块

### 1️⃣ Azure AD 认证模块

**文件**: `backend/media-service/auth_middleware.py`

**功能**:
- 验证 JWT token (�?Azure AD 签发)
- 提取用户身份信息 (oid, sub, email)
- 实现 FastAPI Dependency 注入
- Token 刷新机制

**技术要�?*:
```python
# 使用 PyJWT 验证 Azure AD token
# �?Azure AD JWKS 端点获取公钥
# 验证 issuer, audience, expiry
# 提取 claims: oid (用户ID), email, name
```

### 2️⃣ SaaS Fulfillment API 客户�?

**文件**: `backend/media-service/saas_fulfillment_client.py`

**功能**:
- **Resolve API**: 解析 marketplace token,获取订阅详情
- **Activate API**: 激活订�?使其可计�?
- **Update API**: 变更订阅计划或数�?
- **Delete API**: 取消订阅
- **Get Subscription**: 查询订阅状�?

**技术要�?*:
```python
# 使用 Azure AD Service Principal 认证
# 调用 https://marketplaceapi.microsoft.com/api/saas/subscriptions
# 实现重试机制 (指数退�?
# 错误处理和日志记�?
```

### 3️⃣ Webhook 处理�?

**文件**: `backend/media-service/marketplace_webhook.py`

**功能**:
- 接收订阅事件: Subscribe, Unsubscribe, ChangePlan, ChangeQuantity, Suspend, Reinstate
- 验证 webhook 签名 (HMAC-SHA256)
- 持久化事件到数据�?
- 触发业务逻辑 (发送邮件通知�?

**技术要�?*:
```python
# 验证 x-ms-marketplace-token header
# 计算 HMAC-SHA256 签名
# 异步处理事件 (避免超时)
# 幂等性处�?(同一事件多次触发)
```

### 4️⃣ 数据库模�?

**文件**: `backend/media-service/models/marketplace_models.py`

**核心表结�?*:
- `users`: 用户账号 (Azure AD oid, email, name)
- `subscriptions`: 订阅信息 (subscription_id, plan_id, status, quantity)
- `user_subscriptions`: 用户-订阅关联 (多对�?
- `webhook_events`: Webhook 事件日志

### 5️⃣ Landing Page

**文件**: `marketplace-portal/app.py` (改�?

**功能**:
- 接收 token + subscription_id 参数
- 调用 Resolve API 获取订阅详情
- 显示激活页�?(订阅信息、计划、价�?
- 用户确认后调�?Activate API
- 重定向到主应�?

### 6️⃣ 前端认证集成

**文件**: `frontend/src/services/authService.ts` (新建)

**功能**:
- 集成 MSAL.js (Microsoft Authentication Library)
- 实现 Azure AD 登录流程
- 管理 access token �?refresh token
- 更新 Redux store �?authSlice

---

## 实施步骤

### Phase 1: Azure AD 应用注册 (1小时)

#### 步骤 1.1: 创建 Azure AD 应用

1. 登录 [Azure Portal](https://portal.azure.com)
2. 导航�?**Azure Active Directory** �?**App registrations**
3. 点击 **New registration**
4. 填写信息:
   ```
   Name: MediaGenie-Production
   Supported account types: Multitenant (任何组织目录中的账户)
   Redirect URI: 
     - Web: https://mediagenie-backend.azurewebsites.net/auth/callback
     - SPA: https://mediagenie-frontend.azurewebsites.net
   ```
5. 点击 **Register**

#### 步骤 1.2: 配置 API 权限

1. 进入应用 �?**API permissions**
2. 添加权限:
   - **Microsoft Graph** �?Delegated �?`User.Read`, `email`, `profile`, `openid`
3. 点击 **Grant admin consent** (管理员同�?

#### 步骤 1.3: 创建 Client Secret

1. 进入 **Certificates & secrets**
2. 点击 **New client secret**
3. 描述: `MediaGenie-Backend-Secret`
4. 过期时间: 24 months
5. **记录 secret value** (只显示一�?

#### 步骤 1.4: 记录关键信息

```bash
# 添加�?.env 文件
AZURE_AD_TENANT_ID=<你的 Tenant ID>
AZURE_AD_CLIENT_ID=<你的 Application (client) ID>
AZURE_AD_CLIENT_SECRET=<你的 Client Secret>
AZURE_AD_AUTHORITY=https://login.microsoftonline.com/<Tenant ID>
AZURE_AD_REDIRECT_URI=https://mediagenie-backend.azurewebsites.net/auth/callback
```

### Phase 2: SaaS Offer 技术配�?(30分钟)

#### 步骤 2.1: Partner Center 配置

1. 登录 [Partner Center](https://partner.microsoft.com/dashboard)
2. 进入您的 SaaS offer �?**Technical configuration**
3. 填写:
   ```
   Landing page URL: https://mediagenie-marketplace-portal.azurewebsites.net/landing
   Connection webhook: https://mediagenie-backend.azurewebsites.net/marketplace/webhook
   Azure Active Directory tenant ID: <上面�?Tenant ID>
   Azure Active Directory application ID: <上面�?Client ID>
   ```

#### 步骤 2.2: 获取 Marketplace API 凭证

这些凭证与上面的 Azure AD 应用相同,用于调用 SaaS Fulfillment API�?

---

## 数据库设�?

### 📊 表结构设�?

#### 1. `users` �?(用户账号)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    azure_ad_oid VARCHAR(255) UNIQUE NOT NULL,  -- Azure AD Object ID (唯一标识)
    azure_ad_sub VARCHAR(255),                   -- Azure AD Subject (备用标识)
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    tenant_id VARCHAR(255),                      -- Azure AD Tenant ID (多租户隔�?
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_azure_ad_oid (azure_ad_oid),
    INDEX idx_email (email)
);

COMMENT ON TABLE users IS '用户账号�?存储 Azure AD 登录用户信息';
COMMENT ON COLUMN users.azure_ad_oid IS 'Azure AD Object ID,用户�?Azure AD 中的唯一标识';
COMMENT ON COLUMN users.tenant_id IS 'Azure AD Tenant ID,用于多租户场景隔�?;
```

#### 2. `subscriptions` �?(订阅信息)

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id VARCHAR(255) UNIQUE NOT NULL,  -- Marketplace 订阅 ID
    subscription_name VARCHAR(255),
    offer_id VARCHAR(100) NOT NULL,                -- Offer ID (mediagenie)
    plan_id VARCHAR(100) NOT NULL,                 -- Plan ID (basic/standard/premium)
    quantity INT DEFAULT 1,                        -- 订阅数量
    
    -- 订阅状�?(�?Marketplace 保持一�?
    status VARCHAR(50) NOT NULL,  
    -- PendingFulfillmentStart / Subscribed / Suspended / Unsubscribed
    
    -- 购买者信�?
    purchaser_email VARCHAR(255),
    purchaser_tenant_id VARCHAR(255),
    
    -- 受益人信�?(实际使用�?
    beneficiary_email VARCHAR(255),
    beneficiary_tenant_id VARCHAR(255),
    
    -- 时间信息
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    term_start_date TIMESTAMP,
    term_end_date TIMESTAMP,
    
    -- SaaS 相关
    is_free_trial BOOLEAN DEFAULT FALSE,
    is_test BOOLEAN DEFAULT FALSE,
    auto_renew BOOLEAN DEFAULT TRUE,
    
    -- 元数�?
    raw_data JSONB,  -- 存储完整�?Marketplace 响应
    
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_status (status),
    INDEX idx_purchaser_email (purchaser_email)
);

COMMENT ON TABLE subscriptions IS 'Azure Marketplace 订阅信息';
COMMENT ON COLUMN subscriptions.subscription_id IS 'Marketplace 分配的订阅唯一 ID';
COMMENT ON COLUMN subscriptions.status IS '订阅状�? PendingFulfillmentStart, Subscribed, Suspended, Unsubscribed';
```

#### 3. `user_subscriptions` �?(用户-订阅关联)

```sql
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    -- 角色权限
    role VARCHAR(50) DEFAULT 'user',  -- owner / admin / user
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, subscription_id),
    INDEX idx_user_id (user_id),
    INDEX idx_subscription_id (subscription_id)
);

COMMENT ON TABLE user_subscriptions IS '用户-订阅多对多关联表';
COMMENT ON COLUMN user_subscriptions.role IS '用户角色: owner(所有�?, admin(管理�?, user(普通用�?';
```

#### 4. `webhook_events` �?(Webhook 事件日志)

```sql
CREATE TABLE webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id VARCHAR(255) UNIQUE,  -- Marketplace 事件 ID (幂等�?
    
    -- 事件信息
    event_type VARCHAR(50) NOT NULL,  
    -- Subscribe / Unsubscribe / ChangePlan / ChangeQuantity / Suspend / Reinstate
    
    subscription_id VARCHAR(255),
    plan_id VARCHAR(100),
    quantity INT,
    
    -- 处理状�?
    status VARCHAR(50) DEFAULT 'pending',  -- pending / processing / completed / failed
    error_message TEXT,
    retry_count INT DEFAULT 0,
    
    -- 时间信息
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    
    -- 原始数据
    raw_payload JSONB,
    
    INDEX idx_event_id (event_id),
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_status (status),
    INDEX idx_received_at (received_at)
);

COMMENT ON TABLE webhook_events IS 'Marketplace Webhook 事件日志';
COMMENT ON COLUMN webhook_events.event_id IS 'Marketplace 事件唯一 ID,用于幂等性检�?;
```

#### 5. 更新现有 `tasks` �?(添加订阅关联)

```sql
-- 添加订阅关联字段
ALTER TABLE tasks 
    ADD COLUMN subscription_id UUID REFERENCES subscriptions(id),
    ADD COLUMN tenant_id VARCHAR(255);

CREATE INDEX idx_tasks_subscription_id ON tasks(subscription_id);
CREATE INDEX idx_tasks_tenant_id ON tasks(tenant_id);

COMMENT ON COLUMN tasks.subscription_id IS '任务关联的订�?ID,用于计费和权限控�?;
COMMENT ON COLUMN tasks.tenant_id IS '租户 ID,用于多租户数据隔�?;
```

### 🔄 数据库迁移脚�?

**文件**: `backend/media-service/migrations/001_marketplace_tables.sql`

---

## API 集成流程

### 🔗 SaaS Fulfillment API v2 详解

**Base URL**: `https://marketplaceapi.microsoft.com/api`

#### 1. Resolve API (解析 Token)

**场景**: 用户�?Marketplace 重定向到 Landing Page 时调�?

```http
POST /saas/subscriptions/resolve?api-version=2018-08-31
Authorization: Bearer <Azure AD access token>
Content-Type: application/json
x-ms-marketplace-token: <marketplace token from query param>
```

**请求头说�?*:
- `Authorization`: Azure AD 服务主体 token
- `x-ms-marketplace-token`: Marketplace 重定向时携带�?token

**响应示例**:
```json
{
  "id": "12345678-1234-1234-1234-123456789abc",
  "subscriptionName": "MediaGenie-Corp",
  "offerId": "mediagenie",
  "planId": "standard",
  "quantity": 5,
  "subscription": {
    "id": "12345678-1234-1234-1234-123456789abc",
    "publisherId": "your-publisher-id",
    "offerId": "mediagenie",
    "name": "MediaGenie-Corp",
    "saasSubscriptionStatus": "PendingFulfillmentStart",
    "beneficiary": {
      "emailId": "user@company.com",
      "objectId": "user-azure-ad-oid",
      "tenantId": "company-tenant-id"
    },
    "purchaser": {
      "emailId": "admin@company.com",
      "objectId": "admin-azure-ad-oid",
      "tenantId": "company-tenant-id"
    },
    "planId": "standard",
    "term": {
      "startDate": "2025-10-27T00:00:00Z",
      "endDate": "2025-11-27T00:00:00Z",
      "termUnit": "P1M"
    },
    "isFreeTrial": false,
    "isTest": false,
    "allowedCustomerOperations": ["Read", "Update", "Delete"],
    "sessionMode": "None",
    "sandboxType": "None",
    "created": "2025-10-27T08:00:00Z",
    "lastModified": "2025-10-27T08:00:00Z"
  }
}
```

**处理逻辑**:
```python
# 1. 验证 token 有效�?
# 2. 检查订阅是否已存在 (防止重复激�?
# 3. 创建或更�?subscription 记录
# 4. 创建 beneficiary 用户账号 (如果不存�?
# 5. 关联 user_subscriptions
```

#### 2. Activate API (激活订�?

**场景**: Landing Page 用户确认后调�?开始计�?

```http
POST /saas/subscriptions/{subscriptionId}/activate?api-version=2018-08-31
Authorization: Bearer <Azure AD access token>
Content-Type: application/json

{
  "planId": "standard",
  "quantity": 5
}
```

**响应**: 
- `200 OK`: 激活成�?
- `400 Bad Request`: 参数错误
- `403 Forbidden`: 无权�?
- `404 Not Found`: 订阅不存�?
- `409 Conflict`: 订阅已激�?

**处理逻辑**:
```python
# 1. 调用 Activate API
# 2. 更新 subscription.status = 'Subscribed'
# 3. 记录 activated_at 时间�?
# 4. 发送欢迎邮件给用户
# 5. 启用用户�?MediaGenie 的访问权�?
```

#### 3. Get Subscription (查询订阅)

**场景**: 定期同步订阅状�?或用户登录时验证

```http
GET /saas/subscriptions/{subscriptionId}?api-version=2018-08-31
Authorization: Bearer <Azure AD access token>
```

**响应**: 返回完整的订阅详�?(�?Resolve 类似)

#### 4. Update Subscription (变更计划)

**场景**: 用户升级/降级订阅计划

```http
PATCH /saas/subscriptions/{subscriptionId}?api-version=2018-08-31
Authorization: Bearer <Azure AD access token>
Content-Type: application/json

{
  "planId": "premium",
  "quantity": 10
}
```

**响应**: 
- `202 Accepted`: 变更请求已接�?
- 实际变更通过 Webhook 通知

#### 5. Delete Subscription (取消订阅)

**场景**: 用户�?Marketplace 取消订阅

```http
DELETE /saas/subscriptions/{subscriptionId}?api-version=2018-08-31
Authorization: Bearer <Azure AD access token>
```

**响应**: 
- `202 Accepted`: 取消请求已接�?
- 实际删除通过 Webhook 通知

### 📥 Webhook 事件处理

**Endpoint**: `POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook`

**事件类型**:

| 事件类型 | 触发条件 | 处理动作 |
|---------|---------|---------|
| `Subscribe` | 新订阅被激�?| 创建订阅记录,发送欢迎邮�?|
| `Unsubscribe` | 用户取消订阅 | 更新状态为 Unsubscribed,禁用访问 |
| `ChangePlan` | 变更订阅计划 | 更新 plan_id,调整功能限制 |
| `ChangeQuantity` | 变更订阅数量 | 更新 quantity,调整配额 |
| `Suspend` | 订阅被暂�?(支付失败) | 更新状态为 Suspended,限制访问 |
| `Reinstate` | 订阅恢复 | 更新状态为 Subscribed,恢复访问 |

**Webhook 请求示例**:
```http
POST /marketplace/webhook
Content-Type: application/json
x-ms-marketplace-token: <验证签名�?

{
  "id": "event-12345",
  "activityId": "activity-67890",
  "subscriptionId": "12345678-1234-1234-1234-123456789abc",
  "offerId": "mediagenie",
  "publisherId": "your-publisher-id",
  "planId": "premium",
  "quantity": 10,
  "timeStamp": "2025-10-27T10:30:00Z",
  "action": "ChangePlan",
  "status": "Success"
}
```

**处理流程**:
```python
# 1. 验证签名 (x-ms-marketplace-token)
# 2. 检�?event_id 是否已处�?(幂等�?
# 3. 解析事件类型和参�?
# 4. 更新 subscriptions �?
# 5. 记录�?webhook_events �?
# 6. 触发业务逻辑 (邮件通知�?
# 7. 返回 200 OK (必须快速响�?
```

**签名验证**:
```python
import hmac
import hashlib

def verify_webhook_signature(request_body: bytes, token: str, secret: str) -> bool:
    """
    验证 Marketplace Webhook 签名
    
    Args:
        request_body: 原始请求 body (bytes)
        token: x-ms-marketplace-token header
        secret: Azure AD Client Secret
    """
    # Marketplace 使用 HMAC-SHA256
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        request_body,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected_signature, token)
```

---

## 安全性配�?

### 🔐 Azure AD Token 验证

#### JWT Token 结构

```json
{
  "header": {
    "alg": "RS256",
    "kid": "key-id-from-jwks",
    "typ": "JWT"
  },
  "payload": {
    "aud": "api://mediagenie-backend",  // 必须验证
    "iss": "https://login.microsoftonline.com/{tenant}/v2.0",  // 必须验证
    "iat": 1698393600,
    "nbf": 1698393600,
    "exp": 1698397200,  // 必须验证
    "oid": "user-object-id",  // 用户唯一标识
    "sub": "user-subject-id",
    "email": "user@company.com",
    "name": "User Name",
    "tid": "tenant-id",
    "roles": ["User", "Admin"],  // 可�?
    "scp": "User.Read"
  }
}
```

#### 验证步骤

1. **获取 JWKS (公钥�?**:
   ```python
   # Azure AD JWKS 端点
   jwks_uri = f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"
   ```

2. **验证 Token**:
   ```python
   import jwt
   from jwt.algorithms import RSAAlgorithm
   
   # 验证�?
   decoded = jwt.decode(
       token,
       key=public_key,
       algorithms=["RS256"],
       audience=f"api://{client_id}",
       issuer=f"https://login.microsoftonline.com/{tenant_id}/v2.0",
       options={
           "verify_signature": True,
           "verify_exp": True,
           "verify_nbf": True,
           "verify_iat": True,
           "verify_aud": True,
           "verify_iss": True
       }
   )
   ```

3. **提取用户信息**:
   ```python
   user_oid = decoded["oid"]  # 优先使用 oid
   user_email = decoded.get("email") or decoded.get("preferred_username")
   user_name = decoded.get("name")
   tenant_id = decoded["tid"]
   ```

### 🛡�?多租户数据隔�?

#### Row-Level Security (行级安全)

```sql
-- 为每个表添加 tenant_id �?
ALTER TABLE tasks ADD COLUMN tenant_id VARCHAR(255);
ALTER TABLE subscriptions ADD COLUMN tenant_id VARCHAR(255);

-- 创建策略函数
CREATE OR REPLACE FUNCTION current_tenant_id() 
RETURNS VARCHAR(255) AS $$
BEGIN
    RETURN current_setting('app.current_tenant_id', true);
END;
$$ LANGUAGE plpgsql STABLE;

-- 启用 Row-Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 创建策略 (只能访问自己租户的数�?
CREATE POLICY tenant_isolation_policy ON tasks
    USING (tenant_id = current_tenant_id());

-- 应用端设置租户上下文
-- 在每个请求开始时执行:
-- SET LOCAL app.current_tenant_id = '<user_tenant_id>';
```

#### API 层隔�?

```python
# 每个 API 请求自动注入 tenant_id
@app.get("/api/tasks")
async def get_tasks(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # 设置租户上下�?
    await db.execute(
        text(f"SET LOCAL app.current_tenant_id = '{current_user.tenant_id}'")
    )
    
    # 查询会自动过�?
    result = await db.execute(select(Task))
    return result.scalars().all()
```

---

## 测试验证

### 🧪 单元测试

#### 测试 Azure AD Token 验证

```python
# tests/test_auth_middleware.py
import pytest
from auth_middleware import verify_azure_ad_token

def test_valid_token():
    """测试有效 token"""
    token = "eyJ0eXAiOiJKV1QiLCJhbGc..."
    user = verify_azure_ad_token(token)
    assert user.oid == "expected-oid"
    assert user.email == "user@company.com"

def test_expired_token():
    """测试过期 token"""
    token = "expired-token"
    with pytest.raises(jwt.ExpiredSignatureError):
        verify_azure_ad_token(token)

def test_invalid_audience():
    """测试错误�?audience"""
    token = "token-with-wrong-audience"
    with pytest.raises(jwt.InvalidAudienceError):
        verify_azure_ad_token(token)
```

#### 测试 SaaS API 调用

```python
# tests/test_saas_fulfillment_client.py
import pytest
from unittest.mock import patch, MagicMock
from saas_fulfillment_client import SaaSFulfillmentClient

@pytest.fixture
def client():
    return SaaSFulfillmentClient(
        tenant_id="test-tenant",
        client_id="test-client",
        client_secret="test-secret"
    )

def test_resolve_subscription(client):
    """测试 Resolve API"""
    with patch('requests.post') as mock_post:
        mock_post.return_value.json.return_value = {
            "id": "sub-123",
            "planId": "standard"
        }
        
        result = client.resolve_subscription("marketplace-token")
        assert result["id"] == "sub-123"
        assert result["planId"] == "standard"

def test_activate_subscription(client):
    """测试 Activate API"""
    with patch('requests.post') as mock_post:
        mock_post.return_value.status_code = 200
        
        success = client.activate_subscription("sub-123", "standard", 1)
        assert success is True
```

#### 测试 Webhook 处理

```python
# tests/test_marketplace_webhook.py
import pytest
from marketplace_webhook import process_webhook_event

def test_subscribe_event():
    """测试订阅事件"""
    event = {
        "id": "event-1",
        "action": "Subscribe",
        "subscriptionId": "sub-123",
        "planId": "standard"
    }
    
    result = process_webhook_event(event)
    assert result["status"] == "completed"

def test_duplicate_event():
    """测试重复事件 (幂等�?"""
    event = {"id": "event-1", "action": "Subscribe"}
    
    # 第一次处�?
    result1 = process_webhook_event(event)
    assert result1["status"] == "completed"
    
    # 第二次处�?(应该跳过)
    result2 = process_webhook_event(event)
    assert result2["status"] == "skipped"
```

### 🔬 集成测试

#### 端到端流程测�?

```python
# tests/integration/test_subscription_flow.py
import pytest
from fastapi.testclient import TestClient

@pytest.mark.integration
def test_complete_subscription_flow(client: TestClient):
    """测试完整的订阅激活流�?""
    
    # 1. 模拟 Marketplace 重定�?
    response = client.get(
        "/landing",
        params={
            "token": "marketplace-token-123",
            "subscription_id": "sub-456"
        }
    )
    assert response.status_code == 200
    
    # 2. 用户确认激�?
    response = client.post(
        "/landing/activate",
        json={"subscription_id": "sub-456"}
    )
    assert response.status_code == 200
    
    # 3. 验证订阅已激�?
    response = client.get("/api/subscription/status")
    assert response.json()["status"] == "Subscribed"
    
    # 4. 模拟 Webhook 事件
    response = client.post(
        "/marketplace/webhook",
        json={
            "id": "event-789",
            "action": "ChangePlan",
            "subscriptionId": "sub-456",
            "planId": "premium"
        }
    )
    assert response.status_code == 200
    
    # 5. 验证计划已变�?
    response = client.get("/api/subscription/status")
    assert response.json()["plan_id"] == "premium"
```

### 📊 手动测试清单

#### Landing Page 测试

- [ ] 访问 `https://mediagenie-marketplace-portal.azurewebsites.net/landing?token=xxx&subscription_id=yyy`
- [ ] 验证显示正确的订阅信�?(计划名称、价格、数�?
- [ ] 点击"激�?按钮,验证成功激�?
- [ ] 验证重定向到主应�?
- [ ] 验证用户可以正常登录和使用功�?

#### Webhook 测试

使用 [RequestBin](https://requestbin.com/) �?Postman 模拟 Marketplace Webhook:

```bash
curl -X POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -H "x-ms-marketplace-token: test-signature" \
  -d '{
    "id": "test-event-1",
    "action": "Subscribe",
    "subscriptionId": "test-sub-123",
    "planId": "standard",
    "quantity": 1
  }'
```

验证:
- [ ] 返回 200 OK
- [ ] 数据库中创建�?webhook_events 记录
- [ ] 订阅状态已更新

#### Azure AD 登录测试

- [ ] 前端点击"登录"按钮
- [ ] 重定向到 Microsoft 登录页面
- [ ] 使用 Azure AD 账号登录
- [ ] 成功重定向回应用
- [ ] 验证用户信息正确显示
- [ ] 验证 API 请求携带正确�?Authorization header

---

## 部署清单

### �?部署前检�?

#### 环境变量配置

�?Azure App Service 配置以下环境变量:

**Backend (mediagenie-backend)**:
```bash
# Azure AD 配置
AZURE_AD_TENANT_ID=<your-tenant-id>
AZURE_AD_CLIENT_ID=<your-client-id>
AZURE_AD_CLIENT_SECRET=<your-client-secret>
AZURE_AD_AUTHORITY=https://login.microsoftonline.com/<tenant-id>

# SaaS API 配置
MARKETPLACE_API_BASE_URL=https://marketplaceapi.microsoft.com/api
MARKETPLACE_API_VERSION=2018-08-31

# 数据库配�?
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/mediagenie
REDIS_URL=redis://host:6379/0

# 现有�?Azure Services 配置
AZURE_OPENAI_ENDPOINT=...
AZURE_SPEECH_KEY=...
AZURE_VISION_ENDPOINT=...

# CORS 配置
FRONTEND_URL=https://mediagenie-frontend.azurewebsites.net
MARKETPLACE_PORTAL_URL=https://mediagenie-marketplace-portal.azurewebsites.net

# 日志级别
LOG_LEVEL=INFO
```

**Frontend (mediagenie-frontend)**:
```bash
# Azure AD 配置 (MSAL.js)
REACT_APP_AZURE_AD_CLIENT_ID=<your-client-id>
REACT_APP_AZURE_AD_AUTHORITY=https://login.microsoftonline.com/<tenant-id>
REACT_APP_AZURE_AD_REDIRECT_URI=https://mediagenie-frontend.azurewebsites.net

# API 端点
REACT_APP_API_BASE_URL=https://mediagenie-backend.azurewebsites.net
```

**Marketplace Portal (mediagenie-marketplace-portal)**:
```bash
# Azure AD 配置
AZURE_AD_TENANT_ID=<your-tenant-id>
AZURE_AD_CLIENT_ID=<your-client-id>
AZURE_AD_CLIENT_SECRET=<your-client-secret>

# Backend API
BACKEND_URL=https://mediagenie-backend.azurewebsites.net

# Frontend URL (激活后重定�?
FRONTEND_URL=https://mediagenie-frontend.azurewebsites.net

# Flask 配置
SECRET_KEY=<random-secret-key>
FLASK_ENV=production
```

#### 数据库迁�?

```bash
# 1. 连接�?PostgreSQL
psql $DATABASE_URL

# 2. 执行迁移脚本
\i backend/media-service/migrations/001_marketplace_tables.sql

# 3. 验证表已创建
\dt

# 4. 验证索引
\di
```

#### Partner Center 配置

- [ ] Technical configuration 已填�?Landing page URL �?Webhook URL
- [ ] Azure AD application ID 已配�?
- [ ] Connection webhook 已测试通过
- [ ] Plans and pricing 已配�?(Basic/Standard/Premium)
- [ ] Offer 已提交审�?

### 🚀 部署步骤

#### 1. 部署 Backend Service

```bash
cd backend/media-service

# 安装依赖 (包含新模�?
pip install -r requirements.txt

# 打包
zip -r backend-api.zip . -x "*.pyc" "__pycache__/*" "logs/*"

# 部署�?Azure
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --src backend-api.zip

# 配置启动命令
az webapp config set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --startup-file "gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind=0.0.0.0:8000 --timeout 600"
```

#### 2. 部署 Marketplace Portal

```bash
cd marketplace-portal

# 打包
zip -r portal.zip . -x "*.pyc" "__pycache__/*"

# 部署
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace-portal \
  --src portal.zip

# 配置启动命令
az webapp config set \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace-portal \
  --startup-file "gunicorn app:app --bind=0.0.0.0:8000"
```

#### 3. 部署 Frontend

```bash
cd frontend

# 构建生产版本
npm run build

# 部署�?Azure Static Web Apps �?App Service
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name mediagenie-frontend \
  --src build.zip
```

### 🔍 部署后验�?

#### Health Check

```bash
# Backend
curl https://mediagenie-backend.azurewebsites.net/health

# Expected: {"status": "healthy", "timestamp": "..."}

# Marketplace Portal
curl https://mediagenie-marketplace-portal.azurewebsites.net/health

# Expected: {"status": "ok"}
```

#### Azure AD Login Flow

1. 访问 `https://mediagenie-frontend.azurewebsites.net`
2. 点击"登录"按钮
3. 应该重定向到 `https://login.microsoftonline.com/...`
4. 登录后应该返回应用并显示用户�?

#### Subscription Flow

1. �?Partner Center 创建测试订阅
2. 应该重定向到 Landing Page
3. 显示订阅详情
4. 点击"激�?后应该成�?
5. �?Backend 数据库中验证订阅记录已创�?

---

## 常见问题

### �?Q1: Token 验证失败,返回 401 Unauthorized

**可能原因**:
- Token 已过�?
- Audience (aud) 不匹�?
- Issuer (iss) 不匹�?
- JWKS 公钥缓存过期

**解决方案**:
```python
# 1. 检�?token 过期时间
import jwt
decoded = jwt.decode(token, options={"verify_signature": False})
print(f"Token expires at: {decoded['exp']}")

# 2. 验证 audience
print(f"Token audience: {decoded['aud']}")
# 应该匹配 f"api://{client_id}" �?client_id

# 3. 刷新 JWKS 缓存
# 设置较短�?TTL (�?1 小时)
```

### �?Q2: Resolve API 返回 404 Not Found

**可能原因**:
- Marketplace token 无效或已过期
- Token 已被使用 (只能使用一�?
- Azure AD Service Principal 权限不足

**解决方案**:
```bash
# 1. 验证 Service Principal �?Marketplace API 权限
az ad app permission list --id <client-id>

# 2. 重新生成 Marketplace token
# �?Partner Center 创建新的测试购买

# 3. 检�?API 调用日志
# 查看具体错误信息
```

### �?Q3: Webhook 未触�?

**可能原因**:
- Webhook URL 配置错误
- Endpoint 返回�?200 状态码
- Endpoint 响应超时 (>30�?
- 防火墙阻止了 Marketplace IP

**解决方案**:
```bash
# 1. 验证 Webhook URL 可访�?
curl -X POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# 2. 检查应用日�?
az webapp log tail --resource-group MediaGenie-RG --name mediagenie-backend

# 3. 添加详细日志
logger.info(f"Webhook received: {request.json()}")

# 4. 使用 RequestBin 调试
# 临时�?Webhook URL 改为 RequestBin,查看 Marketplace 发送的实际数据
```

### �?Q4: 用户无法看到订阅信息

**可能原因**:
- User �?Subscription 未正确关�?
- Tenant ID 隔离导致查询不到数据
- Beneficiary 信息未同�?

**解决方案**:
```sql
-- 1. 检查用户是否存�?
SELECT * FROM users WHERE email = 'user@company.com';

-- 2. 检查订阅关�?
SELECT us.*, s.* 
FROM user_subscriptions us
JOIN subscriptions s ON us.subscription_id = s.id
WHERE us.user_id = '<user-id>';

-- 3. 手动创建关联 (如果缺失)
INSERT INTO user_subscriptions (user_id, subscription_id, role)
VALUES ('<user-id>', '<subscription-id>', 'owner');
```

### �?Q5: Activate API 返回 409 Conflict

**可能原因**:
- 订阅已经激活过
- 调用了多�?Activate (幂等性问�?

**解决方案**:
```python
# 1. 先查询订阅状�?
subscription = client.get_subscription(subscription_id)
if subscription["saasSubscriptionStatus"] == "Subscribed":
    logger.info("Subscription already activated")
    return

# 2. 只在 PendingFulfillmentStart 状态调�?Activate
if subscription["saasSubscriptionStatus"] == "PendingFulfillmentStart":
    client.activate_subscription(subscription_id, plan_id, quantity)
```

### �?Q6: 多租户数据泄�?

**可能原因**:
- 未正确实�?Row-Level Security
- API 查询未过�?tenant_id
- 跨租户的 subscription_id 引用

**解决方案**:
```python
# 1. 所有查询必须带 tenant_id 过滤
async def get_tasks(user: User, db: AsyncSession):
    # �?错误: 未过滤租�?
    tasks = await db.execute(select(Task))
    
    # �?正确: 过滤租户
    tasks = await db.execute(
        select(Task).where(Task.tenant_id == user.tenant_id)
    )

# 2. 启用 Row-Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON tasks
    USING (tenant_id = current_setting('app.current_tenant_id'));

# 3. 审计查询日志
# 定期检查是否有跨租户访�?
```

---

## 附录

### 📚 参考文�?

- [Azure Marketplace SaaS Offer Documentation](https://learn.microsoft.com/en-us/azure/marketplace/plan-saas-offer)
- [SaaS Fulfillment API v2](https://learn.microsoft.com/en-us/azure/marketplace/partner-center-portal/pc-saas-fulfillment-api-v2)
- [Marketplace Metering Service API](https://learn.microsoft.com/en-us/azure/marketplace/partner-center-portal/marketplace-metering-service-apis)
- [Azure AD Authentication](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
- [MSAL.js Documentation](https://github.com/AzureAD/microsoft-authentication-library-for-js)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

### 🛠�?推荐工具

- **JWT Debugger**: https://jwt.io/ (验证 token 结构)
- **RequestBin**: https://requestbin.com/ (调试 webhook)
- **Postman**: https://www.postman.com/ (API 测试)
- **Azure Portal**: https://portal.azure.com/ (资源管理)
- **Partner Center**: https://partner.microsoft.com/dashboard (Offer 管理)

### 📧 支持联系

如果遇到技术问�?可以参�?
- [Azure Marketplace 论坛](https://aka.ms/MarketplaceForum)
- [Partner Center Support](https://partner.microsoft.com/support)
- [Azure Support](https://azure.microsoft.com/support/)

---

## 总结

本指导文档提供了�?MediaGenie 集成�?Azure Marketplace 的完整技术路�?

1. �?**Azure AD 认证**: 实现单点登录�?JWT 验证
2. �?**SaaS Fulfillment API**: 管理订阅生命周期
3. �?**Webhook 集成**: 实时处理订阅事件
4. �?**数据库设�?*: 多租户数据隔�?
5. �?**安全性配�?*: Token 验证和签名校�?
6. �?**测试验证**: 单元测试和集成测�?
7. �?**部署清单**: 生产环境部署步骤

**下一�?*: 请查看对应的代码实现文件,按照 Phase 1-4 的顺序逐步实施�?

---

**文档版本**: v1.0  
**最后更�?*: 2025�?0�?7�? 
**作�?*: GitHub Copilot  
**项目**: MediaGenie Azure Marketplace SaaS Integration
