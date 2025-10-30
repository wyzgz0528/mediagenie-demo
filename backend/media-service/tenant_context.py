"""
租户上下文管�?用于在数据库查询中设置租户隔�?"""

from contextlib import asynccontextmanager
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import logging

logger = logging.getLogger(__name__)


class TenantContext:
    """租户上下文管理器"""
    
    def __init__(self, tenant_id: str, user_id: Optional[str] = None):
        """
        初始化租户上下文
        
        Args:
            tenant_id: 租户 ID (通常�?Azure AD Tenant ID)
            user_id: 用户 ID (UUID)
        """
        self.tenant_id = tenant_id
        self.user_id = user_id
    
    async def set_context(self, session: AsyncSession) -> None:
        """
        在数据库会话中设置租户上下文
        
        Args:
            session: 数据库会�?        """
        try:
            # 设置租户 ID
            await session.execute(
                text(f"SET app.current_tenant_id = '{self.tenant_id}'")
            )
            logger.debug(f"�?设置租户 ID: {self.tenant_id}")
            
            # 设置用户 ID (如果提供)
            if self.user_id:
                await session.execute(
                    text(f"SET app.current_user_id = '{self.user_id}'")
                )
                logger.debug(f"�?设置用户 ID: {self.user_id}")
        except Exception as e:
            logger.error(f"�?设置租户上下文失�? {e}")
            raise
    
    async def clear_context(self, session: AsyncSession) -> None:
        """
        清除租户上下�?        
        Args:
            session: 数据库会�?        """
        try:
            await session.execute(text("RESET app.current_tenant_id"))
            await session.execute(text("RESET app.current_user_id"))
            logger.debug("�?清除租户上下�?)
        except Exception as e:
            logger.error(f"�?清除租户上下文失�? {e}")


@asynccontextmanager
async def with_tenant_context(
    session: AsyncSession,
    tenant_id: str,
    user_id: Optional[str] = None
):
    """
    上下文管理器 - 自动设置和清除租户上下文
    
    使用方式:
        async with with_tenant_context(session, tenant_id, user_id):
            # 在这里执行查询，RLS 会自动应�?            result = await session.execute(select(User))
    
    Args:
        session: 数据库会�?        tenant_id: 租户 ID
        user_id: 用户 ID (可�?
    
    Yields:
        租户上下�?    """
    context = TenantContext(tenant_id, user_id)
    
    try:
        # 设置上下�?        await context.set_context(session)
        yield context
    finally:
        # 清除上下�?        await context.clear_context(session)


async def get_audit_logs(
    session: AsyncSession,
    tenant_id: str,
    limit: int = 100,
    offset: int = 0
) -> list:
    """
    获取审计日志
    
    Args:
        session: 数据库会�?        tenant_id: 租户 ID
        limit: 返回的最大记录数
        offset: 偏移�?    
    Returns:
        审计日志列表
    """
    try:
        async with with_tenant_context(session, tenant_id):
            result = await session.execute(
                text(f"""
                    SELECT 
                        id,
                        tenant_id,
                        user_id,
                        action,
                        table_name,
                        record_id,
                        old_values,
                        new_values,
                        created_at
                    FROM audit_logs
                    ORDER BY created_at DESC
                    LIMIT {limit} OFFSET {offset}
                """)
            )
            
            rows = result.fetchall()
            return [
                {
                    'id': row[0],
                    'tenant_id': row[1],
                    'user_id': row[2],
                    'action': row[3],
                    'table_name': row[4],
                    'record_id': row[5],
                    'old_values': row[6],
                    'new_values': row[7],
                    'created_at': row[8],
                }
                for row in rows
            ]
    except Exception as e:
        logger.error(f"�?获取审计日志失败: {e}")
        return []


async def check_user_subscription_access(
    session: AsyncSession,
    tenant_id: str,
    user_id: str,
    subscription_id: str
) -> bool:
    """
    检查用户是否有权访问订�?    
    Args:
        session: 数据库会�?        tenant_id: 租户 ID
        user_id: 用户 ID
        subscription_id: 订阅 ID
    
    Returns:
        是否有权访问
    """
    try:
        async with with_tenant_context(session, tenant_id, user_id):
            result = await session.execute(
                text("""
                    SELECT check_subscription_access(:subscription_id::UUID)
                """),
                {'subscription_id': subscription_id}
            )
            
            return result.scalar() or False
    except Exception as e:
        logger.error(f"�?检查订阅访问权限失�? {e}")
        return False


async def check_user_subscription_owner(
    session: AsyncSession,
    tenant_id: str,
    user_id: str,
    subscription_id: str
) -> bool:
    """
    检查用户是否是订阅的所有�?    
    Args:
        session: 数据库会�?        tenant_id: 租户 ID
        user_id: 用户 ID
        subscription_id: 订阅 ID
    
    Returns:
        是否是所有�?    """
    try:
        async with with_tenant_context(session, tenant_id, user_id):
            result = await session.execute(
                text("""
                    SELECT check_subscription_owner(:subscription_id::UUID)
                """),
                {'subscription_id': subscription_id}
            )
            
            return result.scalar() or False
    except Exception as e:
        logger.error(f"�?检查订阅所有者失�? {e}")
        return False


async def get_user_subscriptions(
    session: AsyncSession,
    tenant_id: str,
    user_id: str
) -> list:
    """
    获取用户的订阅列�?    
    Args:
        session: 数据库会�?        tenant_id: 租户 ID
        user_id: 用户 ID
    
    Returns:
        订阅列表
    """
    try:
        async with with_tenant_context(session, tenant_id, user_id):
            result = await session.execute(
                text("""
                    SELECT 
                        id,
                        user_id,
                        subscription_id,
                        role,
                        marketplace_subscription_id,
                        plan_id,
                        status,
                        purchaser_email,
                        beneficiary_email
                    FROM user_subscription_details
                """)
            )
            
            rows = result.fetchall()
            return [
                {
                    'id': row[0],
                    'user_id': row[1],
                    'subscription_id': row[2],
                    'role': row[3],
                    'marketplace_subscription_id': row[4],
                    'plan_id': row[5],
                    'status': row[6],
                    'purchaser_email': row[7],
                    'beneficiary_email': row[8],
                }
                for row in rows
            ]
    except Exception as e:
        logger.error(f"�?获取用户订阅失败: {e}")
        return []


# 导出
__all__ = [
    'TenantContext',
    'with_tenant_context',
    'get_audit_logs',
    'check_user_subscription_access',
    'check_user_subscription_owner',
    'get_user_subscriptions',
]

