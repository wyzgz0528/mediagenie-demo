"""
数据库连接和会话管理

使用 SQLAlchemy 异步引擎和会�?"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging

from config import settings

logger = logging.getLogger(__name__)

# ============================================
# 数据库引擎配�?# ============================================

# 创建异步引擎
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,  # 开发环境打�?SQL
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=settings.DB_POOL_RECYCLE,
    pool_pre_ping=True,  # 连接前检查连接是否有�?    future=True,
)

# 创建异步会话工厂
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

logger.info(f"Database engine created: {settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else 'configured'}")


# ============================================
# FastAPI Dependency
# ============================================

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI Dependency: 获取数据库会�?    
    用法:
        @app.get("/api/users")
        async def get_users(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(User))
            return result.scalars().all()
    
    特�?
    - 自动提交成功的事�?    - 自动回滚失败的事�?    - 自动关闭会话
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            logger.error(f"Database session error: {e}")
            raise
        finally:
            await session.close()


# ============================================
# 上下文管理器
# ============================================

@asynccontextmanager
async def get_db_context() -> AsyncGenerator[AsyncSession, None]:
    """
    上下文管理器: 获取数据库会�?    
    用法:
        async with get_db_context() as db:
            result = await db.execute(select(User))
            users = result.scalars().all()
    
    特�?
    - 自动提交成功的事�?    - 自动回滚失败的事�?    - 自动关闭会话
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            logger.error(f"Database context error: {e}")
            raise
        finally:
            await session.close()


# ============================================
# 数据库操作辅助函�?# ============================================

async def init_db():
    """
    初始化数据库
    
    注意: 生产环境应使用迁移脚�?此函数仅用于开发和测试
    """
    from models import Base
    
    async with engine.begin() as conn:
        # 创建所有表
        await conn.run_sync(Base.metadata.create_all)
    
    logger.info("Database initialized successfully")


async def close_db():
    """
    关闭数据库连�?    
    在应用关闭时调用
    """
    await engine.dispose()
    logger.info("Database connections closed")


async def check_db_connection() -> bool:
    """
    检查数据库连接是否正常
    
    Returns:
        bool: 连接是否正常
    """
    try:
        async with AsyncSessionLocal() as session:
            await session.execute("SELECT 1")
        logger.info("Database connection check: OK")
        return True
    except Exception as e:
        logger.error(f"Database connection check failed: {e}")
        return False


# ============================================
# 租户上下文管�?(多租户支�?
# ============================================

class TenantContext:
    """
    租户上下文管理器
    
    用于设置当前租户 ID,实现多租户数据隔�?    """
    
    def __init__(self, session: AsyncSession, tenant_id: str):
        self.session = session
        self.tenant_id = tenant_id
    
    async def __aenter__(self):
        """设置租户上下�?""
        await self.session.execute(
            f"SET LOCAL app.current_tenant_id = '{self.tenant_id}'"
        )
        logger.debug(f"Tenant context set: {self.tenant_id}")
        return self.session
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """清除租户上下�?""
        await self.session.execute("RESET app.current_tenant_id")
        logger.debug(f"Tenant context cleared: {self.tenant_id}")


async def set_tenant_context(session: AsyncSession, tenant_id: str):
    """
    设置租户上下�?    
    用法:
        async with get_db() as db:
            await set_tenant_context(db, user.tenant_id)
            # 后续查询会自动过滤租户数�?            result = await db.execute(select(Task))
    """
    await session.execute(
        f"SET LOCAL app.current_tenant_id = '{tenant_id}'"
    )
    logger.debug(f"Tenant context set: {tenant_id}")


# ============================================
# 数据库健康检�?# ============================================

async def health_check() -> dict:
    """
    数据库健康检�?    
    Returns:
        dict: 健康检查结�?    """
    try:
        async with AsyncSessionLocal() as session:
            # 执行简单查�?            result = await session.execute("SELECT 1 as health_check")
            row = result.fetchone()
            
            # 检查连接池状�?            pool = engine.pool
            pool_status = {
                "size": pool.size(),
                "checked_in": pool.checkedin(),
                "checked_out": pool.checkedout(),
                "overflow": pool.overflow(),
            }
            
            return {
                "status": "healthy",
                "database": "connected",
                "pool": pool_status,
                "query_result": row[0] if row else None
            }
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }


# ============================================
# 事务管理
# ============================================

@asynccontextmanager
async def transaction(session: AsyncSession):
    """
    事务上下文管理器
    
    用法:
        async with get_db() as db:
            async with transaction(db):
                # 所有操作在同一个事务中
                db.add(user)
                db.add(subscription)
                # 自动提交或回�?    """
    try:
        yield session
        await session.commit()
        logger.debug("Transaction committed")
    except Exception as e:
        await session.rollback()
        logger.error(f"Transaction rolled back: {e}")
        raise


# ============================================
# 批量操作
# ============================================

async def bulk_insert(session: AsyncSession, objects: list):
    """
    批量插入对象
    
    Args:
        session: 数据库会�?        objects: 要插入的对象列表
    """
    session.add_all(objects)
    await session.flush()
    logger.info(f"Bulk inserted {len(objects)} objects")


async def bulk_update(session: AsyncSession, model, updates: list[dict]):
    """
    批量更新
    
    Args:
        session: 数据库会�?        model: 模型�?        updates: 更新数据列表,每个字典必须包含 id 字段
    """
    from sqlalchemy import update
    
    for update_data in updates:
        stmt = update(model).where(model.id == update_data['id']).values(**update_data)
        await session.execute(stmt)
    
    await session.flush()
    logger.info(f"Bulk updated {len(updates)} objects")

