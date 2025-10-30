# MediaGenie Azure Marketplace 实施计划

> **项目状态分析与完善计划**  
> **日期**: 2025�?0�?7�? 
> **目标**: �?MediaGenie 完善为生产级 Azure Marketplace SaaS 产品

---

## 📊 当前状态评�?
### �?已完成的功能

| 模块 | 状�?| 完成�?| 说明 |
|------|------|--------|------|
| **Azure AD 认证** | �?完成 | 100% | `auth_middleware.py` 已实现完整的 JWT 验证 |
| **配置管理** | �?完成 | 100% | `config.py` 包含所有必需的配置项 |
| **SaaS API 客户�?* | �?完成 | 100% | `saas_fulfillment_client.py` 实现了所�?API |
| **Webhook 处理�?* | �?完成 | 90% | `marketplace_webhook.py` 已实�?需完善签名验证 |
| **数据库迁移脚�?* | �?完成 | 100% | `001_marketplace_tables.sql` 包含所有表结构 |
| **Landing Page** | ⚠️ 部分完成 | 60% | 静态页面已完成,需集成 Resolve/Activate API |
| **Marketplace 路由** | ⚠️ 部分完成 | 70% | 基础路由已完�?使用内存存储 |

### �?需要完善的功能

| 功能 | 优先�?| 预计工时 | 说明 |
|------|--------|---------|------|
| **数据库集�?* | 🔴 �?| 4小时 | 替换内存存储�?PostgreSQL |
| **Landing Page 激活流�?* | 🔴 �?| 3小时 | 集成 Resolve + Activate API |
| **Webhook 签名验证** | 🔴 �?| 2小时 | 实现 HMAC-SHA256 签名验证 |
| **前端 Azure AD 登录** | 🟡 �?| 4小时 | 集成 MSAL.js |
| **多租户数据隔�?* | 🟡 �?| 3小时 | 实现 Row-Level Security |
| **订阅权限控制** | 🟡 �?| 2小时 | 基于订阅状态控制功能访�?|
| **测试用例** | 🟢 �?| 4小时 | 单元测试和集成测�?|

---

## 🎯 实施计划（分阶段�?
### Phase 1: 核心功能完善�?-2天）

#### 任务 1.1: 数据库集�?⭐⭐�?
**目标**: 将内存存储替换为 PostgreSQL

**文件修改**:
- `backend/media-service/main.py` - 集成数据库连�?- `backend/media-service/marketplace.py` - 使用数据库存储订�?
**步骤**:
1. 执行数据库迁移脚�?`001_marketplace_tables.sql`
2. 创建 `database.py` 模块（如果不存在�?3. 修改 `marketplace.py` 中的订阅管理逻辑
4. 测试数据库连接和 CRUD 操作

**验收标准**:
- �?数据库表创建成功
- �?订阅数据持久化到数据�?- �?Webhook 事件记录�?`webhook_events` �?
---

#### 任务 1.2: Landing Page 激活流�?⭐⭐�?
**目标**: 实现完整的订阅激活流�?
**文件修改**:
- `marketplace-portal/app.py` - 集成 SaaS API
- `marketplace-portal/templates/landing.html` - 添加激活按钮和逻辑

**步骤**:
1. �?Landing Page 接收 `token` 参数时调�?Resolve API
2. 显示订阅详情（计划、数量、购买者信息）
3. 用户点击"激�?按钮时调�?Activate API
4. 激活成功后重定向到前端应用

**验收标准**:
- �?Resolve API 调用成功，显示订阅信�?- �?Activate API 调用成功，订阅状态变�?`Subscribed`
- �?用户和订阅关联创建成�?
---

#### 任务 1.3: Webhook 签名验证 ⭐⭐�?
**目标**: 实现生产�?Webhook 安全验证

**文件修改**:
- `backend/media-service/marketplace_webhook.py` - 实现签名验证

**步骤**:
1. 实现 HMAC-SHA256 签名验证函数
2. �?Webhook 端点中验�?`x-ms-marketplace-token` header
3. 添加签名验证失败的错误处�?4. 记录验证失败的请求到日志

**验收标准**:
- �?签名验证函数实现正确
- �?无效签名的请求返�?401 Unauthorized
- �?有效签名的请求正常处�?
---

### Phase 2: 前端集成�?天）

#### 任务 2.1: 前端 Azure AD 登录 ⭐⭐

**目标**: 集成 MSAL.js 实现 Azure AD 单点登录

**文件创建/修改**:
- `frontend/src/services/authService.ts` - 新建 MSAL 服务
- `frontend/src/components/LoginButton.tsx` - 新建登录按钮组件
- `frontend/src/store/slices/authSlice.ts` - 更新认证状态管�?
**步骤**:
1. 安装 `@azure/msal-browser` �?`@azure/msal-react`
2. 配置 MSAL 实例（Client ID, Authority, Redirect URI�?3. 创建登录/登出组件
4. 更新 API 调用，添�?Authorization header
5. 实现 token 刷新机制

**验收标准**:
- �?用户可以通过 Microsoft 账号登录
- �?登录后显示用户名和邮�?- �?API 请求自动携带 JWT token
- �?Token 过期后自动刷�?
---

### Phase 3: 多租户和权限控制�?天）

#### 任务 3.1: 多租户数据隔�?⭐⭐

**目标**: 实现租户级别的数据隔�?
**文件修改**:
- `backend/media-service/main.py` - 添加 tenant_id 过滤
- `backend/media-service/migrations/002_add_tenant_id.sql` - 新建迁移脚本

**步骤**:
1. �?`tasks` 表添�?`tenant_id` �?2. 创建 Row-Level Security 策略
3. 在所有查询中添加 `tenant_id` 过滤
4. 测试跨租户数据访问（应该被阻止）

**验收标准**:
- �?用户只能看到自己租户的数�?- �?跨租户访问被阻止
- �?性能测试通过（索引优化）

---

#### 任务 3.2: 订阅权限控制 ⭐⭐

**目标**: 基于订阅状态控制功能访�?
**文件修改**:
- `backend/media-service/auth_middleware.py` - 添加订阅检�?- `backend/media-service/main.py` - �?API 端点添加权限检�?
**步骤**:
1. 创建 `check_subscription_active` 依赖函数
2. 在需要订阅的 API 端点添加依赖
3. 订阅状态为 `Suspended` �?`Unsubscribed` 时返�?403
4. 添加友好的错误消�?
**验收标准**:
- �?活跃订阅用户可以正常使用功能
- �?暂停/取消订阅用户被阻止访�?- �?错误消息清晰友好

---

### Phase 4: 测试和部署（1天）

#### 任务 4.1: 单元测试 �?
**目标**: 编写核心模块的单元测�?
**文件创建**:
- `backend/media-service/tests/test_auth_middleware.py`
- `backend/media-service/tests/test_saas_fulfillment_client.py`
- `backend/media-service/tests/test_marketplace_webhook.py`

**测试覆盖**:
- Azure AD Token 验证（有�?过期/无效 audience�?- SaaS API 调用（Resolve/Activate/Update/Delete�?- Webhook 事件处理（Subscribe/Unsubscribe/ChangePlan�?- 签名验证（有�?无效签名�?
**验收标准**:
- �?测试覆盖�?> 80%
- �?所有测试通过
- �?CI/CD 集成

---

#### 任务 4.2: 集成测试 �?
**目标**: 端到端流程测�?
**测试场景**:
1. 完整订阅激活流�?2. 用户登录�?API 调用
3. Webhook 事件处理
4. 订阅变更和取�?
**验收标准**:
- �?所有场景测试通过
- �?性能测试通过（响应时�?< 2秒）
- �?负载测试通过�?00 并发用户�?
---

#### 任务 4.3: 生产部署 ⭐⭐�?
**目标**: 部署�?Azure 生产环境

**步骤**:
1. 配置生产环境变量
2. 执行数据库迁�?3. 部署 Backend Service
4. 部署 Marketplace Portal
5. 部署 Frontend
6. 配置 Partner Center

**验收标准**:
- �?所有服务健康检查通过
- �?Landing Page 可访�?- �?Webhook 端点可访�?- �?前端登录功能正常

---

## 📋 详细任务清单

### 立即开始（今天�?
- [ ] **Task 1**: 执行数据库迁移脚�?- [ ] **Task 2**: 修改 `marketplace.py` 使用数据库存�?- [ ] **Task 3**: 实现 Landing Page Resolve API 调用
- [ ] **Task 4**: 实现 Landing Page Activate API 调用
- [ ] **Task 5**: 实现 Webhook 签名验证

### 明天

- [ ] **Task 6**: 安装和配�?MSAL.js
- [ ] **Task 7**: 创建前端登录组件
- [ ] **Task 8**: 更新 API 调用添加 Authorization header
- [ ] **Task 9**: �?tasks 表添�?tenant_id
- [ ] **Task 10**: 实现订阅权限检�?
### 后天

- [ ] **Task 11**: 编写单元测试
- [ ] **Task 12**: 编写集成测试
- [ ] **Task 13**: 部署到生产环�?- [ ] **Task 14**: 配置 Partner Center
- [ ] **Task 15**: 最终验证测�?
---

## 🔧 技术债务和优�?
### 当前技术债务

1. **内存存储** �?需要替换为数据�?2. **签名验证占位�?* �?需要实现真实验�?3. **静�?Landing Page** �?需要动态激活流�?4. **缺少前端认证** �?需要集�?MSAL.js
5. **缺少测试** �?需要编写测试用�?
### 性能优化建议

1. **数据库索�?*: �?`tenant_id`, `subscription_id`, `azure_ad_oid` 添加索引
2. **缓存**: 使用 Redis 缓存订阅状态和用户信息
3. **异步处理**: Webhook 事件使用后台任务处理
4. **连接�?*: 配置合理的数据库连接池大�?
---

## 📊 预计工期总结

| 阶段 | 任务�?| 预计工时 | 完成日期 |
|------|--------|---------|---------|
| **Phase 1: 核心功能** | 3 | 9小时 | 今天-明天 |
| **Phase 2: 前端集成** | 1 | 4小时 | 明天 |
| **Phase 3: 多租�?* | 2 | 5小时 | 明天-后天 |
| **Phase 4: 测试部署** | 3 | 8小时 | 后天 |
| **总计** | 9 | **26小时** | **3-4�?* |

---

## �?验收标准

### 功能验收

- [ ] 用户可以�?Marketplace 购买并激活订�?- [ ] 用户可以通过 Azure AD 登录
- [ ] 用户只能访问自己租户的数�?- [ ] 订阅状态变更通过 Webhook 实时更新
- [ ] 暂停/取消的订阅无法访问功�?
### 安全验收

- [ ] JWT Token 验证正确
- [ ] Webhook 签名验证正确
- [ ] 多租户数据完全隔�?- [ ] API Keys 不在代码中硬编码
- [ ] HTTPS 强制启用

### 性能验收

- [ ] API 响应时间 < 2�?- [ ] 数据库查询优化（有索引）
- [ ] 支持 100 并发用户
- [ ] Webhook 处理时间 < 30�?
---

## 🚀 下一步行�?
### 立即开始（优先级最高）

1. **执行数据库迁�?*
   ```bash
   psql $DATABASE_URL -f backend/media-service/migrations/001_marketplace_tables.sql
   ```

2. **修改 marketplace.py 使用数据�?*
   - 替换内存字典为数据库查询
   - 实现订阅 CRUD 操作

3. **完善 Landing Page**
   - 集成 Resolve API
   - 集成 Activate API
   - 添加激活按�?
---

**准备好开始了吗？让我们从 Phase 1 Task 1.1 开始！** 🚀

