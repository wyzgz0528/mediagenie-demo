"""
数据库迁移执行脚�?
执行 migrations/001_marketplace_tables.sql 创建所有必需的表
"""

import asyncio
import asyncpg
import os
import sys
from pathlib import Path
import logging
from dotenv import load_dotenv

# 加载 .env 文件
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def run_migration():
    """执行数据库迁�?""

    # 获取数据库连接字符串
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        logger.error("DATABASE_URL environment variable not set")
        sys.exit(1)
    
    # 转换 SQLAlchemy URL �?asyncpg URL
    # postgresql+asyncpg://user:pass@host:port/db -> postgresql://user:pass@host:port/db
    if "+asyncpg" in database_url:
        database_url = database_url.replace("+asyncpg", "")
    
    logger.info(f"Connecting to database...")
    
    try:
        # 连接到数据库
        conn = await asyncpg.connect(database_url)
        logger.info("�?Database connection established")
        
        # 读取迁移脚本
        migration_file = Path(__file__).parent / "migrations" / "001_marketplace_tables.sql"
        
        if not migration_file.exists():
            logger.error(f"Migration file not found: {migration_file}")
            sys.exit(1)
        
        logger.info(f"Reading migration file: {migration_file}")
        migration_sql = migration_file.read_text(encoding="utf-8")
        
        # 执行迁移
        logger.info("Executing migration...")
        await conn.execute(migration_sql)
        logger.info("�?Migration executed successfully")
        
        # 验证表是否创�?        tables = await conn.fetch("""
            SELECT tablename 
            FROM pg_tables 
            WHERE tablename IN ('users', 'subscriptions', 'user_subscriptions', 'webhook_events')
            ORDER BY tablename
        """)
        
        logger.info(f"�?Created tables: {', '.join([t['tablename'] for t in tables])}")
        
        # 验证视图是否创建
        views = await conn.fetch("""
            SELECT viewname 
            FROM pg_views 
            WHERE viewname IN ('v_user_subscriptions', 'v_active_subscriptions')
            ORDER BY viewname
        """)
        
        logger.info(f"�?Created views: {', '.join([v['viewname'] for v in views])}")
        
        # 验证函数是否创建
        functions = await conn.fetch("""
            SELECT proname 
            FROM pg_proc 
            WHERE proname IN ('upsert_user', 'associate_user_subscription', 'current_tenant_id')
            ORDER BY proname
        """)
        
        logger.info(f"�?Created functions: {', '.join([f['proname'] for f in functions])}")
        
        # 关闭连接
        await conn.close()
        logger.info("�?Database connection closed")
        
        logger.info("\n" + "="*60)
        logger.info("🎉 Migration completed successfully!")
        logger.info("="*60)
        
    except Exception as e:
        logger.error(f"�?Migration failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(run_migration())

