-- ============================================
-- 多租户数据隔离 - 行级安全策略 (RLS)
-- 版本: 002
-- 日期: 2025-10-27
-- 说明: 实现租户级别的数据隔离和权限控制
-- ============================================

-- ============================================
-- 1. 启用行级安全 (RLS)
-- ============================================

-- 为 users 表启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 为 subscriptions 表启用 RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- 为 user_subscriptions 表启用 RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 为 webhook_events 表启用 RLS
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. 创建租户上下文函数
-- ============================================

-- 获取当前租户 ID
CREATE OR REPLACE FUNCTION get_current_tenant_id() RETURNS VARCHAR AS $$
BEGIN
  -- 从 JWT 令牌中获取租户 ID
  -- 在应用层设置: SET app.current_tenant_id = 'tenant-id'
  RETURN COALESCE(
    current_setting('app.current_tenant_id', true),
    'default-tenant'
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- 获取当前用户 ID
CREATE OR REPLACE FUNCTION get_current_user_id() RETURNS UUID AS $$
BEGIN
  -- 从 JWT 令牌中获取用户 ID
  -- 在应用层设置: SET app.current_user_id = 'user-id'
  RETURN COALESCE(
    (current_setting('app.current_user_id', true))::UUID,
    NULL::UUID
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 3. Users 表 - RLS 策略
-- ============================================

-- 用户只能查看同一租户的用户
CREATE POLICY users_tenant_isolation ON users
  FOR SELECT
  USING (tenant_id = get_current_tenant_id());

-- 用户只能更新自己的信息
CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (id = get_current_user_id() AND tenant_id = get_current_tenant_id())
  WITH CHECK (id = get_current_user_id() AND tenant_id = get_current_tenant_id());

-- 用户只能删除自己的信息
CREATE POLICY users_delete_own ON users
  FOR DELETE
  USING (id = get_current_user_id() AND tenant_id = get_current_tenant_id());

-- 允许插入新用户（注册时）
CREATE POLICY users_insert_own ON users
  FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

-- ============================================
-- 4. Subscriptions 表 - RLS 策略
-- ============================================

-- 用户只能查看同一租户的订阅
CREATE POLICY subscriptions_tenant_isolation ON subscriptions
  FOR SELECT
  USING (tenant_id = get_current_tenant_id());

-- 用户只能更新同一租户的订阅
CREATE POLICY subscriptions_update_tenant ON subscriptions
  FOR UPDATE
  USING (tenant_id = get_current_tenant_id())
  WITH CHECK (tenant_id = get_current_tenant_id());

-- 用户只能删除同一租户的订阅
CREATE POLICY subscriptions_delete_tenant ON subscriptions
  FOR DELETE
  USING (tenant_id = get_current_tenant_id());

-- 允许插入新订阅
CREATE POLICY subscriptions_insert_tenant ON subscriptions
  FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

-- ============================================
-- 5. User_Subscriptions 表 - RLS 策略
-- ============================================

-- 用户只能查看自己的订阅关联
CREATE POLICY user_subscriptions_select ON user_subscriptions
  FOR SELECT
  USING (
    user_id = get_current_user_id() OR
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE subscriptions.id = user_subscriptions.subscription_id
      AND subscriptions.tenant_id = get_current_tenant_id()
    )
  );

-- 用户只能更新自己的订阅关联
CREATE POLICY user_subscriptions_update ON user_subscriptions
  FOR UPDATE
  USING (user_id = get_current_user_id())
  WITH CHECK (user_id = get_current_user_id());

-- 用户只能删除自己的订阅关联
CREATE POLICY user_subscriptions_delete ON user_subscriptions
  FOR DELETE
  USING (user_id = get_current_user_id());

-- 允许插入新的订阅关联
CREATE POLICY user_subscriptions_insert ON user_subscriptions
  FOR INSERT
  WITH CHECK (user_id = get_current_user_id());

-- ============================================
-- 6. Webhook_Events 表 - RLS 策略
-- ============================================

-- 用户只能查看同一租户的事件
CREATE POLICY webhook_events_tenant_isolation ON webhook_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE subscriptions.id = webhook_events.subscription_id
      AND subscriptions.tenant_id = get_current_tenant_id()
    )
  );

-- 系统可以插入事件（不受 RLS 限制）
CREATE POLICY webhook_events_insert ON webhook_events
  FOR INSERT
  WITH CHECK (true);

-- 系统可以更新事件状态
CREATE POLICY webhook_events_update ON webhook_events
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- ============================================
-- 7. 创建审计日志表
-- ============================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 审计信息
    tenant_id VARCHAR(255) NOT NULL,
    user_id UUID,
    action VARCHAR(50) NOT NULL,  -- SELECT, INSERT, UPDATE, DELETE
    table_name VARCHAR(255) NOT NULL,
    record_id UUID,
    
    -- 变更内容
    old_values JSONB,
    new_values JSONB,
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 索引
    CONSTRAINT audit_logs_tenant_fk FOREIGN KEY (tenant_id) REFERENCES users(tenant_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- 为审计日志表启用 RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己租户的审计日志
CREATE POLICY audit_logs_tenant_isolation ON audit_logs
  FOR SELECT
  USING (tenant_id = get_current_tenant_id());

-- ============================================
-- 8. 创建审计触发器
-- ============================================

-- 审计函数
CREATE OR REPLACE FUNCTION audit_trigger_func() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, table_name, record_id, new_values)
    VALUES (
      get_current_tenant_id(),
      get_current_user_id(),
      'INSERT',
      TG_TABLE_NAME,
      NEW.id,
      row_to_json(NEW)
    );
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, table_name, record_id, old_values, new_values)
    VALUES (
      get_current_tenant_id(),
      get_current_user_id(),
      'UPDATE',
      TG_TABLE_NAME,
      NEW.id,
      row_to_json(OLD),
      row_to_json(NEW)
    );
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (tenant_id, user_id, action, table_name, record_id, old_values)
    VALUES (
      get_current_tenant_id(),
      get_current_user_id(),
      'DELETE',
      TG_TABLE_NAME,
      OLD.id,
      row_to_json(OLD)
    );
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 为 users 表创建审计触发器
CREATE TRIGGER audit_users_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- 为 subscriptions 表创建审计触发器
CREATE TRIGGER audit_subscriptions_trigger
AFTER INSERT OR UPDATE OR DELETE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- ============================================
-- 9. 创建权限检查函数
-- ============================================

-- 检查用户是否有权访问订阅
CREATE OR REPLACE FUNCTION check_subscription_access(sub_id UUID) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM subscriptions
    WHERE id = sub_id
    AND tenant_id = get_current_tenant_id()
  );
END;
$$ LANGUAGE plpgsql;

-- 检查用户是否是订阅的所有者
CREATE OR REPLACE FUNCTION check_subscription_owner(sub_id UUID) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_subscriptions
    WHERE subscription_id = sub_id
    AND user_id = get_current_user_id()
    AND role = 'owner'
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 10. 创建视图用于简化查询
-- ============================================

-- 用户可访问的订阅视图
CREATE OR REPLACE VIEW user_accessible_subscriptions AS
SELECT s.*
FROM subscriptions s
WHERE s.tenant_id = get_current_tenant_id();

-- 用户的订阅关联视图
CREATE OR REPLACE VIEW user_subscription_details AS
SELECT 
  us.id,
  us.user_id,
  us.subscription_id,
  us.role,
  s.subscription_id as marketplace_subscription_id,
  s.plan_id,
  s.status,
  s.purchaser_email,
  s.beneficiary_email
FROM user_subscriptions us
JOIN subscriptions s ON us.subscription_id = s.id
WHERE us.user_id = get_current_user_id()
AND s.tenant_id = get_current_tenant_id();

-- ============================================
-- 11. 授予权限
-- ============================================

-- 授予公共角色对函数的执行权限
GRANT EXECUTE ON FUNCTION get_current_tenant_id() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_current_user_id() TO PUBLIC;
GRANT EXECUTE ON FUNCTION check_subscription_access(UUID) TO PUBLIC;
GRANT EXECUTE ON FUNCTION check_subscription_owner(UUID) TO PUBLIC;

-- 授予公共角色对视图的查询权限
GRANT SELECT ON user_accessible_subscriptions TO PUBLIC;
GRANT SELECT ON user_subscription_details TO PUBLIC;

-- ============================================
-- 12. 迁移完成
-- ============================================

-- 记录迁移完成
DO $$
BEGIN
  RAISE NOTICE '✅ 多租户数据隔离迁移完成';
  RAISE NOTICE '✅ 已启用行级安全 (RLS)';
  RAISE NOTICE '✅ 已创建租户隔离策略';
  RAISE NOTICE '✅ 已创建审计日志系统';
  RAISE NOTICE '✅ 已创建权限检查函数';
END $$;

