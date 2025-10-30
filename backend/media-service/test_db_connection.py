"""
测试数据库连接和基本操作

验证数据库配置是否正�?表是否创建成�?"""

import asyncio
import sys
from pathlib import Path
from dotenv import load_dotenv

# 加载 .env 文件
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

# 添加当前目录�?Python 路径
sys.path.insert(0, str(Path(__file__).parent))

from database import check_db_connection, health_check, get_db_context
from db_service import UserService, SubscriptionService, WebhookEventService
from models import User, Subscription
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def test_connection():
    """测试数据库连�?""
    logger.info("="*60)
    logger.info("Testing database connection...")
    logger.info("="*60)
    
    # 测试连接
    is_connected = await check_db_connection()
    if not is_connected:
        logger.error("�?Database connection failed")
        return False
    
    logger.info("�?Database connection successful")
    return True


async def test_health_check():
    """测试健康检�?""
    logger.info("\n" + "="*60)
    logger.info("Testing health check...")
    logger.info("="*60)
    
    health = await health_check()
    logger.info(f"Health status: {health}")
    
    if health["status"] == "healthy":
        logger.info("�?Health check passed")
        return True
    else:
        logger.error("�?Health check failed")
        return False


async def test_tables_exist():
    """测试表是否存�?""
    logger.info("\n" + "="*60)
    logger.info("Testing if tables exist...")
    logger.info("="*60)
    
    async with get_db_context() as db:
        # 测试查询每个�?        tables = ["users", "subscriptions", "user_subscriptions", "webhook_events"]
        
        for table in tables:
            try:
                result = await db.execute(f"SELECT COUNT(*) FROM {table}")
                count = result.scalar()
                logger.info(f"�?Table '{table}' exists (rows: {count})")
            except Exception as e:
                logger.error(f"�?Table '{table}' not found: {e}")
                return False
    
    return True


async def test_user_operations():
    """测试用户操作"""
    logger.info("\n" + "="*60)
    logger.info("Testing user operations...")
    logger.info("="*60)
    
    async with get_db_context() as db:
        # 创建测试用户
        user = await UserService.create_or_update(
            db,
            azure_ad_oid="test-oid-001",
            email="test@example.com",
            display_name="Test User",
            tenant_id="test-tenant-001"
        )
        logger.info(f"�?Created user: {user.email} (ID: {user.id})")
        
        # 查询用户
        found_user = await UserService.get_by_oid(db, "test-oid-001")
        if found_user:
            logger.info(f"�?Found user by OID: {found_user.email}")
        else:
            logger.error("�?User not found")
            return False
        
        # 更新用户 (幂等性测�?
        updated_user = await UserService.create_or_update(
            db,
            azure_ad_oid="test-oid-001",
            email="test@example.com",
            display_name="Updated Test User",
            tenant_id="test-tenant-001"
        )
        logger.info(f"�?Updated user: {updated_user.display_name}")
    
    return True


async def test_subscription_operations():
    """测试订阅操作"""
    logger.info("\n" + "="*60)
    logger.info("Testing subscription operations...")
    logger.info("="*60)
    
    async with get_db_context() as db:
        # 创建测试订阅
        subscription_data = {
            "subscription_id": "test-sub-001",
            "subscription_name": "Test Subscription",
            "offer_id": "test-offer",
            "plan_id": "basic",
            "quantity": 1,
            "status": "PendingFulfillmentStart",
            "purchaser_email": "purchaser@example.com",
            "beneficiary_email": "beneficiary@example.com"
        }
        
        subscription = await SubscriptionService.create(db, subscription_data)
        logger.info(f"�?Created subscription: {subscription.subscription_id}")
        
        # 激活订�?        activated = await SubscriptionService.activate(db, "test-sub-001")
        if activated and activated.status == "Subscribed":
            logger.info(f"�?Activated subscription: {activated.subscription_id}")
        else:
            logger.error("�?Subscription activation failed")
            return False
        
        # 更新计划
        updated = await SubscriptionService.update_plan(db, "test-sub-001", "premium")
        if updated and updated.plan_id == "premium":
            logger.info(f"�?Updated subscription plan to: {updated.plan_id}")
        else:
            logger.error("�?Plan update failed")
            return False
    
    return True


async def test_webhook_event_operations():
    """测试 Webhook 事件操作"""
    logger.info("\n" + "="*60)
    logger.info("Testing webhook event operations...")
    logger.info("="*60)
    
    async with get_db_context() as db:
        # 创建测试事件
        event_data = {
            "event_id": "test-event-001",
            "event_type": "Subscribe",
            "subscription_id": "test-sub-001",
            "plan_id": "basic",
            "quantity": 1,
            "raw_payload": {"test": "data"}
        }
        
        event = await WebhookEventService.create(db, event_data)
        logger.info(f"�?Created webhook event: {event.event_id}")
        
        # 标记为处理中
        processing = await WebhookEventService.mark_processing(db, "test-event-001")
        if processing and processing.processing_status == "processing":
            logger.info(f"�?Marked event as processing")
        else:
            logger.error("�?Failed to mark as processing")
            return False
        
        # 标记为完�?        completed = await WebhookEventService.mark_completed(db, "test-event-001", {"result": "success"})
        if completed and completed.processing_status == "completed":
            logger.info(f"�?Marked event as completed")
        else:
            logger.error("�?Failed to mark as completed")
            return False
        
        # 幂等性测�?        duplicate = await WebhookEventService.get_by_event_id(db, "test-event-001")
        if duplicate and duplicate.is_processed:
            logger.info(f"�?Idempotency check passed")
        else:
            logger.error("�?Idempotency check failed")
            return False
    
    return True


async def cleanup_test_data():
    """清理测试数据"""
    logger.info("\n" + "="*60)
    logger.info("Cleaning up test data...")
    logger.info("="*60)
    
    async with get_db_context() as db:
        # 删除测试数据
        await db.execute("DELETE FROM webhook_events WHERE event_id LIKE 'test-%'")
        await db.execute("DELETE FROM user_subscriptions WHERE subscription_id IN (SELECT id FROM subscriptions WHERE subscription_id LIKE 'test-%')")
        await db.execute("DELETE FROM subscriptions WHERE subscription_id LIKE 'test-%'")
        await db.execute("DELETE FROM users WHERE azure_ad_oid LIKE 'test-%'")
        
        logger.info("�?Test data cleaned up")


async def main():
    """运行所有测�?""
    logger.info("\n" + "🧪 Starting database tests...\n")
    
    tests = [
        ("Connection Test", test_connection),
        ("Health Check Test", test_health_check),
        ("Tables Exist Test", test_tables_exist),
        ("User Operations Test", test_user_operations),
        ("Subscription Operations Test", test_subscription_operations),
        ("Webhook Event Operations Test", test_webhook_event_operations),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = await test_func()
            results.append((test_name, result))
        except Exception as e:
            logger.error(f"�?{test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # 清理测试数据
    try:
        await cleanup_test_data()
    except Exception as e:
        logger.error(f"⚠️ Cleanup failed: {e}")
    
    # 打印总结
    logger.info("\n" + "="*60)
    logger.info("Test Summary")
    logger.info("="*60)
    
    for test_name, result in results:
        status = "�?PASSED" if result else "�?FAILED"
        logger.info(f"{status} - {test_name}")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    logger.info("="*60)
    logger.info(f"Total: {passed}/{total} tests passed")
    logger.info("="*60)
    
    if passed == total:
        logger.info("\n🎉 All tests passed!")
        sys.exit(0)
    else:
        logger.error(f"\n�?{total - passed} test(s) failed")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())

