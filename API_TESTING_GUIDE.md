# 🚀 API 端点测试指南

> **测试时间**: 2025-10-27  
> **测试环境**: Windows + FastAPI + PostgreSQL

---

## 📋 前置条件

�?**已完�?*:
- PostgreSQL 容器运行�?(端口 5432)
- 数据库迁移已执行
- 所有依赖已安装

---

## 🎯 启动后端服务

### 步骤 1: 打开新的 PowerShell 窗口

**重要**: 不要�?VS Code 终端中运行，打开一个独立的 PowerShell 窗口

### 步骤 2: 导航到后端目�?
```powershell
cd F:\project\MediaGenie1001\backend\media-service
```

### 步骤 3: 启动 FastAPI 服务

```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

**预期输出**:
```
INFO:     Uvicorn running on http://0.0.0.0:9001
INFO:     Application startup complete
```

�?**服务已启动！**

---

## 🧪 测试 API 端点

### 方法 1: 使用 Swagger UI (推荐)

1. **打开浏览�?*，访�?
   ```
   http://localhost:9001/docs
   ```

2. **你会看到**:
   - 所有可用的 API 端点
   - 每个端点的详细文�?   - 可以直接在浏览器中测�?
3. **测试步骤**:
   - 点击 "Try it out" 按钮
   - 输入参数
   - 点击 "Execute" 按钮
   - 查看响应

---

### 方法 2: 使用 PowerShell 命令

#### 测试 1: 健康检�?
```powershell
curl http://localhost:9001/health
```

**预期响应**:
```json
{
  "status": "active",
  "service": "MediaGenie",
  "version": "1.0.0",
  "timestamp": "2025-10-27T..."
}
```

---

#### 测试 2: Marketplace 健康检�?
```powershell
curl http://localhost:9001/marketplace/health
```

**预期响应**:
```json
{
  "status": "active",
  "service": "MediaGenie",
  "version": "1.0.0",
  "marketplace": {
    "webhook_endpoint": "/api/marketplace/webhook",
    "supported_actions": ["subscribe", "unsubscribe", "changePlan", "changeQuantity"]
  },
  "timestamp": "2025-10-27T..."
}
```

---

#### 测试 3: 发�?Webhook 事件

```powershell
$body = @{
    id = "test-webhook-001"
    activityId = "activity-001"
    subscriptionId = "sub-test-001"
    offerId = "offer-test"
    publisherId = "publisher-test"
    planId = "basic"
    quantity = 1
    timeStamp = (Get-Date -AsUTC -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "Subscribe"
    status = "Success"
} | ConvertTo-Json

curl -X POST http://localhost:9001/marketplace/webhook `
  -H "Content-Type: application/json" `
  -d $body
```

**预期响应**:
```json
{
  "status": "received",
  "event_id": "test-webhook-001",
  "message": "Webhook event received and queued for processing"
}
```

---

#### 测试 4: 获取事件列表

```powershell
curl http://localhost:9001/marketplace/events
```

**预期响应**:
```json
{
  "events": [
    {
      "id": "...",
      "event_id": "test-webhook-001",
      "event_type": "Subscribe",
      "status": "pending",
      "received_at": "2025-10-27T..."
    }
  ],
  "total": 1
}
```

---

### 方法 3: 使用 Python 测试脚本

#### 安装依赖

```powershell
pip install httpx
```

#### 运行测试脚本

```powershell
cd F:\project\MediaGenie1001\backend\media-service
python test_api_endpoints.py
```

**预期输出**:
```
�?PASSED - 健康检�?�?PASSED - Marketplace 健康检�?�?PASSED - Webhook 端点
�?PASSED - 事件列表
�?PASSED - Swagger UI

总计: 5/5 测试通过
```

---

## 📊 API 端点列表

| 端点 | 方法 | 描述 |
|------|------|------|
| `/health` | GET | 健康检�?|
| `/marketplace/health` | GET | Marketplace 健康检�?|
| `/marketplace/webhook` | POST | 接收 Webhook 事件 |
| `/marketplace/events` | GET | 获取事件列表 |
| `/docs` | GET | Swagger UI 文档 |
| `/redoc` | GET | ReDoc 文档 |
| `/openapi.json` | GET | OpenAPI 规范 |

---

## 🔍 调试技�?
### 查看实时日志

在启动服务的 PowerShell 窗口中，你会看到实时日志�?
```
INFO:     127.0.0.1:12345 - "GET /health HTTP/1.1" 200 OK
INFO:     127.0.0.1:12345 - "POST /marketplace/webhook HTTP/1.1" 200 OK
```

### 检查数据库

```powershell
# 查看 webhook_events �?psql -U postgres -d mediagenie -c "SELECT * FROM webhook_events;"

# 查看 subscriptions �?psql -U postgres -d mediagenie -c "SELECT * FROM subscriptions;"
```

### 常见问题

**问题**: 连接被拒�?```
curl : 无法连接到远程服务器
```

**解决方案**:
1. 确保服务已启�?(检�?PowerShell 窗口)
2. 确保端口 9001 没有被占�?3. 检查防火墙设置

---

**问题**: 404 Not Found
```json
{"detail": "Not Found"}
```

**解决方案**:
1. 检�?URL 是否正确
2. 检�?HTTP 方法 (GET vs POST)
3. 访问 `/docs` 查看正确的端�?
---

## �?测试清单

- [ ] 启动后端服务
- [ ] 访问 Swagger UI (`http://localhost:9001/docs`)
- [ ] 测试健康检查端�?- [ ] 测试 Marketplace 健康检�?- [ ] 发�?Webhook 事件
- [ ] 获取事件列表
- [ ] 检查数据库中的数据
- [ ] 运行 Python 测试脚本

---

## 🎉 成功标志

�?**所有测试通过�?*:
1. 所�?API 端点返回 200 �?201 状态码
2. 响应数据格式正确
3. 数据库中有新的事件记�?4. Swagger UI 可以访问

---

## 📝 下一�?
测试完成�?
1. 启动 Marketplace Portal (Flask 应用)
2. 测试完整的订阅激活流�?3. 继续 Phase 4 (前端 Azure AD 集成)

---

**准备好了吗？** 🚀

