# MediaGenie 测试指南

> **测试 Phase 1-3 完成的功�?*

---

## 🧪 测试环境准备

### 1. 安装依赖

```bash
# Backend
cd backend/media-service
pip install -r requirements.txt

# Marketplace Portal
cd marketplace-portal
pip install -r requirements.txt
```

### 2. 配置环境变量

创建 `backend/media-service/.env`:

```bash
# 数据库配�?(必需)
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/mediagenie

# Azure AD 配置 (可�?用于 Landing Page 测试)
AZURE_AD_TENANT_ID=your-tenant-id
AZURE_AD_CLIENT_ID=your-client-id
AZURE_AD_CLIENT_SECRET=your-client-secret

# Azure Cognitive Services (必需)
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_OPENAI_KEY=your-key
AZURE_SPEECH_KEY=your-key
AZURE_SPEECH_REGION=eastus
AZURE_VISION_ENDPOINT=https://your-vision.cognitiveservices.azure.com/
AZURE_VISION_KEY=your-key

# Webhook 配置
WEBHOOK_SIGNATURE_ENABLED=false  # 测试时禁用签名验�?```

创建 `marketplace-portal/.env`:

```bash
BACKEND_URL=http://localhost:9001
FRONTEND_URL=http://localhost:3000
SECRET_KEY=dev-secret-key

# Azure AD 配置 (可�?
AZURE_AD_TENANT_ID=your-tenant-id
AZURE_AD_CLIENT_ID=your-client-id
AZURE_AD_CLIENT_SECRET=your-client-secret
```

---

## �?Phase 1: 数据库集成测�?
### 测试 1.1: 执行数据库迁�?
```bash
cd backend/media-service

# 方法 1: 使用 Python 脚本
python run_migration.py

# 方法 2: 使用 psql
psql $DATABASE_URL -f migrations/001_marketplace_tables.sql
```

**预期输出**:
```
�?Database connection established
�?Migration executed successfully
�?Created tables: subscriptions, user_subscriptions, users, webhook_events
�?Created views: v_active_subscriptions, v_user_subscriptions
�?Created functions: associate_user_subscription, current_tenant_id, upsert_user
🎉 Migration completed successfully!
```

---

### 测试 1.2: 数据库连接测�?
```bash
cd backend/media-service
python test_db_connection.py
```

**预期输出**:
```
🧪 Starting database tests...

============================================================
Testing database connection...
============================================================
�?Database connection successful

============================================================
Testing health check...
============================================================
�?Health check passed

============================================================
Testing if tables exist...
============================================================
�?Table 'users' exists (rows: 0)
�?Table 'subscriptions' exists (rows: 0)
�?Table 'user_subscriptions' exists (rows: 0)
�?Table 'webhook_events' exists (rows: 0)

============================================================
Testing user operations...
============================================================
�?Created user: test@example.com (ID: ...)
�?Found user by OID: test@example.com
�?Updated user: Updated Test User

============================================================
Testing subscription operations...
============================================================
�?Created subscription: test-sub-001
�?Activated subscription: test-sub-001
�?Updated subscription plan to: premium

============================================================
Testing webhook event operations...
============================================================
�?Created webhook event: test-event-001
�?Marked event as processing
�?Marked event as completed
�?Idempotency check passed

============================================================
Cleaning up test data...
============================================================
�?Test data cleaned up

============================================================
Test Summary
============================================================
�?PASSED - Connection Test
�?PASSED - Health Check Test
�?PASSED - Tables Exist Test
�?PASSED - User Operations Test
�?PASSED - Subscription Operations Test
�?PASSED - Webhook Event Operations Test
============================================================
Total: 6/6 tests passed
============================================================

🎉 All tests passed!
```

---

### 测试 1.3: API 端点测试

```bash
# 启动后端服务
cd backend/media-service
uvicorn main:app --reload --port 9001
```

在另一个终�?

```bash
# 测试健康检�?curl http://localhost:9001/health

# 测试 Marketplace 健康检�?curl http://localhost:9001/marketplace/health

# 预期输出:
# {
#   "status": "healthy",
#   "service": "MediaGenie Marketplace Integration",
#   "version": "1.0.0",
#   "database": "connected",
#   "subscriptions": 0,
#   "events_logged": 0,
#   "timestamp": "2025-10-27T..."
# }
```

---

## �?Phase 2: Landing Page 激活流程测�?
### 测试 2.1: 启动 Marketplace Portal

```bash
cd marketplace-portal
python app.py
```

**预期输出**:
```
 * Running on http://0.0.0.0:5000
```

---

### 测试 2.2: 访问 Landing Page

```bash
# 方法 1: 浏览器访�?# http://localhost:5000/landing?token=test-token

# 方法 2: curl 测试
curl "http://localhost:5000/landing?token=test-token"
```

**预期结果**:
- 显示错误消息 (因为 test-token 无效)
- 或者显示订阅详�?(如果配置了有效的 Azure AD 凭据)

---

### 测试 2.3: 测试激活端�?
```bash
# 注意: 需要先访问 Landing Page 建立 session

# 使用 curl 测试 (需�?cookie)
curl -X POST http://localhost:5000/activate \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -b cookies.txt

# 预期输出:
# {
#   "status": "error",
#   "message": "No subscription data found. Please start from the landing page."
# }
```

---

### 测试 2.4: 端到端测�?(需要真�?Marketplace token)

如果你有真实�?Marketplace token:

1. 访问: `http://localhost:5000/landing?token=<real-token>`
2. 查看订阅详情
3. 点击"激活订�?按钮
4. 等待激活完�?5. 自动重定向到前端应用

---

## �?Phase 3: Webhook 签名验证测试

### 测试 3.1: 测试 Webhook 端点 (无签名验�?

```bash
# 确保 WEBHOOK_SIGNATURE_ENABLED=false

curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-event-001",
    "activityId": "test-activity-001",
    "subscriptionId": "test-sub-001",
    "offerId": "mediagenie",
    "publisherId": "test-publisher",
    "planId": "standard",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'

# 预期输出:
# {
#   "status": "accepted",
#   "event_id": "test-event-001",
#   "message": "Event accepted for processing"
# }
```

---

### 测试 3.2: 验证事件已保�?
```bash
# 查询事件列表
curl http://localhost:9001/marketplace/events

# 预期输出:
# {
#   "total": 1,
#   "events": [
#     {
#       "event_id": "test-event-001",
#       "event_type": "Subscribe",
#       "subscription_id": "test-sub-001",
#       "processing_status": "completed",
#       "received_at": "2025-10-27T...",
#       "processed_at": "2025-10-27T..."
#     }
#   ]
# }
```

---

### 测试 3.3: 测试幂等�?
```bash
# 发送相同的事件两次
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-event-002",
    "activityId": "test-activity-002",
    "subscriptionId": "test-sub-002",
    "offerId": "mediagenie",
    "publisherId": "test-publisher",
    "planId": "standard",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'

# 第一�? {"status": "accepted", ...}

# 再次发送相同的事件
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-event-002",
    "activityId": "test-activity-002",
    "subscriptionId": "test-sub-002",
    "offerId": "mediagenie",
    "publisherId": "test-publisher",
    "planId": "standard",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'

# 第二�? {"status": "skipped", "message": "Event already processed"}
```

---

### 测试 3.4: 测试所有事件类�?
```bash
# Subscribe
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-sub", "activityId": "act-1", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "basic", "quantity": 1, "timeStamp": "2025-10-27T10:00:00Z", "action": "Subscribe", "status": "Success"}'

# Unsubscribe
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-unsub", "activityId": "act-2", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "basic", "quantity": 1, "timeStamp": "2025-10-27T10:01:00Z", "action": "Unsubscribe", "status": "Success"}'

# ChangePlan
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-plan", "activityId": "act-3", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "premium", "quantity": 1, "timeStamp": "2025-10-27T10:02:00Z", "action": "ChangePlan", "status": "Success"}'

# ChangeQuantity
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-qty", "activityId": "act-4", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "premium", "quantity": 5, "timeStamp": "2025-10-27T10:03:00Z", "action": "ChangeQuantity", "status": "Success"}'

# Suspend
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-suspend", "activityId": "act-5", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "premium", "quantity": 5, "timeStamp": "2025-10-27T10:04:00Z", "action": "Suspend", "status": "Success"}'

# Reinstate
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id": "evt-reinstate", "activityId": "act-6", "subscriptionId": "sub-1", "offerId": "offer-1", "publisherId": "pub-1", "planId": "premium", "quantity": 5, "timeStamp": "2025-10-27T10:05:00Z", "action": "Reinstate", "status": "Success"}'
```

---

## 📊 测试结果验证

### 验证数据库数�?
```sql
-- 连接到数据库
psql $DATABASE_URL

-- 查看所有订�?SELECT subscription_id, plan_id, status, quantity FROM subscriptions;

-- 查看所有事�?SELECT event_id, event_type, subscription_id, processing_status FROM webhook_events ORDER BY received_at DESC;

-- 查看用户
SELECT azure_ad_oid, email, display_name FROM users;

-- 查看用户-订阅关联
SELECT * FROM v_user_subscriptions;
```

---

## 🐛 常见问题排查

### 问题 1: 数据库连接失�?
```bash
# 检�?PostgreSQL 是否运行
pg_isready

# 检查连接字符串
echo $DATABASE_URL

# 测试连接
psql $DATABASE_URL -c "SELECT 1"
```

---

### 问题 2: 迁移脚本失败

```bash
# 查看详细错误
python run_migration.py 2>&1 | tee migration.log

# 手动执行 SQL
psql $DATABASE_URL -f migrations/001_marketplace_tables.sql
```

---

### 问题 3: Webhook 处理失败

```bash
# 查看后端日志
tail -f backend/media-service/logs/media-service.log

# 查看事件状�?curl http://localhost:9001/marketplace/events | jq '.events[] | select(.processing_status == "failed")'
```

---

## �?测试清单

### Phase 1 测试
- [ ] 数据库迁移成�?- [ ] 所有表已创�?- [ ] 测试脚本通过 (6/6)
- [ ] API 健康检查通过
- [ ] 订阅 CRUD 操作正常
- [ ] 事件 CRUD 操作正常

### Phase 2 测试
- [ ] Landing Page 可访�?- [ ] 激活端点可访问
- [ ] 订阅状态查询正�?- [ ] 错误处理正确

### Phase 3 测试
- [ ] Webhook 端点可访�?- [ ] 所有事件类型处理正�?- [ ] 幂等性检查生�?- [ ] 事件保存到数据库
- [ ] 订阅状态正确更�?
---

**所有测试通过�?可以继续 Phase 4!** 🎉

