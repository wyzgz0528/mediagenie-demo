"""
数据库服务层

提供用户、订阅、Webhook 事件�?CRUD 操作
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, and_, or_
from sqlalchemy.orm import selectinload
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging
import uuid

from models import User, Subscription, UserSubscription, WebhookEvent

logger = logging.getLogger(__name__)


# ============================================
# 用户服务
# ============================================

class UserService:
    """用户相关数据库操�?""
    
    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: uuid.UUID) -> Optional[User]:
        """根据 ID 获取用户"""
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_by_oid(db: AsyncSession, azure_ad_oid: str) -> Optional[User]:
        """根据 Azure AD OID 获取用户"""
        result = await db.execute(
            select(User).where(User.azure_ad_oid == azure_ad_oid)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_by_email(db: AsyncSession, email: str) -> Optional[User]:
        """根据邮箱获取用户"""
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def create_or_update(
        db: AsyncSession,
        azure_ad_oid: str,
        email: str,
        display_name: Optional[str],
        tenant_id: str
    ) -> User:
        """
        创建或更新用�?(幂等操作)
        
        如果用户已存�?更新信息并更�?last_login
        如果用户不存�?创建新用�?        """
        # 查找现有用户
        user = await UserService.get_by_oid(db, azure_ad_oid)
        
        if user:
            # 更新现有用户
            user.email = email
            user.display_name = display_name
            user.tenant_id = tenant_id
            user.last_login = datetime.utcnow()
            user.updated_at = datetime.utcnow()
            logger.info(f"Updated user: {azure_ad_oid}")
        else:
            # 创建新用�?            user = User(
                azure_ad_oid=azure_ad_oid,
                email=email,
                display_name=display_name,
                tenant_id=tenant_id,
                last_login=datetime.utcnow()
            )
            db.add(user)
            logger.info(f"Created new user: {azure_ad_oid}")
        
        await db.flush()
        await db.refresh(user)
        return user
    
    @staticmethod
    async def get_user_subscriptions(
        db: AsyncSession,
        user_id: uuid.UUID
    ) -> List[Subscription]:
        """获取用户的所有订�?""
        result = await db.execute(
            select(Subscription)
            .join(UserSubscription)
            .where(UserSubscription.user_id == user_id)
        )
        return result.scalars().all()
    
    @staticmethod
    async def get_active_subscriptions(
        db: AsyncSession,
        user_id: uuid.UUID
    ) -> List[Subscription]:
        """获取用户的活跃订�?""
        result = await db.execute(
            select(Subscription)
            .join(UserSubscription)
            .where(
                and_(
                    UserSubscription.user_id == user_id,
                    Subscription.status == "Subscribed"
                )
            )
        )
        return result.scalars().all()


# ============================================
# 订阅服务
# ============================================

class SubscriptionService:
    """订阅相关数据库操�?""
    
    @staticmethod
    async def get_by_id(db: AsyncSession, subscription_id: uuid.UUID) -> Optional[Subscription]:
        """根据数据�?ID 获取订阅"""
        result = await db.execute(
            select(Subscription).where(Subscription.id == subscription_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_by_subscription_id(db: AsyncSession, subscription_id: str) -> Optional[Subscription]:
        """根据 Marketplace 订阅 ID 获取订阅"""
        result = await db.execute(
            select(Subscription).where(Subscription.subscription_id == subscription_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def create(db: AsyncSession, subscription_data: Dict[str, Any]) -> Subscription:
        """创建新订�?""
        subscription = Subscription(**subscription_data)
        db.add(subscription)
        await db.flush()
        await db.refresh(subscription)
        logger.info(f"Created subscription: {subscription.subscription_id}")
        return subscription
    
    @staticmethod
    async def update_status(
        db: AsyncSession,
        subscription_id: str,
        status: str
    ) -> Optional[Subscription]:
        """更新订阅状�?""
        subscription = await SubscriptionService.get_by_subscription_id(db, subscription_id)
        if subscription:
            subscription.status = status
            subscription.updated_at = datetime.utcnow()
            await db.flush()
            await db.refresh(subscription)
            logger.info(f"Updated subscription {subscription_id} status to {status}")
        return subscription
    
    @staticmethod
    async def activate(
        db: AsyncSession,
        subscription_id: str
    ) -> Optional[Subscription]:
        """激活订�?""
        subscription = await SubscriptionService.get_by_subscription_id(db, subscription_id)
        if subscription:
            subscription.status = "Subscribed"
            subscription.activated_at = datetime.utcnow()
            subscription.updated_at = datetime.utcnow()
            await db.flush()
            await db.refresh(subscription)
            logger.info(f"Activated subscription: {subscription_id}")
        return subscription
    
    @staticmethod
    async def update_plan(
        db: AsyncSession,
        subscription_id: str,
        new_plan_id: str
    ) -> Optional[Subscription]:
        """更新订阅计划"""
        subscription = await SubscriptionService.get_by_subscription_id(db, subscription_id)
        if subscription:
            old_plan = subscription.plan_id
            subscription.plan_id = new_plan_id
            subscription.updated_at = datetime.utcnow()
            await db.flush()
            await db.refresh(subscription)
            logger.info(f"Updated subscription {subscription_id} plan from {old_plan} to {new_plan_id}")
        return subscription
    
    @staticmethod
    async def update_quantity(
        db: AsyncSession,
        subscription_id: str,
        new_quantity: int
    ) -> Optional[Subscription]:
        """更新订阅数量"""
        subscription = await SubscriptionService.get_by_subscription_id(db, subscription_id)
        if subscription:
            old_quantity = subscription.quantity
            subscription.quantity = new_quantity
            subscription.updated_at = datetime.utcnow()
            await db.flush()
            await db.refresh(subscription)
            logger.info(f"Updated subscription {subscription_id} quantity from {old_quantity} to {new_quantity}")
        return subscription
    
    @staticmethod
    async def get_all_active(db: AsyncSession) -> List[Subscription]:
        """获取所有活跃订�?""
        result = await db.execute(
            select(Subscription).where(Subscription.status == "Subscribed")
        )
        return result.scalars().all()


# ============================================
# 用户-订阅关联服务
# ============================================

class UserSubscriptionService:
    """用户-订阅关联操作"""
    
    @staticmethod
    async def associate(
        db: AsyncSession,
        user_id: uuid.UUID,
        subscription_id: uuid.UUID,
        role: str = "user"
    ) -> UserSubscription:
        """
        关联用户与订�?(幂等操作)
        
        如果关联已存�?更新角色
        如果关联不存�?创建新关�?        """
        # 查找现有关联
        result = await db.execute(
            select(UserSubscription).where(
                and_(
                    UserSubscription.user_id == user_id,
                    UserSubscription.subscription_id == subscription_id
                )
            )
        )
        user_subscription = result.scalar_one_or_none()
        
        if user_subscription:
            # 更新角色
            user_subscription.role = role
            logger.info(f"Updated user-subscription association: user={user_id}, subscription={subscription_id}")
        else:
            # 创建新关�?            user_subscription = UserSubscription(
                user_id=user_id,
                subscription_id=subscription_id,
                role=role
            )
            db.add(user_subscription)
            logger.info(f"Created user-subscription association: user={user_id}, subscription={subscription_id}")
        
        await db.flush()
        await db.refresh(user_subscription)
        return user_subscription
    
    @staticmethod
    async def remove(
        db: AsyncSession,
        user_id: uuid.UUID,
        subscription_id: uuid.UUID
    ) -> bool:
        """移除用户-订阅关联"""
        result = await db.execute(
            delete(UserSubscription).where(
                and_(
                    UserSubscription.user_id == user_id,
                    UserSubscription.subscription_id == subscription_id
                )
            )
        )
        deleted = result.rowcount > 0
        if deleted:
            logger.info(f"Removed user-subscription association: user={user_id}, subscription={subscription_id}")
        return deleted


# ============================================
# Webhook 事件服务
# ============================================

class WebhookEventService:
    """Webhook 事件相关操作"""
    
    @staticmethod
    async def create(db: AsyncSession, event_data: Dict[str, Any]) -> WebhookEvent:
        """创建 Webhook 事件记录"""
        event = WebhookEvent(**event_data)
        db.add(event)
        await db.flush()
        await db.refresh(event)
        logger.info(f"Created webhook event: {event.event_id} ({event.event_type})")
        return event
    
    @staticmethod
    async def get_by_event_id(db: AsyncSession, event_id: str) -> Optional[WebhookEvent]:
        """根据事件 ID 获取事件 (幂等性检�?"""
        result = await db.execute(
            select(WebhookEvent).where(WebhookEvent.event_id == event_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def mark_processing(db: AsyncSession, event_id: str) -> Optional[WebhookEvent]:
        """标记事件为处理中"""
        event = await WebhookEventService.get_by_event_id(db, event_id)
        if event:
            event.processing_status = "processing"
            await db.flush()
            await db.refresh(event)
        return event
    
    @staticmethod
    async def mark_completed(
        db: AsyncSession,
        event_id: str,
        result: Optional[Dict[str, Any]] = None
    ) -> Optional[WebhookEvent]:
        """标记事件为已完成"""
        event = await WebhookEventService.get_by_event_id(db, event_id)
        if event:
            event.processing_status = "completed"
            event.processed_at = datetime.utcnow()
            if result:
                event.processing_result = result
            await db.flush()
            await db.refresh(event)
            logger.info(f"Webhook event completed: {event_id}")
        return event
    
    @staticmethod
    async def mark_failed(
        db: AsyncSession,
        event_id: str,
        error_message: str
    ) -> Optional[WebhookEvent]:
        """标记事件为失�?""
        event = await WebhookEventService.get_by_event_id(db, event_id)
        if event:
            event.processing_status = "failed"
            event.error_message = error_message
            event.retry_count += 1
            await db.flush()
            await db.refresh(event)
            logger.error(f"Webhook event failed: {event_id} - {error_message}")
        return event

