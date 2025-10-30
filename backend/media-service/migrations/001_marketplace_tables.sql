-- ============================================
-- Azure Marketplace SaaS 集成数据库迁移脚本
-- 版本: 001
-- 日期: 2025-10-27
-- 说明: 创建用户、订阅、关联和事件表
-- ============================================

-- 启用 UUID 扩展 (如果还未启用)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 1. 用户账号表
-- ============================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Azure AD 身份信息
    azure_ad_oid VARCHAR(255) UNIQUE NOT NULL,  -- Azure AD Object ID (主标识)
    azure_ad_sub VARCHAR(255),                   -- Azure AD Subject (备用)
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    tenant_id VARCHAR(255) NOT NULL,             -- Azure AD Tenant ID
    
    -- 账号状态
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,

    -- 元数据 (使用 user_metadata 避免与保留字冲突)
    user_metadata JSONB DEFAULT '{}'::jsonb
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_users_azure_ad_oid ON users(azure_ad_oid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);

-- 注释
COMMENT ON TABLE users IS '用户账号表,存储 Azure AD 登录用户信息';
COMMENT ON COLUMN users.azure_ad_oid IS 'Azure AD Object ID,用户唯一标识';
COMMENT ON COLUMN users.tenant_id IS 'Azure AD Tenant ID,多租户隔离';


-- ============================================
-- 2. 订阅信息表
-- ============================================

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Marketplace 订阅标识
    subscription_id VARCHAR(255) UNIQUE NOT NULL,  -- Marketplace 分配的订阅 ID
    subscription_name VARCHAR(255),
    
    -- Offer 和 Plan 信息
    publisher_id VARCHAR(100),
    offer_id VARCHAR(100) NOT NULL,
    plan_id VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 1,
    
    -- 订阅状态
    -- PendingFulfillmentStart / Subscribed / Suspended / Unsubscribed
    status VARCHAR(50) NOT NULL,
    
    -- 购买者信息 (Purchaser)
    purchaser_email VARCHAR(255),
    purchaser_oid VARCHAR(255),
    purchaser_tenant_id VARCHAR(255),
    
    -- 受益人信息 (Beneficiary - 实际使用者)
    beneficiary_email VARCHAR(255),
    beneficiary_oid VARCHAR(255),
    beneficiary_tenant_id VARCHAR(255),
    
    -- 订阅期限
    term_start_date TIMESTAMP,
    term_end_date TIMESTAMP,
    term_unit VARCHAR(20),  -- P1M (月), P1Y (年)
    
    -- 标志位
    is_free_trial BOOLEAN DEFAULT FALSE,
    is_test BOOLEAN DEFAULT FALSE,
    auto_renew BOOLEAN DEFAULT TRUE,
    
    -- 会话和沙箱
    session_mode VARCHAR(50) DEFAULT 'None',
    sandbox_type VARCHAR(50) DEFAULT 'None',
    
    -- 允许的客户操作
    allowed_customer_operations JSONB DEFAULT '[]'::jsonb,
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 完整的 Marketplace 响应 (备份)
    raw_data JSONB
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_subscriptions_subscription_id ON subscriptions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_purchaser_email ON subscriptions(purchaser_email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_beneficiary_email ON subscriptions(beneficiary_email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_beneficiary_tenant_id ON subscriptions(beneficiary_tenant_id);

-- 注释
COMMENT ON TABLE subscriptions IS 'Azure Marketplace 订阅信息表';
COMMENT ON COLUMN subscriptions.subscription_id IS 'Marketplace 分配的订阅唯一 ID';
COMMENT ON COLUMN subscriptions.status IS '订阅状态: PendingFulfillmentStart, Subscribed, Suspended, Unsubscribed';
COMMENT ON COLUMN subscriptions.purchaser_email IS '购买者邮箱 (可能是公司管理员)';
COMMENT ON COLUMN subscriptions.beneficiary_email IS '受益人邮箱 (实际使用者)';


-- ============================================
-- 3. 用户-订阅关联表 (多对多)
-- ============================================

CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 关联
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    -- 角色权限
    role VARCHAR(50) DEFAULT 'user',  -- owner / admin / user
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 唯一约束
    UNIQUE(user_id, subscription_id)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_subscription_id ON user_subscriptions(subscription_id);

-- 注释
COMMENT ON TABLE user_subscriptions IS '用户-订阅多对多关联表';
COMMENT ON COLUMN user_subscriptions.role IS '用户角色: owner(所有者), admin(管理员), user(普通用户)';


-- ============================================
-- 4. Webhook 事件日志表
-- ============================================

CREATE TABLE IF NOT EXISTS webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 事件标识
    event_id VARCHAR(255) UNIQUE,  -- Marketplace 事件 ID (幂等性)
    activity_id VARCHAR(255),       -- 活动 ID
    
    -- 事件类型
    -- Subscribe / Unsubscribe / ChangePlan / ChangeQuantity / Suspend / Reinstate / Renew
    event_type VARCHAR(50) NOT NULL,
    
    -- 订阅信息
    subscription_id VARCHAR(255) NOT NULL,
    offer_id VARCHAR(100),
    publisher_id VARCHAR(100),
    plan_id VARCHAR(100),
    quantity INT,
    
    -- 事件状态
    event_status VARCHAR(50),  -- Success / Failure / InProgress
    
    -- 处理状态
    processing_status VARCHAR(50) DEFAULT 'pending',  
    -- pending / processing / completed / failed
    
    error_message TEXT,
    retry_count INT DEFAULT 0,
    
    -- 时间信息
    event_timestamp TIMESTAMP,      -- Marketplace 事件时间
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    
    -- 原始 Webhook payload
    raw_payload JSONB,
    
    -- 处理结果
    processing_result JSONB
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_subscription_id ON webhook_events(subscription_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_type ON webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processing_status ON webhook_events(processing_status);
CREATE INDEX IF NOT EXISTS idx_webhook_events_received_at ON webhook_events(received_at);

-- 注释
COMMENT ON TABLE webhook_events IS 'Marketplace Webhook 事件日志表';
COMMENT ON COLUMN webhook_events.event_id IS 'Marketplace 事件唯一 ID,用于幂等性检查';
COMMENT ON COLUMN webhook_events.processing_status IS '处理状态: pending(待处理), processing(处理中), completed(已完成), failed(失败)';


-- ============================================
-- 5. 更新现有 tasks 表 (添加订阅关联)
-- ============================================

-- 检查 tasks 表是否存在,如果存在则添加列
DO $$
BEGIN
    -- 检查 tasks 表是否存在
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name='tasks'
    ) THEN
        -- 添加 subscription_id 列
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name='tasks' AND column_name='subscription_id'
        ) THEN
            ALTER TABLE tasks ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);
            CREATE INDEX idx_tasks_subscription_id ON tasks(subscription_id);
            COMMENT ON COLUMN tasks.subscription_id IS '任务关联的订阅 ID,用于计费和权限控制';
        END IF;

        -- 添加 tenant_id 列
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name='tasks' AND column_name='tenant_id'
        ) THEN
            ALTER TABLE tasks ADD COLUMN tenant_id VARCHAR(255);
            CREATE INDEX idx_tasks_tenant_id ON tasks(tenant_id);
            COMMENT ON COLUMN tasks.tenant_id IS '租户 ID,用于多租户数据隔离';
        END IF;
    END IF;
END $$;


-- ============================================
-- 6. 自动更新 updated_at 触发器
-- ============================================

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 users 表创建触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为 subscriptions 表创建触发器
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 7. Row-Level Security (RLS) 配置
-- ============================================

-- 启用 RLS (可选,根据需求决定是否启用)
-- ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- 创建租户上下文函数
CREATE OR REPLACE FUNCTION current_tenant_id() 
RETURNS VARCHAR(255) AS $$
BEGIN
    RETURN current_setting('app.current_tenant_id', true);
END;
$$ LANGUAGE plpgsql STABLE;

-- 创建 RLS 策略 (示例,默认不启用)
-- CREATE POLICY tenant_isolation_policy ON tasks
--     USING (tenant_id = current_tenant_id());

-- CREATE POLICY tenant_isolation_policy ON subscriptions
--     USING (beneficiary_tenant_id = current_tenant_id());


-- ============================================
-- 8. 初始数据 (可选)
-- ============================================

-- 插入测试用户 (开发环境)
-- INSERT INTO users (azure_ad_oid, email, display_name, tenant_id) 
-- VALUES 
--     ('test-oid-001', 'test@example.com', 'Test User', 'test-tenant-001')
-- ON CONFLICT (azure_ad_oid) DO NOTHING;


-- ============================================
-- 9. 视图 (便捷查询)
-- ============================================

-- 创建用户订阅视图 (包含完整信息)
CREATE OR REPLACE VIEW v_user_subscriptions AS
SELECT 
    us.id AS user_subscription_id,
    u.id AS user_id,
    u.azure_ad_oid,
    u.email AS user_email,
    u.display_name AS user_name,
    u.tenant_id AS user_tenant_id,
    us.role AS user_role,
    s.id AS subscription_db_id,
    s.subscription_id,
    s.subscription_name,
    s.offer_id,
    s.plan_id,
    s.quantity,
    s.status AS subscription_status,
    s.is_free_trial,
    s.is_test,
    s.term_start_date,
    s.term_end_date,
    s.activated_at,
    s.created_at AS subscription_created_at,
    us.created_at AS relation_created_at
FROM user_subscriptions us
JOIN users u ON us.user_id = u.id
JOIN subscriptions s ON us.subscription_id = s.id;

COMMENT ON VIEW v_user_subscriptions IS '用户订阅视图,包含用户和订阅的完整信息';


-- 创建活跃订阅视图
CREATE OR REPLACE VIEW v_active_subscriptions AS
SELECT 
    s.*,
    COUNT(us.user_id) AS user_count
FROM subscriptions s
LEFT JOIN user_subscriptions us ON s.id = us.subscription_id
WHERE s.status = 'Subscribed'
GROUP BY s.id;

COMMENT ON VIEW v_active_subscriptions IS '活跃订阅视图,仅包含状态为 Subscribed 的订阅及用户数';


-- ============================================
-- 10. 存储过程 (便捷操作)
-- ============================================

-- 创建或更新用户 (幂等操作)
CREATE OR REPLACE FUNCTION upsert_user(
    p_azure_ad_oid VARCHAR(255),
    p_email VARCHAR(255),
    p_display_name VARCHAR(255),
    p_tenant_id VARCHAR(255)
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    INSERT INTO users (azure_ad_oid, email, display_name, tenant_id)
    VALUES (p_azure_ad_oid, p_email, p_display_name, p_tenant_id)
    ON CONFLICT (azure_ad_oid) 
    DO UPDATE SET 
        email = EXCLUDED.email,
        display_name = EXCLUDED.display_name,
        tenant_id = EXCLUDED.tenant_id,
        updated_at = CURRENT_TIMESTAMP,
        last_login = CURRENT_TIMESTAMP
    RETURNING id INTO v_user_id;
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION upsert_user IS '创建或更新用户 (幂等操作)';


-- 关联用户与订阅
CREATE OR REPLACE FUNCTION associate_user_subscription(
    p_user_id UUID,
    p_subscription_id UUID,
    p_role VARCHAR(50) DEFAULT 'user'
) RETURNS UUID AS $$
DECLARE
    v_relation_id UUID;
BEGIN
    INSERT INTO user_subscriptions (user_id, subscription_id, role)
    VALUES (p_user_id, p_subscription_id, p_role)
    ON CONFLICT (user_id, subscription_id) 
    DO UPDATE SET role = EXCLUDED.role
    RETURNING id INTO v_relation_id;
    
    RETURN v_relation_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION associate_user_subscription IS '关联用户与订阅 (幂等操作)';


-- ============================================
-- 11. 验证迁移
-- ============================================

-- 列出所有新创建的表
SELECT 
    tablename, 
    tableowner,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE tablename IN ('users', 'subscriptions', 'user_subscriptions', 'webhook_events')
ORDER BY tablename;

-- 列出所有索引
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE tablename IN ('users', 'subscriptions', 'user_subscriptions', 'webhook_events')
ORDER BY tablename, indexname;

-- 输出成功消息
DO $$
BEGIN
    RAISE NOTICE '✅ Migration 001 completed successfully!';
    RAISE NOTICE '📊 Created tables: users, subscriptions, user_subscriptions, webhook_events';
    RAISE NOTICE '🔍 Created views: v_user_subscriptions, v_active_subscriptions';
    RAISE NOTICE '⚙️ Created functions: upsert_user, associate_user_subscription';
END $$;
