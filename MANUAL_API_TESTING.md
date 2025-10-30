# 🚀 手动 API 端点测试指南

> **目标**: 手动启动后端服务并测试所�?API 端点

---

## 📋 快速开�?(3 �?

### 步骤 1️⃣: 打开新的 PowerShell 窗口

**重要**: 不要�?VS Code 中运行，打开一个独立的 PowerShell 窗口

```powershell
# �?Win+R，输�?powershell，按 Enter
```

### 步骤 2️⃣: 启动后端服务

```powershell
cd F:\project\MediaGenie1001\backend\media-service
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

**等待看到这个消息**:
```
INFO:     Uvicorn running on http://0.0.0.0:9001
INFO:     Application startup complete
```

�?**服务已启动！**

---

### 步骤 3️⃣: 在浏览器中测�?
打开浏览器，访问:
```
http://localhost:9001/docs
```

你会看到 **Swagger UI** - 一个交互式�?API 文档界面�?
---

## 🧪 测试场景

### 场景 1: 健康检�?
**�?Swagger UI �?*:
1. 找到 `GET /health` 端点
2. 点击 "Try it out"
3. 点击 "Execute"
4. 查看响应 (应该�?200 OK)

**或在 PowerShell �?*:
```powershell
curl http://localhost:9001/health
```

---

### 场景 2: Marketplace 健康检�?
**�?Swagger UI �?*:
1. 找到 `GET /marketplace/health` 端点
2. 点击 "Try it out"
3. 点击 "Execute"
4. 查看响应

**或在 PowerShell �?*:
```powershell
curl http://localhost:9001/marketplace/health
```

---

### 场景 3: 发�?Webhook 事件

**�?Swagger UI �?*:
1. 找到 `POST /marketplace/webhook` 端点
2. 点击 "Try it out"
3. 在请求体中输�?
```json
{
  "id": "test-webhook-001",
  "activityId": "activity-001",
  "subscriptionId": "sub-test-001",
  "offerId": "offer-test",
  "publisherId": "publisher-test",
  "planId": "basic",
  "quantity": 1,
  "timeStamp": "2025-10-27T10:00:00Z",
  "action": "Subscribe",
  "status": "Success"
}
```
4. 点击 "Execute"
5. 查看响应 (应该�?200 �?201)

**或在 PowerShell �?*:
```powershell
$body = @{
    id = "test-webhook-001"
    activityId = "activity-001"
    subscriptionId = "sub-test-001"
    offerId = "offer-test"
    publisherId = "publisher-test"
    planId = "basic"
    quantity = 1
    timeStamp = "2025-10-27T10:00:00Z"
    action = "Subscribe"
    status = "Success"
} | ConvertTo-Json

curl -X POST http://localhost:9001/marketplace/webhook `
  -H "Content-Type: application/json" `
  -d $body
```

---

### 场景 4: 获取事件列表

**�?Swagger UI �?*:
1. 找到 `GET /marketplace/events` 端点
2. 点击 "Try it out"
3. 点击 "Execute"
4. 查看响应 (应该包含之前发送的事件)

**或在 PowerShell �?*:
```powershell
curl http://localhost:9001/marketplace/events
```

---

## 📊 预期结果

### �?所有测试通过�?
1. **健康检�?* - 返回 200 OK
   ```json
   {
     "status": "active",
     "service": "MediaGenie",
     "version": "1.0.0"
   }
   ```

2. **Marketplace 健康检�?* - 返回 200 OK
   ```json
   {
     "status": "active",
     "marketplace": {
       "webhook_endpoint": "/api/marketplace/webhook"
     }
   }
   ```

3. **Webhook 事件** - 返回 200 �?201
   ```json
   {
     "status": "received",
     "event_id": "test-webhook-001",
     "message": "Webhook event received"
   }
   ```

4. **事件列表** - 返回 200 OK
   ```json
   {
     "events": [
       {
         "id": "...",
         "event_id": "test-webhook-001",
         "event_type": "Subscribe"
       }
     ],
     "total": 1
   }
   ```

---

## 🔍 实时日志

在启动服务的 PowerShell 窗口中，你会看到实时日志�?
```
INFO:     127.0.0.1:12345 - "GET /health HTTP/1.1" 200 OK
INFO:     127.0.0.1:12345 - "POST /marketplace/webhook HTTP/1.1" 200 OK
INFO:     127.0.0.1:12345 - "GET /marketplace/events HTTP/1.1" 200 OK
```

---

## �?常见问题

### 问题 1: 连接被拒�?
```
curl : 无法连接到远程服务器
```

**解决方案**:
- �?确保服务已启�?(检�?PowerShell 窗口)
- �?确保端口 9001 没有被占�?- �?等待 "Application startup complete" 消息

---

### 问题 2: 模块未找�?
```
ModuleNotFoundError: No module named 'fastapi'
```

**解决方案**:
```powershell
pip install fastapi uvicorn
```

---

### 问题 3: 数据库连接错�?
```
sqlalchemy.exc.OperationalError: could not connect to server
```

**解决方案**:
- �?确保 PostgreSQL 容器正在运行
- �?运行: `docker ps` 检查容器状�?- �?如果容器未运行，执行: `powershell -ExecutionPolicy Bypass -File start-postgres.ps1`

---

## 📝 测试清单

- [ ] 打开新的 PowerShell 窗口
- [ ] 启动后端服务 (`python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload`)
- [ ] 等待 "Application startup complete" 消息
- [ ] 访问 `http://localhost:9001/docs`
- [ ] 测试 `/health` 端点
- [ ] 测试 `/marketplace/health` 端点
- [ ] 测试 `/marketplace/webhook` 端点 (POST)
- [ ] 测试 `/marketplace/events` 端点
- [ ] 检查实时日�?- [ ] 验证数据库中的数�?
---

## 🎉 成功标志

�?**当你看到这些时，说明测试成功**:

1. �?服务启动消息: `Uvicorn running on http://0.0.0.0:9001`
2. �?Swagger UI 可以访问: `http://localhost:9001/docs`
3. �?所�?API 端点返回 200 �?201 状态码
4. �?实时日志显示请求被处�?5. �?数据库中有新的事件记�?
---

## 🚀 下一�?
测试完成�?

1. **启动 Marketplace Portal**
   ```powershell
   cd F:\project\MediaGenie1001\marketplace-portal
   python app.py
   ```

2. **测试完整的订阅激活流�?*
   - 访问 `http://localhost:5000/landing?token=test-token`

3. **继续 Phase 4 - 前端 Azure AD 集成**

---

**现在就开始测试吧�?* 🚀

**需要帮助？** 告诉我你遇到的任何问题！

