# 数据库设置指�?
本文档说明如何设置和初始�?MediaGenie �?PostgreSQL 数据库�?
---

## 📋 前提条件

1. **PostgreSQL 数据�?* (版本 12+)
2. **Python 环境** (已安装项目依�?
3. **环境变量配置** (DATABASE_URL)

---

## 🚀 快速开�?
### 方法 1: 使用 Python 脚本 (推荐)

```bash
# 1. 确保已设�?DATABASE_URL 环境变量
export DATABASE_URL="postgresql+asyncpg://user:password@host:5432/database"

# 2. 执行迁移脚本
cd backend/media-service
python run_migration.py
```

**输出示例**:
```
INFO:__main__:Connecting to database...
INFO:__main__:�?Database connection established
INFO:__main__:Reading migration file: migrations/001_marketplace_tables.sql
INFO:__main__:Executing migration...
INFO:__main__:�?Migration executed successfully
INFO:__main__:�?Created tables: subscriptions, user_subscriptions, users, webhook_events
INFO:__main__:�?Created views: v_active_subscriptions, v_user_subscriptions
INFO:__main__:�?Created functions: associate_user_subscription, current_tenant_id, upsert_user
============================================================
🎉 Migration completed successfully!
============================================================
```

---

### 方法 2: 使用 psql 命令�?
```bash
# 1. 连接到数据库
psql $DATABASE_URL

# 2. 执行迁移脚本
\i backend/media-service/migrations/001_marketplace_tables.sql

# 3. 验证表已创建
\dt

# 4. 查看表结�?\d users
\d subscriptions
\d user_subscriptions
\d webhook_events
```

---

## �?验证安装

### 1. 测试数据库连�?
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

... (更多测试)

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

### 2. 手动验证表结�?
```sql
-- 查看所有表
SELECT tablename FROM pg_tables 
WHERE tablename IN ('users', 'subscriptions', 'user_subscriptions', 'webhook_events');

-- 查看用户表结�?\d users

-- 查看订阅表结�?\d subscriptions

-- 查看视图
SELECT viewname FROM pg_views 
WHERE viewname IN ('v_user_subscriptions', 'v_active_subscriptions');

-- 查看函数
SELECT proname FROM pg_proc 
WHERE proname IN ('upsert_user', 'associate_user_subscription', 'current_tenant_id');
```

---

## 📊 数据库架�?
### 表结�?
#### 1. users (用户�?
- **主键**: `id` (UUID)
- **唯一�?*: `azure_ad_oid`, `email`
- **索引**: `azure_ad_oid`, `email`, `tenant_id`
- **用�?*: 存储 Azure AD 登录用户信息

#### 2. subscriptions (订阅�?
- **主键**: `id` (UUID)
- **唯一�?*: `subscription_id`
- **索引**: `subscription_id`, `status`, `plan_id`, `purchaser_email`, `beneficiary_email`, `beneficiary_tenant_id`
- **用�?*: 存储 Azure Marketplace 订阅信息

#### 3. user_subscriptions (用户-订阅关联�?
- **主键**: `id` (UUID)
- **外键**: `user_id` �?`users.id`, `subscription_id` �?`subscriptions.id`
- **唯一约束**: `(user_id, subscription_id)`
- **用�?*: 多对多关�?一个订阅可以有多个用户

#### 4. webhook_events (Webhook 事件日志�?
- **主键**: `id` (UUID)
- **唯一�?*: `event_id`
- **索引**: `event_id`, `subscription_id`, `event_type`, `processing_status`, `received_at`
- **用�?*: 记录所�?Webhook 事件,用于幂等性检查和审计

---

### 视图

#### 1. v_user_subscriptions
- **用�?*: 用户订阅视图,包含用户和订阅的完整信息
- **字段**: 用户信息 + 订阅信息 + 角色

#### 2. v_active_subscriptions
- **用�?*: 活跃订阅视图,仅包含状态为 `Subscribed` 的订�?- **字段**: 订阅信息 + 用户数量

---

### 存储过程

#### 1. upsert_user
- **用�?*: 创建或更新用�?(幂等操作)
- **参数**: `azure_ad_oid`, `email`, `display_name`, `tenant_id`
- **返回**: 用户 ID (UUID)

#### 2. associate_user_subscription
- **用�?*: 关联用户与订�?(幂等操作)
- **参数**: `user_id`, `subscription_id`, `role`
- **返回**: 关联 ID (UUID)

#### 3. current_tenant_id
- **用�?*: 获取当前租户 ID (用于 Row-Level Security)
- **返回**: 租户 ID (VARCHAR)

---

## 🔧 常见问题

### 问题 1: 连接失败

**错误**: `could not connect to server`

**解决方案**:
1. 检�?`DATABASE_URL` 环境变量是否正确
2. 确保 PostgreSQL 服务正在运行
3. 检查防火墙设置
4. 验证数据库用户权�?
```bash
# 测试连接
psql $DATABASE_URL -c "SELECT 1"
```

---

### 问题 2: 表已存在

**错误**: `relation "users" already exists`

**解决方案**:
迁移脚本使用 `CREATE TABLE IF NOT EXISTS`,不会报错。如果需要重新创建表:

```sql
-- ⚠️ 警告: 这会删除所有数�?
DROP TABLE IF EXISTS webhook_events CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 然后重新执行迁移
\i backend/media-service/migrations/001_marketplace_tables.sql
```

---

### 问题 3: 权限不足

**错误**: `permission denied for schema public`

**解决方案**:
```sql
-- 授予用户权限
GRANT ALL PRIVILEGES ON DATABASE your_database TO your_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;
```

---

## 📝 环境变量配置

### 开发环�?(.env)

```bash
# 数据库配�?DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/mediagenie

# 数据库连接池
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600
```

### 生产环境 (Azure App Service)

�?Azure Portal 配置以下环境变量:

```
DATABASE_URL=postgresql+asyncpg://user:pass@host.postgres.database.azure.com:5432/mediagenie?sslmode=require
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=40
```

---

## 🔄 数据库迁移流�?
### 本地开�?
```bash
# 1. 启动 PostgreSQL
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=password postgres:14

# 2. 创建数据�?createdb mediagenie

# 3. 执行迁移
python run_migration.py

# 4. 测试
python test_db_connection.py
```

---

### Azure 生产环境

```bash
# 1. 创建 Azure Database for PostgreSQL
az postgres server create \
  --resource-group MediaGenie-RG \
  --name mediagenie-db \
  --location eastus \
  --admin-user myadmin \
  --admin-password MyPassword123! \
  --sku-name B_Gen5_1

# 2. 配置防火墙规�?az postgres server firewall-rule create \
  --resource-group MediaGenie-RG \
  --server mediagenie-db \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# 3. 获取连接字符�?az postgres server show-connection-string \
  --server-name mediagenie-db

# 4. �?Azure Cloud Shell 执行迁移
export DATABASE_URL="postgresql+asyncpg://myadmin@mediagenie-db:MyPassword123!@mediagenie-db.postgres.database.azure.com:5432/postgres?sslmode=require"
python run_migration.py
```

---

## 📚 相关文档

- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [SQLAlchemy 文档](https://docs.sqlalchemy.org/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)

---

## �?下一�?
数据库设置完成后,继续:

1. **启动后端服务**: `uvicorn main:app --reload`
2. **测试 API 端点**: `curl http://localhost:9001/marketplace/health`
3. **查看 API 文档**: `http://localhost:9001/docs`

---

**需要帮�?** 查看 [QUICK_START_IMPLEMENTATION.md](../../docs/QUICK_START_IMPLEMENTATION.md)

