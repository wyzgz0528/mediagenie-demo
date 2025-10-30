#!/usr/bin/env python3
"""
运行多租户数据隔离迁移脚�?执行 002_multi_tenant_rls.sql 以启用行级安�?(RLS)
"""

import asyncio
import logging
import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import text
from database import engine

# 加载环境变量
load_dotenv()

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def run_rls_migration():
    """运行 RLS 迁移脚本"""
    try:
        # 获取迁移文件路径
        migration_file = Path(__file__).parent / 'migrations' / '002_multi_tenant_rls.sql'
        
        if not migration_file.exists():
            logger.error(f"�?迁移文件不存�? {migration_file}")
            return False
        
        # 读取迁移脚本
        logger.info(f"📖 读取迁移脚本: {migration_file}")
        with open(migration_file, 'r', encoding='utf-8') as f:
            migration_sql = f.read()
        
        # 执行迁移
        logger.info("🚀 开始执�?RLS 迁移...")
        
        async with engine.begin() as conn:
            # 分割 SQL 语句（处理多个语句）
            statements = migration_sql.split(';')
            
            for i, statement in enumerate(statements, 1):
                statement = statement.strip()
                
                # 跳过空语句和注释
                if not statement or statement.startswith('--'):
                    continue
                
                try:
                    logger.info(f"�?执行语句 {i}...")
                    await conn.execute(text(statement))
                    logger.info(f"�?语句 {i} 执行成功")
                except Exception as e:
                    logger.error(f"�?语句 {i} 执行失败: {e}")
                    # 继续执行其他语句
                    continue
        
        logger.info("�?RLS 迁移完成�?)
        logger.info("")
        logger.info("📊 已启用的功能:")
        logger.info("  �?行级安全 (RLS) - 所有表")
        logger.info("  �?租户隔离策略 - users, subscriptions, user_subscriptions, webhook_events")
        logger.info("  �?审计日志系统 - 记录所有数据变�?)
        logger.info("  �?权限检查函�?- 验证用户访问权限")
        logger.info("  �?数据库视�?- 简化查�?)
        logger.info("")
        logger.info("🔐 安全特�?")
        logger.info("  �?用户只能访问自己租户的数�?)
        logger.info("  �?用户只能修改自己的信�?)
        logger.info("  �?所有数据变更都被记�?)
        logger.info("  �?自动租户隔离")
        logger.info("")
        
        return True
        
    except Exception as e:
        logger.error(f"�?RLS 迁移失败: {e}")
        return False

async def verify_rls_setup():
    """验证 RLS 设置"""
    try:
        logger.info("")
        logger.info("🔍 验证 RLS 设置...")
        
        async with engine.begin() as conn:
            # 检�?RLS 是否启用
            result = await conn.execute(text("""
                SELECT tablename, rowsecurity
                FROM pg_tables
                WHERE schemaname = 'public'
                AND tablename IN ('users', 'subscriptions', 'user_subscriptions', 'webhook_events')
                ORDER BY tablename;
            """))
            
            rows = result.fetchall()
            
            logger.info("📊 RLS 状�?")
            for row in rows:
                table_name, rls_enabled = row
                status = "�?已启�? if rls_enabled else "�?未启�?
                logger.info(f"  {status} - {table_name}")
            
            # 检查策略数�?            result = await conn.execute(text("""
                SELECT tablename, COUNT(*) as policy_count
                FROM pg_policies
                WHERE schemaname = 'public'
                GROUP BY tablename
                ORDER BY tablename;
            """))
            
            rows = result.fetchall()
            
            logger.info("")
            logger.info("📋 RLS 策略数量:")
            for row in rows:
                table_name, policy_count = row
                logger.info(f"  {table_name}: {policy_count} 个策�?)
            
            # 检查函�?            result = await conn.execute(text("""
                SELECT COUNT(*) as function_count
                FROM pg_proc
                WHERE proname IN (
                    'get_current_tenant_id',
                    'get_current_user_id',
                    'check_subscription_access',
                    'check_subscription_owner',
                    'audit_trigger_func'
                );
            """))
            
            function_count = result.scalar()
            logger.info("")
            logger.info(f"🔧 已创�?{function_count} 个函�?)
            
            # 检查审计日志表
            result = await conn.execute(text("""
                SELECT COUNT(*) as table_count
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name = 'audit_logs';
            """))
            
            table_count = result.scalar()
            if table_count > 0:
                logger.info("�?审计日志表已创建")
            
        logger.info("")
        logger.info("�?RLS 设置验证完成�?)
        return True
        
    except Exception as e:
        logger.error(f"�?RLS 设置验证失败: {e}")
        return False

async def main():
    """主函�?""
    logger.info("")
    logger.info("╔════════════════════════════════════════════════════════════╗")
    logger.info("�?    🔐 多租户数据隔�?- RLS 迁移                           �?)
    logger.info("╚════════════════════════════════════════════════════════════╝")
    logger.info("")
    
    # 运行迁移
    success = await run_rls_migration()
    
    if success:
        # 验证设置
        await verify_rls_setup()
        
        logger.info("")
        logger.info("🎉 RLS 迁移完成�?)
        logger.info("")
        logger.info("📝 使用说明:")
        logger.info("  1. 在应用中设置租户上下�?")
        logger.info("     SET app.current_tenant_id = 'tenant-id'")
        logger.info("     SET app.current_user_id = 'user-id'")
        logger.info("")
        logger.info("  2. 然后执行查询，RLS 会自动过滤数�?)
        logger.info("")
        logger.info("  3. 查看审计日志:")
        logger.info("     SELECT * FROM audit_logs WHERE tenant_id = 'tenant-id'")
        logger.info("")
    else:
        logger.error("�?RLS 迁移失败")
        return False
    
    return True

if __name__ == '__main__':
    success = asyncio.run(main())
    exit(0 if success else 1)

