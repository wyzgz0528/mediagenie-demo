# MediaGenie Marketplace 快速实施指�?
> **立即开始完善你�?Azure Marketplace SaaS 产品**  
> **预计时间**: 3-4�? 
> **难度**: 中等

---

## 📊 当前状�?
### �?你已经拥�?
1. �?**完整�?Azure AD 认证模块** (`auth_middleware.py`)
2. �?**SaaS Fulfillment API 客户�?* (`saas_fulfillment_client.py`)
3. �?**Webhook 处理器框�?* (`marketplace_webhook.py`)
4. �?**数据库表结构** (`001_marketplace_tables.sql`)
5. �?**基础 Landing Page** (`marketplace-portal/`)
6. �?**配置管理** (`config.py`)

### ⚠️ 需要完�?
1. �?数据库集成（当前使用内存存储�?2. �?Landing Page 激活流程（当前是静态页面）
3. �?Webhook 签名验证（当前是占位符）
4. �?前端 Azure AD 登录（当前是 mock 用户�?5. �?多租户数据隔离（当前只有 userId 字段�?
---

## 🚀 立即开始（3步）

### 步骤1: 执行数据库迁移（5分钟�?
```bash
# 1. 连接到你�?PostgreSQL 数据�?psql $DATABASE_URL

# 2. 执行迁移脚本
\i backend/media-service/migrations/001_marketplace_tables.sql

# 3. 验证表已创建
\dt

# 应该看到:
# - users
# - subscriptions
# - user_subscriptions
# - webhook_events
```

**验证**:
```sql
-- 查看表结�?\d users
\d subscriptions
\d user_subscriptions
\d webhook_events
```

---

### 步骤2: 配置环境变量�?0分钟�?
�?Azure App Service 配置以下环境变量�?
#### Backend Service

```bash
# Azure AD 配置
AZURE_AD_TENANT_ID=<your-tenant-id>
AZURE_AD_CLIENT_ID=<your-client-id>
AZURE_AD_CLIENT_SECRET=<your-client-secret>

# 数据库配�?DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/mediagenie

# Marketplace API 配置
MARKETPLACE_API_BASE_URL=https://marketplaceapi.microsoft.com/api
MARKETPLACE_API_VERSION=2018-08-31

# Webhook 签名密钥（与 Partner Center 配置一致）
MARKETPLACE_WEBHOOK_SECRET=<your-webhook-secret>

# 前端 URL
FRONTEND_URL=https://mediagenie-frontend.azurewebsites.net
```

#### Frontend

```bash
# Azure AD 配置
REACT_APP_AZURE_AD_CLIENT_ID=<your-client-id>
REACT_APP_AZURE_AD_AUTHORITY=https://login.microsoftonline.com/<tenant-id>
REACT_APP_AZURE_AD_REDIRECT_URI=https://mediagenie-frontend.azurewebsites.net

# API 端点
REACT_APP_API_BASE_URL=https://mediagenie-backend.azurewebsites.net
```

---

### 步骤3: 测试基础功能�?0分钟�?
```bash
# 1. 测试 Backend 健康检�?curl https://mediagenie-backend.azurewebsites.net/health

# 2. 测试 Landing Page
curl https://mediagenie-marketplace-portal.azurewebsites.net/landing?token=test&subscription_id=test

# 3. 测试 Webhook 端点
curl -X POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

---

## 📝 详细实施步骤

### Phase 1: 数据库集成（今天�?小时�?
#### 任务 1.1: 创建数据库模型（1小时�?
**文件**: `backend/media-service/models.py` (新建)

```python
from sqlalchemy import Column, String, Integer, Boolean, DateTime, JSON, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    azure_ad_oid = Column(String(255), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    display_name = Column(String(255))
    tenant_id = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    subscriptions = relationship("UserSubscription", back_populates="user")

class Subscription(Base):
    __tablename__ = "subscriptions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subscription_id = Column(String(255), unique=True, nullable=False)
    subscription_name = Column(String(255))
    offer_id = Column(String(100), nullable=False)
    plan_id = Column(String(100), nullable=False)
    quantity = Column(Integer, default=1)
    status = Column(String(50), nullable=False)
    
    # 购买者信�?    purchaser_email = Column(String(255))
    purchaser_oid = Column(String(255))
    purchaser_tenant_id = Column(String(255))
    
    # 受益人信�?    beneficiary_email = Column(String(255))
    beneficiary_oid = Column(String(255))
    beneficiary_tenant_id = Column(String(255))
    
    # 时间信息
    created_at = Column(DateTime, default=datetime.utcnow)
    activated_at = Column(DateTime)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 元数�?    raw_data = Column(JSON)
    
    # 关系
    users = relationship("UserSubscription", back_populates="subscription")

class UserSubscription(Base):
    __tablename__ = "user_subscriptions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    subscription_id = Column(UUID(as_uuid=True), ForeignKey("subscriptions.id"), nullable=False)
    role = Column(String(50), default="user")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="subscriptions")
    subscription = relationship("Subscription", back_populates="users")
```

---

#### 任务 1.2: 创建数据库服务（1小时�?
**文件**: `backend/media-service/database.py` (新建)

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from config import settings
import logging

logger = logging.getLogger(__name__)

# 创建异步引擎
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=settings.DB_POOL_RECYCLE,
)

# 创建会话工厂
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_db() -> AsyncSession:
    """
    FastAPI Dependency: 获取数据库会�?    
    用法:
        @app.get("/api/users")
        async def get_users(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

---

#### 任务 1.3: 修改 marketplace.py 使用数据库（2小时�?
**关键修改�?*:

1. **替换内存字典**:
   ```python
   # �?旧代�?   subscriptions = {}  # 内存存储
   
   # �?新代�?   from sqlalchemy import select
   from models import Subscription, User, UserSubscription
   from database import get_db
   ```

2. **修改订阅查询**:
   ```python
   # �?旧代�?   subscription = subscriptions.get(subscription_id)
   
   # �?新代�?   async def get_subscription(subscription_id: str, db: AsyncSession):
       result = await db.execute(
           select(Subscription).where(Subscription.subscription_id == subscription_id)
       )
       return result.scalar_one_or_none()
   ```

3. **修改订阅创建**:
   ```python
   # �?旧代�?   subscriptions[subscription_id] = subscription_data
   
   # �?新代�?   async def create_subscription(subscription_data: dict, db: AsyncSession):
       subscription = Subscription(**subscription_data)
       db.add(subscription)
       await db.commit()
       await db.refresh(subscription)
       return subscription
   ```

---

### Phase 2: Landing Page 激活流程（今天�?小时�?
#### 任务 2.1: 修改 marketplace-portal/app.py

**添加 Resolve API 调用**:

```python
from saas_fulfillment_client import SaaSFulfillmentClient, AzureADServicePrincipal

# 初始�?SaaS 客户�?service_principal = AzureADServicePrincipal(
    tenant_id=os.getenv("AZURE_AD_TENANT_ID"),
    client_id=os.getenv("AZURE_AD_CLIENT_ID"),
    client_secret=os.getenv("AZURE_AD_CLIENT_SECRET")
)
saas_client = SaaSFulfillmentClient(service_principal)

@app.route('/landing')
async def landing_page():
    token = request.args.get('token')
    
    if not token:
        return render_template('landing_error.html', error="Missing token")
    
    try:
        # 调用 Resolve API
        subscription_data = await saas_client.resolve_subscription(token)
        
        # 显示订阅详情
        return render_template('landing_activate.html', subscription=subscription_data)
    
    except Exception as e:
        logger.error(f"Resolve API error: {e}")
        return render_template('landing_error.html', error=str(e))

@app.route('/landing/activate', methods=['POST'])
async def activate_subscription():
    subscription_id = request.form.get('subscription_id')
    plan_id = request.form.get('plan_id')
    quantity = int(request.form.get('quantity', 1))
    
    try:
        # 调用 Activate API
        success = await saas_client.activate_subscription(
            subscription_id, plan_id, quantity
        )
        
        if success:
            # 重定向到前端应用
            frontend_url = os.getenv("FRONTEND_URL")
            return redirect(f"{frontend_url}?activated=true")
        else:
            return render_template('landing_error.html', error="Activation failed")
    
    except Exception as e:
        logger.error(f"Activate API error: {e}")
        return render_template('landing_error.html', error=str(e))
```

---

### Phase 3: Webhook 签名验证（今天，2小时�?
#### 修改 marketplace_webhook.py

**实现签名验证**:

```python
import hmac
import hashlib
from config import settings

def verify_webhook_signature(body: bytes, signature: str) -> bool:
    """
    验证 Marketplace Webhook 签名
    
    Args:
        body: 原始请求 body (bytes)
        signature: x-ms-marketplace-token header
        
    Returns:
        bool: 签名是否有效
    """
    secret = settings.MARKETPLACE_WEBHOOK_SECRET
    
    if not secret:
        logger.warning("MARKETPLACE_WEBHOOK_SECRET not configured, skipping verification")
        return True  # 开发模�?    
    # 计算期望的签�?    expected_signature = hmac.new(
        secret.encode('utf-8'),
        body,
        hashlib.sha256
    ).hexdigest()
    
    # 使用常量时间比较防止时序攻击
    return hmac.compare_digest(expected_signature, signature)

@router.post("/webhook")
async def handle_webhook(request: Request, ...):
    # 读取原始 body
    body_bytes = await request.body()
    
    # 获取签名
    signature = request.headers.get("x-ms-marketplace-token")
    
    if not signature:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing x-ms-marketplace-token header"
        )
    
    # 验证签名
    if not verify_webhook_signature(body_bytes, signature):
        logger.error("Webhook signature verification failed")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature"
        )
    
    # 继续处理...
```

---

## �?验证清单

### 今天完成后应该能�?
- [ ] 数据库表已创�?- [ ] 订阅数据持久化到数据�?- [ ] Landing Page 可以调用 Resolve API
- [ ] Landing Page 可以调用 Activate API
- [ ] Webhook 签名验证正常工作

### 测试命令

```bash
# 1. 测试数据库连�?psql $DATABASE_URL -c "SELECT * FROM users LIMIT 1;"

# 2. 测试 Landing Page
curl "https://your-portal.azurewebsites.net/landing?token=test-token"

# 3. 测试 Webhook（带签名�?python test_webhook_signature.py
```

---

## 📚 相关文档

- [完整实施计划](./MARKETPLACE_IMPLEMENTATION_PLAN.md)
- [SaaS 实施指导](./AZURE_MARKETPLACE_SAAS_IMPLEMENTATION_GUIDE.md)
- [Azure Marketplace 文档](https://learn.microsoft.com/en-us/azure/marketplace/)

---

**准备好开始了吗？从步�?开始执行！** 🚀

