# MediaGenie 数据库快速设置脚本
# 用于 Azure Database for PostgreSQL

# 1. 连接到数据库 (替换为你的实际连接字符串)
# psql "postgresql://mediagenie_admin:YOUR_PASSWORD@mediagenie-demo-db.postgres.database.azure.com:5432/postgres?sslmode=require"

# 2. 运行以下SQL命令：

# 创建数据库
CREATE DATABASE mediagenie_demo;

# 切换到新数据库
\c mediagenie_demo

# 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

# 创建用户表 (简化版)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    azure_ad_oid VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(255),
    tenant_id VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

# 创建会话表 (用于存储用户会话)
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    session_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

# 创建索引
CREATE INDEX IF NOT EXISTS idx_users_azure_ad_oid ON users(azure_ad_oid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);

# 插入测试用户 (可选)
-- INSERT INTO users (azure_ad_oid, email, display_name, tenant_id)
-- VALUES ('test-user-oid', 'test@example.com', 'Test User', 'test-tenant-id');

# 验证设置
SELECT 'Database setup complete!' as status;