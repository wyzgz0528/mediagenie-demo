# MediaGenie 测试状态报�?
> **生成时间**: 2025-10-27  
> **测试阶段**: Phase 1-3 功能验证

---

## 📊 当前状�?
### �?已完成的准备工作

1. **�?环境检�?*
   - Python 3.13.7 已安�?   - 所有必需�?Python 包已安装 (FastAPI, SQLAlchemy, asyncpg, etc.)
   - `.env` 文件已配�?   - 所有项目文件已创建

2. **�?代码实现**
   - Phase 1: 数据库集�?(100%)
   - Phase 2: Landing Page 激活流�?(100%)
   - Phase 3: Webhook 签名验证 (100%)

3. **�?文档创建**
   - 实施计划文档
   - 测试指南
   - 数据库设置指�?   - 快速测试脚�?
---

## �?待完成的步骤

### 步骤 1: 启动 PostgreSQL 数据�?
**当前状�?*: �?未启�?
**需要做什�?*:
1. 打开 **Docker Desktop** 应用
2. 等待 Docker 完全启动
3. 运行启动脚本:
   ```powershell
   powershell -ExecutionPolicy Bypass -File start-postgres.ps1
   ```

**或者手动启�?*:
```powershell
docker run -d `
  --name mediagenie-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=password `
  -e POSTGRES_DB=mediagenie `
  -p 5432:5432 `
  postgres:15-alpine
```

**验证**:
```powershell
docker ps
# 应该看到 mediagenie-postgres 容器正在运行
```

---

### 步骤 2: 验证数据库连�?
**运行快速测�?*:
```powershell
python backend/media-service/quick_test.py
```

**预期输出**:
```
�?通过 - 包安�?�?通过 - .env 文件
�?通过 - 项目文件
�?通过 - 数据库连�?
总计: 4/4 测试通过

🎉 所有测试通过！可以继续执行数据库迁移�?```

---

### 步骤 3: 执行数据库迁�?
**运行迁移脚本**:
```powershell
python backend/media-service/run_migration.py
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

### 步骤 4: 运行完整数据库测�?
**运行测试脚本**:
```powershell
python backend/media-service/test_db_connection.py
```

**预期输出**:
```
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

### 步骤 5: 启动后端服务

**启动 FastAPI 服务**:
```powershell
cd backend/media-service
uvicorn main:app --reload --port 9001
```

**预期输出**:
```
INFO:     Uvicorn running on http://127.0.0.1:9001 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

---

### 步骤 6: 测试 API 端点

**在新�?PowerShell 窗口中运�?*:

#### 测试 1: 健康检�?```powershell
curl http://localhost:9001/health
```

**预期输出**:
```json
{
  "status": "healthy",
  "service": "MediaGenie Media Processing Service",
  "version": "1.0.0"
}
```

#### 测试 2: Marketplace 健康检�?```powershell
curl http://localhost:9001/marketplace/health
```

**预期输出**:
```json
{
  "status": "healthy",
  "service": "MediaGenie Marketplace Integration",
  "version": "1.0.0",
  "database": "connected",
  "subscriptions": 0,
  "events_logged": 0
}
```

#### 测试 3: Webhook 端点
```powershell
$body = @{
    id = "test-event-001"
    activityId = "test-activity-001"
    subscriptionId = "test-sub-001"
    offerId = "mediagenie"
    publisherId = "test-publisher"
    planId = "standard"
    quantity = 1
    timeStamp = "2025-10-27T10:00:00Z"
    action = "Subscribe"
    status = "Success"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:9001/marketplace/webhook" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

**预期输出**:
```json
{
  "status": "accepted",
  "event_id": "test-event-001",
  "message": "Event accepted for processing"
}
```

#### 测试 4: 查询事件列表
```powershell
curl http://localhost:9001/marketplace/events
```

**预期输出**:
```json
{
  "total": 1,
  "events": [
    {
      "event_id": "test-event-001",
      "event_type": "Subscribe",
      "subscription_id": "test-sub-001",
      "processing_status": "completed",
      "received_at": "2025-10-27T...",
      "processed_at": "2025-10-27T..."
    }
  ]
}
```

---

### 步骤 7: 启动 Marketplace Portal

**在新�?PowerShell 窗口中运�?*:
```powershell
cd marketplace-portal
python app.py
```

**预期输出**:
```
 * Running on http://0.0.0.0:5000
```

---

### 步骤 8: 测试 Landing Page

**在浏览器中访�?*:
```
http://localhost:5000/landing?token=test-token
```

**预期结果**:
- 显示错误消息 (因为 test-token 无效)
- 或者显示订阅详�?(如果配置了有效的 Azure AD 凭据)

---

## 📋 测试清单

### Phase 1: 数据库集�?- [ ] Docker Desktop 已启�?- [ ] PostgreSQL 容器正在运行
- [ ] 数据库连接测试通过
- [ ] 数据库迁移成功执�?- [ ] 所有表已创�?(users, subscriptions, user_subscriptions, webhook_events)
- [ ] 完整测试通过 (6/6)

### Phase 2: Landing Page 激活流�?- [ ] Marketplace Portal 启动成功
- [ ] Landing Page 可以访问
- [ ] 激活端点可以访�?- [ ] 错误处理正确显示

### Phase 3: Webhook 签名验证
- [ ] 后端服务启动成功
- [ ] Webhook 端点可以访问
- [ ] Subscribe 事件处理成功
- [ ] 事件保存到数据库
- [ ] 幂等性检查生�?- [ ] 事件列表查询成功

---

## 🎯 快速开始命�?
**一键启动所有服�?* (需�?3 �?PowerShell 窗口):

### 窗口 1: PostgreSQL
```powershell
# 启动 Docker Desktop 后运�?powershell -ExecutionPolicy Bypass -File start-postgres.ps1
```

### 窗口 2: 后端服务
```powershell
cd backend/media-service
python run_migration.py
uvicorn main:app --reload --port 9001
```

### 窗口 3: Marketplace Portal
```powershell
cd marketplace-portal
python app.py
```

---

## 📊 测试进度

| 测试�?| 状�?| 说明 |
|--------|------|------|
| 环境检�?| �?完成 | Python, �? 文件都已就绪 |
| PostgreSQL 启动 | �?待完�?| 需要启�?Docker Desktop |
| 数据库连�?| �?待完�?| 等待 PostgreSQL 启动 |
| 数据库迁�?| �?待完�?| 等待数据库连�?|
| 完整测试 | �?待完�?| 等待迁移完成 |
| API 端点测试 | �?待完�?| 等待服务启动 |
| Landing Page 测试 | �?待完�?| 等待 Portal 启动 |

---

## 🚀 下一步行�?
**立即执行**:
1. 打开 Docker Desktop
2. 运行 `start-postgres.ps1`
3. 运行 `quick_test.py` 验证连接
4. 运行 `run_migration.py` 创建�?5. 运行 `test_db_connection.py` 完整测试
6. 启动后端服务
7. 测试 API 端点

**预计时间**: 15-20 分钟

---

## 📚 相关文档

- [数据库设置指南](docs/SETUP_DATABASE.md) - 详细的数据库设置步骤
- [测试指南](docs/TESTING_GUIDE.md) - 完整的测试流�?- [实施进度](docs/IMPLEMENTATION_PROGRESS.md) - 项目完成情况

---

## 💡 提示

1. **Docker Desktop 必须运行** - 这是最重要的前提条�?2. **按顺序执�?* - 不要跳过步骤
3. **查看日志** - 如果出错，检查容器日�? `docker logs mediagenie-postgres`
4. **端口冲突** - 如果 5432 端口被占用，使用不同的端�?
---

**准备好了吗？让我们开始测试！** 🎉

