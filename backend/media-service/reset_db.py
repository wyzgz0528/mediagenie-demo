"""
重置数据�?- 删除所有表并重新创�?"""

import asyncio
import asyncpg
import os
from pathlib import Path
from dotenv import load_dotenv
import logging

# 加载 .env 文件
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def reset_database():
    """重置数据�?""
    
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        logger.error("DATABASE_URL environment variable not set")
        return False
    
    # 转换 URL
    if "+asyncpg" in database_url:
        database_url = database_url.replace("+asyncpg", "")
    
    try:
        logger.info("Connecting to database...")
        conn = await asyncpg.connect(database_url)
        
        logger.info("Dropping existing tables...")
        
        # 删除�?(按依赖顺�?
        await conn.execute("DROP TABLE IF EXISTS webhook_events CASCADE;")
        await conn.execute("DROP TABLE IF EXISTS user_subscriptions CASCADE;")
        await conn.execute("DROP TABLE IF EXISTS subscriptions CASCADE;")
        await conn.execute("DROP TABLE IF EXISTS users CASCADE;")
        
        # 删除视图
        await conn.execute("DROP VIEW IF EXISTS v_user_subscriptions CASCADE;")
        await conn.execute("DROP VIEW IF EXISTS v_active_subscriptions CASCADE;")
        
        # 删除函数
        await conn.execute("DROP FUNCTION IF EXISTS upsert_user CASCADE;")
        await conn.execute("DROP FUNCTION IF EXISTS associate_user_subscription CASCADE;")
        await conn.execute("DROP FUNCTION IF EXISTS current_tenant_id CASCADE;")
        await conn.execute("DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;")
        
        logger.info("�?All tables, views, and functions dropped")
        
        await conn.close()
        logger.info("�?Database reset complete")
        
        return True
    
    except Exception as e:
        logger.error(f"�?Reset failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    success = asyncio.run(reset_database())
    
    if success:
        print("\n" + "="*60)
        print("�?Database reset successful!")
        print("="*60)
        print("\nNext step:")
        print("  python run_migration.py")
    else:
        print("\n" + "="*60)
        print("�?Database reset failed")
        print("="*60)

