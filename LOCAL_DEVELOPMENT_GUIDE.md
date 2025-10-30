# 🚀 本地开发和测试完整指南

> **目标**: 在本地启动完整的 MediaGenie 应用并进行测�? 
> **预计时间**: 30 分钟  
> **难度**: �?简�?
---

## 📋 前置条件检�?
### �?必需的工�?
- �?Python 3.13+ (已安�?
- �?Node.js 18+ (已安�?
- �?PostgreSQL 15 (Docker 容器)
- �?Git (已安�?
- �?VS Code 或其他编辑器

### �?验证环境

```bash
# 检�?Python
python --version  # 应该�?3.13+

# 检�?Node.js
node --version    # 应该�?18+
npm --version     # 应该�?9+

# 检�?Docker
docker --version  # 应该�?20+
```

---

## 🗄�?步骤 1: 启动 PostgreSQL 数据�?
### 方式 A: 使用 Docker (推荐)

```bash
# 启动 PostgreSQL 容器
docker run -d \
  --name mediagenie-postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=mediagenie \
  -p 5432:5432 \
  postgres:15-alpine

# 验证容器运行
docker ps | grep mediagenie-postgres
```

### 方式 B: 使用现有容器

```bash
# 如果容器已存在但未运�?docker start mediagenie-postgres

# 验证
docker ps | grep mediagenie-postgres
```

### 验证数据库连�?
```bash
# 使用 psql 连接
psql -U postgres -d mediagenie -h localhost -c "SELECT 1"

# 或使�?Python
python -c "
import asyncpg
import asyncio

async def test():
    conn = await asyncpg.connect('postgresql://postgres:password@localhost/mediagenie')
    result = await conn.fetchval('SELECT 1')
    print(f'�?数据库连接成�? {result}')
    await conn.close()

asyncio.run(test())
"
```

---

## 🔧 步骤 2: 执行数据库迁�?
### 执行基础迁移

```bash
cd backend/media-service

# 执行基础表创�?python run_migration.py

# 预期输出:
# �?迁移完成�?# 📊 已创建的�?
#   �?users
#   �?subscriptions
#   �?user_subscriptions
#   �?webhook_events
```

### 执行 RLS 迁移 (可�?

```bash
# 执行行级安全迁移
python run_rls_migration.py

# 预期输出:
# �?RLS 迁移完成�?# 📊 已启用的功能:
#   �?行级安全 (RLS)
#   �?租户隔离策略
#   �?审计日志系统
```

---

## 🎯 步骤 3: 启动后端服务

### 在新�?PowerShell 终端�?
```bash
cd backend/media-service

# 安装依赖 (如果还没�?
pip install -r requirements.txt

# 启动 FastAPI 服务
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload

# 预期输出:
# INFO:     Uvicorn running on http://0.0.0.0:9001
# INFO:     Application startup complete
```

### 验证后端服务

```bash
# 在另一个终端中测试
curl http://localhost:9001/health

# 预期响应:
# {"status":"active","service":"MediaGenie","version":"1.0.0"}
```

---

## 🎨 步骤 4: 启动前端应用

### 在新�?PowerShell 终端�?
```bash
cd frontend

# 安装依赖 (如果还没�?
npm install

# 启动前端应用
npm start

# 预期输出:
# Compiled successfully!
# You can now view mediagenie-frontend in the browser.
# Local: http://localhost:3000
```

### 验证前端应用

- 打开浏览器访�? `http://localhost:3000`
- 应该看到 MediaGenie 应用界面
- 点击 "Azure AD 登录" 按钮

---

## 🌐 步骤 5: 启动 Marketplace Portal (可�?

### 在新�?PowerShell 终端�?
```bash
cd marketplace-portal

# 安装依赖 (如果还没�?
pip install -r requirements.txt

# 启动 Marketplace Portal
python app.py

# 预期输出:
# Running on http://127.0.0.1:5000
```

### 访问 Marketplace Portal

- 打开浏览器访�? `http://localhost:5000`
- 应该看到 Marketplace Portal 界面

---

## 🧪 步骤 6: 测试 API 端点

### 使用 Swagger UI 测试

1. 打开浏览器访�? `http://localhost:9001/docs`
2. 你会看到 Swagger UI 界面
3. 展开各个端点并点�?"Try it out"

### 测试健康检�?
```bash
# 后端健康检�?curl http://localhost:9001/health

# Marketplace 健康检�?curl http://localhost:9001/marketplace/health
```

### 测试 Webhook

```bash
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "webhook-test-001",
    "activityId": "activity-001",
    "subscriptionId": "sub-test-001",
    "offerId": "offer-test",
    "publisherId": "publisher-test",
    "planId": "basic",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'
```

### 查询事件

```bash
curl http://localhost:9001/marketplace/events
```

---

## 📊 步骤 7: 验证数据�?
### 查看创建的数�?
```bash
# 连接到数据库
psql -U postgres -d mediagenie

# 查看用户�?SELECT * FROM users;

# 查看订阅�?SELECT * FROM subscriptions;

# 查看事件�?SELECT * FROM webhook_events;

# 查看审计日志 (如果执行�?RLS 迁移)
SELECT * FROM audit_logs;
```

---

## 🎯 完整的启动流�?(快速版)

### 一键启动所有服�?
**创建启动脚本** `start-all.ps1`:

```powershell
# 启动 PostgreSQL
Write-Host "🗄�? 启动 PostgreSQL..." -ForegroundColor Green
docker start mediagenie-postgres
Start-Sleep -Seconds 2

# 执行迁移
Write-Host "📊 执行数据库迁�?.." -ForegroundColor Green
cd backend/media-service
python run_migration.py

# 启动后端
Write-Host "🔧 启动后端服务..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend/media-service; python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload"
Start-Sleep -Seconds 3

# 启动前端
Write-Host "🎨 启动前端应用..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm start"
Start-Sleep -Seconds 3

# 启动 Marketplace Portal
Write-Host "🌐 启动 Marketplace Portal..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd marketplace-portal; python app.py"

Write-Host "�?所有服务已启动�? -ForegroundColor Green
Write-Host "📍 后端 API: http://localhost:9001/docs" -ForegroundColor Cyan
Write-Host "📍 前端应用: http://localhost:3000" -ForegroundColor Cyan
Write-Host "📍 Marketplace: http://localhost:5000" -ForegroundColor Cyan
```

运行脚本:
```bash
.\start-all.ps1
```

---

## 📈 测试场景

### 场景 1: 健康检�?
```bash
# 验证所有服务都在运�?curl http://localhost:9001/health
curl http://localhost:9001/marketplace/health
```

### 场景 2: 发�?Webhook 事件

```bash
# 发送订阅事�?curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"id":"test-1","action":"Subscribe",...}'

# 查询事件
curl http://localhost:9001/marketplace/events
```

### 场景 3: 前端登录

1. 打开 `http://localhost:3000`
2. 点击 "Azure AD 登录"
3. 使用 Azure AD 账户登录
4. 验证登录成功

### 场景 4: 数据库隔�?
```bash
# 设置租户上下�?psql -U postgres -d mediagenie

SET app.current_tenant_id = 'tenant-a';
SELECT * FROM users;  -- 只能看到租户 A 的用�?
SET app.current_tenant_id = 'tenant-b';
SELECT * FROM users;  -- 只能看到租户 B 的用�?```

---

## 🔍 调试技�?
### 查看实时日志

```bash
# 后端日志
tail -f backend/media-service/logs/media-service.log

# 前端日志
# 打开浏览器开发者工�?(F12) -> Console

# 数据库日�?docker logs -f mediagenie-postgres
```

### 重启服务

```bash
# 重启后端 (在启动后端的终端中按 Ctrl+C，然后重新运�?
# 重启前端 (在启动前端的终端中按 Ctrl+C，然后重新运�?
# 重启数据�?docker restart mediagenie-postgres
```

### 清除缓存

```bash
# 清除 Python 缓存
find . -type d -name __pycache__ -exec rm -r {} +

# 清除 Node 缓存
rm -rf frontend/node_modules frontend/package-lock.json
npm install

# 清除数据�?docker exec mediagenie-postgres psql -U postgres -d mediagenie -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

---

## �?完成检�?
- [ ] PostgreSQL 数据库已启动
- [ ] 数据库迁移已执行
- [ ] 后端服务已启�?(端口 9001)
- [ ] 前端应用已启�?(端口 3000)
- [ ] Marketplace Portal 已启�?(端口 5000)
- [ ] 所�?API 端点都正常工�?- [ ] 前端可以访问
- [ ] 数据库中有数�?
---

## 🎉 成功标志

�?**当你看到这些时，说明本地开发环境已就绪**:

1. �?后端服务在线: `http://localhost:9001/health` 返回 200
2. �?前端应用在线: `http://localhost:3000` 可以访问
3. �?Marketplace Portal 在线: `http://localhost:5000` 可以访问
4. �?数据库连接正�?5. �?API 端点正常工作
6. �?前端可以调用后端 API
7. �?数据库中有数�?
---

## 📞 常见问题

### Q: 后端无法启动�?A: 检�?Python 版本、依赖安装、数据库连接

### Q: 前端无法启动�?A: 检�?Node.js 版本、npm 依赖、端口占�?
### Q: 数据库连接失败？
A: 检�?Docker 容器是否运行、密码是否正�?
### Q: 端口已被占用�?A: 修改端口号或关闭占用端口的应�?
---

**准备好了吗？** 按照步骤 1-7 启动所有服务！

**需要帮助？** 查看 `QUICK_REFERENCE.md` 或告诉我你遇到的问题�?
