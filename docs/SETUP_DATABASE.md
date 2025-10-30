# 数据库设置指�?
## 🎯 目标

�?MediaGenie 设置 PostgreSQL 数据库，用于测试 Marketplace 集成功能�?
---

## 📋 前提条件

你需要以下之一�?1. **Docker Desktop** (推荐) - 最简单的方式
2. **PostgreSQL 本地安装** - 如果你已经安装了 PostgreSQL

---

## 方法 1: 使用 Docker (推荐)

### 步骤 1: 启动 Docker Desktop

1. 打开 **Docker Desktop** 应用
2. 等待 Docker 完全启动 (任务栏图标变为绿�?
3. 确认 Docker 正在运行:
   ```powershell
   docker ps
   ```

### 步骤 2: 启动 PostgreSQL 容器

运行提供�?PowerShell 脚本:

```powershell
powershell -ExecutionPolicy Bypass -File start-postgres.ps1
```

或者手动运�?Docker 命令:

```powershell
docker run -d `
  --name mediagenie-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=password `
  -e POSTGRES_DB=mediagenie `
  -p 5432:5432 `
  postgres:15-alpine
```

### 步骤 3: 验证容器运行

```powershell
docker ps
```

你应该看�?`mediagenie-postgres` 容器正在运行�?
---

## 方法 2: 使用本地 PostgreSQL

### 步骤 1: 安装 PostgreSQL

如果还没有安装，从官网下�? https://www.postgresql.org/download/windows/

### 步骤 2: 启动 PostgreSQL 服务

```powershell
# 使用 Windows 服务管理�?services.msc

# 或使用命令行
net start postgresql-x64-15
```

### 步骤 3: 创建数据�?
```powershell
# 使用 psql 命令行工�?psql -U postgres

# �?psql 中执�?
CREATE DATABASE mediagenie;
\q
```

### 步骤 4: 更新 .env 文件

如果你的 PostgreSQL 配置不同，更�?`backend/media-service/.env`:

```bash
DATABASE_URL=postgresql+asyncpg://your_user:your_password@localhost:5432/mediagenie
```

---

## �?验证数据库连�?
运行快速测试脚�?

```powershell
python backend/media-service/quick_test.py
```

**预期输出**:
```
============================================================
测试 3: 检查数据库连接
============================================================
数据�?URL: postgresql://postgres:password@***
�?数据库连接成�?PostgreSQL 版本: PostgreSQL 15.x

�?数据库连接正�?```

---

## 🚀 下一�? 执行数据库迁�?
一旦数据库连接成功，执行迁移脚�?

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

## 🧪 运行完整测试

执行完整的数据库测试:

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

## 🐛 常见问题

### 问题 1: Docker Desktop 未启�?
**错误**: `error during connect: ... dockerDesktopLinuxEngine: The system cannot find the file specified`

**解决方案**:
1. 打开 Docker Desktop 应用
2. 等待完全启动
3. 重新运行脚本

---

### 问题 2: 端口 5432 已被占用

**错误**: `Bind for 0.0.0.0:5432 failed: port is already allocated`

**解决方案**:

**选项 A**: 停止现有�?PostgreSQL 服务
```powershell
net stop postgresql-x64-15
```

**选项 B**: 使用不同的端�?```powershell
docker run -d `
  --name mediagenie-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=password `
  -e POSTGRES_DB=mediagenie `
  -p 5433:5432 `
  postgres:15-alpine
```

然后更新 `.env`:
```bash
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5433/mediagenie
```

---

### 问题 3: 数据库连接被拒绝

**错误**: `远程计算机拒绝网络连接`

**解决方案**:
1. 确认 PostgreSQL 正在运行:
   ```powershell
   docker ps
   # �?   netstat -an | findstr 5432
   ```

2. 等待几秒钟让 PostgreSQL 完全启动:
   ```powershell
   Start-Sleep -Seconds 10
   python backend/media-service/quick_test.py
   ```

3. 检�?Docker 容器日志:
   ```powershell
   docker logs mediagenie-postgres
   ```

---

### 问题 4: 数据库已存在但无法连�?
**解决方案**: 重启容器
```powershell
docker restart mediagenie-postgres
Start-Sleep -Seconds 5
python backend/media-service/quick_test.py
```

---

## 🛠�?有用的命�?
### Docker 命令

```powershell
# 查看所有容�?docker ps -a

# 启动容器
docker start mediagenie-postgres

# 停止容器
docker stop mediagenie-postgres

# 删除容器
docker rm mediagenie-postgres

# 查看容器日志
docker logs mediagenie-postgres

# 进入容器 shell
docker exec -it mediagenie-postgres psql -U postgres -d mediagenie
```

### PostgreSQL 命令

```sql
-- 连接到数据库
\c mediagenie

-- 列出所有表
\dt

-- 查看表结�?\d subscriptions

-- 查询数据
SELECT * FROM subscriptions;

-- 退�?\q
```

---

## 📊 测试流程总结

```
1. 启动 Docker Desktop
   �?2. 运行 start-postgres.ps1
   �?3. 运行 quick_test.py (验证连接)
   �?4. 运行 run_migration.py (创建�?
   �?5. 运行 test_db_connection.py (完整测试)
   �?6. 启动后端服务 (uvicorn main:app)
   �?7. 测试 API 端点
```

---

## 🎉 成功标志

当你看到以下输出时，说明数据库设置成�?

```
�?数据库连接成�?�?所有表已创�?�?6/6 测试通过
```

现在你可以继续测�?Marketplace 功能了！

---

## 📚 相关文档

- [测试指南](./TESTING_GUIDE.md)
- [实施进度](./IMPLEMENTATION_PROGRESS.md)
- [数据库设置](../backend/media-service/DATABASE_SETUP.md)

