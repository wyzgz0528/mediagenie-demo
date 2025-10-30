"""
数据库模型定�?
使用 SQLAlchemy ORM 定义数据库表结构
对应 migrations/001_marketplace_tables.sql 中的�?"""

from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from datetime import datetime
from typing import Optional

Base = declarative_base()


# ============================================
# 1. 用户账号�?# ============================================

class User(Base):
    """
    用户账号�?    存储 Azure AD 登录用户信息
    """
    __tablename__ = "users"
    
    # 主键
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Azure AD 身份信息
    azure_ad_oid = Column(String(255), unique=True, nullable=False, index=True)
    azure_ad_sub = Column(String(255))
    email = Column(String(255), unique=True, nullable=False, index=True)
    display_name = Column(String(255))
    tenant_id = Column(String(255), nullable=False, index=True)
    
    # 账号状�?    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # 时间�?    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())
    last_login = Column(DateTime)

    # 元数�?(使用 user_metadata 避免�?SQLAlchemy �?metadata 冲突)
    user_metadata = Column(JSON, default=dict)
    
    # 关系
    subscriptions = relationship("UserSubscription", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, tenant_id={self.tenant_id})>"


# ============================================
# 2. 订阅信息�?# ============================================

class Subscription(Base):
    """
    Azure Marketplace 订阅信息�?    存储�?Marketplace 获取的订阅详�?    """
    __tablename__ = "subscriptions"
    
    # 主键
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Marketplace 订阅标识
    subscription_id = Column(String(255), unique=True, nullable=False, index=True)
    subscription_name = Column(String(255))
    
    # Offer �?Plan 信息
    publisher_id = Column(String(100))
    offer_id = Column(String(100), nullable=False)
    plan_id = Column(String(100), nullable=False, index=True)
    quantity = Column(Integer, default=1)
    
    # 订阅状�?    # PendingFulfillmentStart / Subscribed / Suspended / Unsubscribed
    status = Column(String(50), nullable=False, index=True)
    
    # 购买者信�?(Purchaser)
    purchaser_email = Column(String(255), index=True)
    purchaser_oid = Column(String(255))
    purchaser_tenant_id = Column(String(255))
    
    # 受益人信�?(Beneficiary - 实际使用�?
    beneficiary_email = Column(String(255), index=True)
    beneficiary_oid = Column(String(255))
    beneficiary_tenant_id = Column(String(255), index=True)
    
    # 订阅期限
    term_start_date = Column(DateTime)
    term_end_date = Column(DateTime)
    term_unit = Column(String(20))  # P1M (�?, P1Y (�?
    
    # 标志�?    is_free_trial = Column(Boolean, default=False)
    is_test = Column(Boolean, default=False)
    auto_renew = Column(Boolean, default=True)
    
    # 会话和沙�?    session_mode = Column(String(50), default='None')
    sandbox_type = Column(String(50), default='None')
    
    # 允许的客户操�?    allowed_customer_operations = Column(JSON, default=list)
    
    # 时间�?    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    activated_at = Column(DateTime)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())
    
    # 完整�?Marketplace 响应 (备份)
    raw_data = Column(JSON)
    
    # 关系
    users = relationship("UserSubscription", back_populates="subscription", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Subscription(id={self.subscription_id}, plan={self.plan_id}, status={self.status})>"
    
    @property
    def is_active(self) -> bool:
        """订阅是否活跃"""
        return self.status == "Subscribed"
    
    @property
    def is_suspended(self) -> bool:
        """订阅是否暂停"""
        return self.status == "Suspended"
    
    @property
    def is_cancelled(self) -> bool:
        """订阅是否取消"""
        return self.status == "Unsubscribed"


# ============================================
# 3. 用户-订阅关联�?(多对�?
# ============================================

class UserSubscription(Base):
    """
    用户-订阅多对多关联表
    一个订阅可以有多个用户,一个用户可以有多个订阅
    """
    __tablename__ = "user_subscriptions"
    
    # 主键
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # 外键
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subscription_id = Column(UUID(as_uuid=True), ForeignKey("subscriptions.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 角色权限
    role = Column(String(50), default='user')  # owner / admin / user
    
    # 时间�?    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    
    # 关系
    user = relationship("User", back_populates="subscriptions")
    subscription = relationship("Subscription", back_populates="users")
    
    def __repr__(self):
        return f"<UserSubscription(user_id={self.user_id}, subscription_id={self.subscription_id}, role={self.role})>"


# ============================================
# 4. Webhook 事件日志�?# ============================================

class WebhookEvent(Base):
    """
    Marketplace Webhook 事件日志�?    记录所�?Webhook 事件,用于幂等性检查和审计
    """
    __tablename__ = "webhook_events"
    
    # 主键
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # 事件标识
    event_id = Column(String(255), unique=True, index=True)  # Marketplace 事件 ID (幂等�?
    activity_id = Column(String(255))  # 活动 ID
    
    # 事件类型
    # Subscribe / Unsubscribe / ChangePlan / ChangeQuantity / Suspend / Reinstate / Renew
    event_type = Column(String(50), nullable=False, index=True)
    
    # 订阅信息
    subscription_id = Column(String(255), nullable=False, index=True)
    offer_id = Column(String(100))
    publisher_id = Column(String(100))
    plan_id = Column(String(100))
    quantity = Column(Integer)
    
    # 事件状�?    event_status = Column(String(50))  # Success / Failure / InProgress
    
    # 处理状�?    # pending / processing / completed / failed
    processing_status = Column(String(50), default='pending', index=True)
    
    error_message = Column(Text)
    retry_count = Column(Integer, default=0)
    
    # 时间信息
    event_timestamp = Column(DateTime)  # Marketplace 事件时间
    received_at = Column(DateTime, default=datetime.utcnow, server_default=func.now(), index=True)
    processed_at = Column(DateTime)
    
    # 原始 Webhook payload
    raw_payload = Column(JSON)
    
    # 处理结果
    processing_result = Column(JSON)
    
    def __repr__(self):
        return f"<WebhookEvent(id={self.event_id}, type={self.event_type}, status={self.processing_status})>"
    
    @property
    def is_processed(self) -> bool:
        """事件是否已处�?""
        return self.processing_status == "completed"
    
    @property
    def is_failed(self) -> bool:
        """事件是否处理失败"""
        return self.processing_status == "failed"
    
    @property
    def can_retry(self) -> bool:
        """是否可以重试"""
        return self.processing_status == "failed" and self.retry_count < 3


# ============================================
# 5. 辅助函数
# ============================================

def get_table_names():
    """获取所有表�?""
    return [
        "users",
        "subscriptions",
        "user_subscriptions",
        "webhook_events"
    ]


def create_all_tables(engine):
    """
    创建所有表
    
    注意: 生产环境应使�?Alembic 进行数据库迁�?    此函数仅用于开发和测试
    """
    Base.metadata.create_all(bind=engine)


def drop_all_tables(engine):
    """
    删除所有表
    
    警告: 此操作会删除所有数�?仅用于开发和测试
    """
    Base.metadata.drop_all(bind=engine)

