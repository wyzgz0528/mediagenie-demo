#!/usr/bin/env python3
"""
API 端点测试脚本
测试 MediaGenie 后端服务的所有主�?API 端点
"""

import asyncio
import httpx
import json
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_URL = "http://localhost:9001"

async def test_health_endpoint():
    """测试健康检查端�?""
    logger.info("=" * 60)
    logger.info("测试 1: 健康检查端�?)
    logger.info("=" * 60)
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{BASE_URL}/health")
            logger.info(f"状态码: {response.status_code}")
            logger.info(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
            return response.status_code == 200
    except Exception as e:
        logger.error(f"�?错误: {e}")
        return False

async def test_marketplace_health():
    """测试 Marketplace 健康检�?""
    logger.info("\n" + "=" * 60)
    logger.info("测试 2: Marketplace 健康检�?)
    logger.info("=" * 60)
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{BASE_URL}/marketplace/health")
            logger.info(f"状态码: {response.status_code}")
            logger.info(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
            return response.status_code == 200
    except Exception as e:
        logger.error(f"�?错误: {e}")
        return False

async def test_webhook_endpoint():
    """测试 Webhook 端点"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 3: Webhook 端点")
    logger.info("=" * 60)
    
    webhook_payload = {
        "id": "test-webhook-001",
        "activityId": "activity-001",
        "subscriptionId": "sub-test-001",
        "offerId": "offer-test",
        "publisherId": "publisher-test",
        "planId": "basic",
        "quantity": 1,
        "timeStamp": datetime.utcnow().isoformat() + "Z",
        "action": "Subscribe",
        "status": "Success"
    }
    
    logger.info(f"发�?Webhook 数据: {json.dumps(webhook_payload, indent=2, ensure_ascii=False)}")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{BASE_URL}/marketplace/webhook",
                json=webhook_payload,
                headers={"Content-Type": "application/json"}
            )
            logger.info(f"状态码: {response.status_code}")
            logger.info(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
            return response.status_code in [200, 201, 202]
    except Exception as e:
        logger.error(f"�?错误: {e}")
        return False

async def test_marketplace_events():
    """测试获取 Marketplace 事件列表"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 4: 获取 Marketplace 事件列表")
    logger.info("=" * 60)
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{BASE_URL}/marketplace/events")
            logger.info(f"状态码: {response.status_code}")
            logger.info(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
            return response.status_code == 200
    except Exception as e:
        logger.error(f"�?错误: {e}")
        return False

async def test_docs_endpoint():
    """测试 Swagger UI 文档"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 5: Swagger UI 文档")
    logger.info("=" * 60)
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{BASE_URL}/docs")
            logger.info(f"状态码: {response.status_code}")
            if response.status_code == 200:
                logger.info("�?Swagger UI 可访�?)
                logger.info(f"访问地址: {BASE_URL}/docs")
            return response.status_code == 200
    except Exception as e:
        logger.error(f"�?错误: {e}")
        return False

async def run_all_tests():
    """运行所有测�?""
    logger.info("\n")
    logger.info("🧪 开�?API 端点测试")
    logger.info("=" * 60)
    
    results = {
        "健康检�?: await test_health_endpoint(),
        "Marketplace 健康检�?: await test_marketplace_health(),
        "Webhook 端点": await test_webhook_endpoint(),
        "事件列表": await test_marketplace_events(),
        "Swagger UI": await test_docs_endpoint(),
    }
    
    logger.info("\n" + "=" * 60)
    logger.info("📊 测试结果总结")
    logger.info("=" * 60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, result in results.items():
        status = "�?PASSED" if result else "�?FAILED"
        logger.info(f"{status} - {test_name}")
    
    logger.info("=" * 60)
    logger.info(f"总计: {passed}/{total} 测试通过")
    logger.info("=" * 60)
    
    return passed == total

if __name__ == "__main__":
    logger.info("⚠️  请确保后端服务已启动�?http://localhost:9001")
    logger.info("启动命令: python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload")
    logger.info("")
    
    success = asyncio.run(run_all_tests())
    exit(0 if success else 1)

