"""
Azure Marketplace Landing Page and Webhook Handlers
处理 Marketplace 订阅事件和用户引导页�?
"""

from fastapi import APIRouter, Request, HTTPException, Query, Depends
from fastapi.responses import HTMLResponse, JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
import logging
import hmac
import hashlib
import json

from database import get_db
from db_service import SubscriptionService, WebhookEventService
from models import Subscription as SubscriptionModel

logger = logging.getLogger(__name__)

# 创建路由
marketplace_router = APIRouter(prefix="/marketplace", tags=["Marketplace"])

# ============================================================================
# Pydantic 模型 (用于 API 响应)
# ============================================================================

class MarketplaceSubscription(BaseModel):
    """Marketplace 订阅信息 (API 响应)"""
    subscription_id: str
    plan_id: str
    quantity: int
    customer_id: str
    customer_email: Optional[str] = None
    status: str  # "Subscribed", "Unsubscribed", "Suspended"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WebhookEvent(BaseModel):
    """Marketplace Webhook 事件 (API 响应)"""
    event_type: str  # "Subscribe", "Unsubscribe", "ChangePlan", "ChangeQuantity", "Suspend", "Reinstate"
    subscription_id: str
    plan_id: str
    quantity: int
    timestamp: datetime
    customer_id: str
    publisher_id: str
    offer_id: str


# ============================================================================
# Landing Page - Marketplace 用户首次访问页面
# ============================================================================

@marketplace_router.get("/landing", response_class=HTMLResponse)
async def landing_page(
    token: Optional[str] = Query(None, description="Marketplace token"),
    subscription_id: Optional[str] = Query(None, description="Subscription ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    Landing Page URL - Azure Marketplace 要求

    用户�?Marketplace 购买后首次访问此页面
    用于引导用户完成设置和激活订�?

    查询参数:
    - token: Marketplace 提供的临时令�?
    - subscription_id: 订阅 ID
    """
    logger.info(f"Landing page accessed: token={token}, subscription_id={subscription_id}")

    # 记录访问事件到数据库
    await WebhookEventService.create(db, {
        "event_type": "landing_page_visit",
        "subscription_id": subscription_id or "unknown",
        "event_timestamp": datetime.utcnow(),
        "raw_payload": {
            "token": token,
            "subscription_id": subscription_id
        }
    })
    
    # 生成 HTML 页面
    html_content = f"""
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>欢迎使用 MediaGenie - Azure Marketplace</title>
        <style>
            * {{
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }}
            
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #333;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }}
            
            .container {{
                background: white;
                border-radius: 16px;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                max-width: 800px;
                width: 100%;
                padding: 40px;
                animation: slideUp 0.5s ease-out;
            }}
            
            @keyframes slideUp {{
                from {{
                    opacity: 0;
                    transform: translateY(30px);
                }}
                to {{
                    opacity: 1;
                    transform: translateY(0);
                }}
            }}
            
            .header {{
                text-align: center;
                margin-bottom: 40px;
            }}
            
            .logo {{
                font-size: 48px;
                margin-bottom: 20px;
            }}
            
            h1 {{
                color: #667eea;
                font-size: 32px;
                margin-bottom: 10px;
            }}
            
            .subtitle {{
                color: #666;
                font-size: 18px;
            }}
            
            .success-icon {{
                width: 80px;
                height: 80px;
                background: #4CAF50;
                border-radius: 50%;
                margin: 0 auto 20px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 40px;
                color: white;
            }}
            
            .info-box {{
                background: #f8f9fa;
                border-left: 4px solid #667eea;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
            }}
            
            .info-box h3 {{
                color: #667eea;
                margin-bottom: 10px;
            }}
            
            .info-item {{
                display: flex;
                justify-content: space-between;
                padding: 10px 0;
                border-bottom: 1px solid #e0e0e0;
            }}
            
            .info-item:last-child {{
                border-bottom: none;
            }}
            
            .info-label {{
                font-weight: 600;
                color: #555;
            }}
            
            .info-value {{
                color: #333;
                font-family: monospace;
            }}
            
            .steps {{
                margin: 30px 0;
            }}
            
            .step {{
                display: flex;
                margin: 20px 0;
                align-items: flex-start;
            }}
            
            .step-number {{
                width: 40px;
                height: 40px;
                background: #667eea;
                color: white;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: bold;
                margin-right: 20px;
                flex-shrink: 0;
            }}
            
            .step-content h4 {{
                color: #333;
                margin-bottom: 5px;
            }}
            
            .step-content p {{
                color: #666;
                line-height: 1.6;
            }}
            
            .button-container {{
                text-align: center;
                margin-top: 40px;
            }}
            
            .btn {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                padding: 15px 40px;
                font-size: 18px;
                border-radius: 8px;
                cursor: pointer;
                text-decoration: none;
                display: inline-block;
                transition: transform 0.2s, box-shadow 0.2s;
            }}
            
            .btn:hover {{
                transform: translateY(-2px);
                box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
            }}
            
            .btn-secondary {{
                background: #6c757d;
                margin-left: 10px;
            }}
            
            .footer {{
                text-align: center;
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #e0e0e0;
                color: #666;
                font-size: 14px;
            }}
            
            .alert {{
                background: #fff3cd;
                border: 1px solid #ffc107;
                color: #856404;
                padding: 15px;
                border-radius: 8px;
                margin: 20px 0;
            }}
            
            .url-box {{
                background: #f8f9fa;
                padding: 15px;
                border-radius: 8px;
                margin: 10px 0;
                font-family: monospace;
                word-break: break-all;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="success-icon">�?/div>
                <h1>🎉 欢迎使用 MediaGenie!</h1>
                <p class="subtitle">感谢您从 Azure Marketplace 订阅我们的服�?/p>
            </div>
            
            {"<div class='alert'>⚠️ 此页面为演示模式。在生产环境�?您需要实现完整的订阅激活流程�?/div>" if not token else ""}
            
            <div class="info-box">
                <h3>📋 订阅信息</h3>
                <div class="info-item">
                    <span class="info-label">订阅 ID:</span>
                    <span class="info-value">{subscription_id or "待分�?}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">状�?</span>
                    <span class="info-value">激活中...</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Token:</span>
                    <span class="info-value">{token[:20] + "..." if token else "N/A"}</span>
                </div>
            </div>
            
            <div class="steps">
                <h3 style="color: #667eea; margin-bottom: 20px;">🚀 快速开�?/h3>
                
                <div class="step">
                    <div class="step-number">1</div>
                    <div class="step-content">
                        <h4>访问应用</h4>
                        <p>点击下方按钮访问您的 MediaGenie 应用主页</p>
                        <div class="url-box">
                            前端应用: <a href="/" target="_blank">打开应用</a>
                        </div>
                    </div>
                </div>
                
                <div class="step">
                    <div class="step-number">2</div>
                    <div class="step-content">
                        <h4>配置 Azure 服务</h4>
                        <p>确保您的 Azure 认知服务密钥已正确配�?(OpenAI, Speech, Vision)</p>
                    </div>
                </div>
                
                <div class="step">
                    <div class="step-number">3</div>
                    <div class="step-content">
                        <h4>开始使用功�?/h4>
                        <p>
                            �?语音转文�?- 上传音频文件进行转写<br>
                            �?文本转语�?- 将文本转换为自然语音<br>
                            �?图像分析 - 智能识别图像内容<br>
                            �?GPT 聊天 - AI 对话助手
                        </p>
                    </div>
                </div>
                
                <div class="step">
                    <div class="step-number">4</div>
                    <div class="step-content">
                        <h4>查看 API 文档</h4>
                        <p>访问 /docs 查看完整�?API 接口文档</p>
                        <div class="url-box">
                            API 文档: <a href="/docs" target="_blank">/docs</a>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="button-container">
                <a href="/" class="btn">🚀 开始使�?/a>
                <a href="/docs" class="btn btn-secondary">📖 查看文档</a>
            </div>
            
            <div class="footer">
                <p>📧 需要帮�? 联系我们: support@mediagenie.com</p>
                <p style="margin-top: 10px;">
                    <a href="/marketplace/health" style="color: #667eea; text-decoration: none;">系统状�?/a> | 
                    <a href="/health" style="color: #667eea; text-decoration: none;">健康检�?/a>
                </p>
            </div>
        </div>
        
        <script>
            // 如果�?token,可以在这里调�?API 激活订�?
            const token = "{token or ''}";
            const subscriptionId = "{subscription_id or ''}";
            
            if (token) {{
                console.log('Marketplace Token:', token);
                console.log('Subscription ID:', subscriptionId);
                
                // 可以调用后端 API 验证和激活订�?
                // fetch('/marketplace/activate', {{ ... }})
            }}
        </script>
    </body>
    </html>
    """
    
    return HTMLResponse(content=html_content)


# ============================================================================
# Connection Webhook - 接收 Marketplace 订阅事件
# ============================================================================

@marketplace_router.post("/webhook")
async def marketplace_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """
    Connection Webhook URL - Azure Marketplace 要求

    接收来自 Azure Marketplace 的订阅事件通知:
    - Subscribe: 用户订阅
    - Unsubscribe: 用户取消订阅
    - ChangePlan: 更改订阅计划
    - ChangeQuantity: 更改订阅数量
    - Suspend: 暂停订阅
    - Reinstate: 恢复订阅

    安全�? 应验证请求签�?(生产环境必需)
    """
    try:
        # 读取请求�?
        body = await request.body()
        body_json = await request.json()

        # 验证签名 (生产环境必需)
        # signature = request.headers.get("x-ms-signature")
        # if not verify_signature(body, signature):
        #     raise HTTPException(status_code=401, detail="Invalid signature")

        # 解析事件
        event_type = body_json.get("action") or body_json.get("eventType")
        subscription_id = body_json.get("subscriptionId") or body_json.get("subscription_id")
        plan_id = body_json.get("planId") or body_json.get("plan_id")
        event_id = body_json.get("id") or f"{subscription_id}_{event_type}_{datetime.utcnow().timestamp()}"

        logger.info(f"Webhook received: {event_type} for subscription {subscription_id}")

        # 幂等性检�? 检查事件是否已处理
        existing_event = await WebhookEventService.get_by_event_id(db, event_id)
        if existing_event and existing_event.is_processed:
            logger.info(f"Event {event_id} already processed, skipping")
            return JSONResponse(
                status_code=200,
                content={
                    "status": "success",
                    "message": "Event already processed",
                    "event_id": event_id
                }
            )

        # 记录事件到数据库
        webhook_event = await WebhookEventService.create(db, {
            "event_id": event_id,
            "event_type": event_type,
            "subscription_id": subscription_id,
            "plan_id": plan_id,
            "quantity": body_json.get("quantity"),
            "event_timestamp": datetime.utcnow(),
            "raw_payload": body_json,
            "processing_status": "processing"
        })

        # 处理不同的事件类�?
        try:
            if event_type == "Subscribe":
                # 处理新订�?
                subscription_data = {
                    "subscription_id": subscription_id,
                    "plan_id": plan_id,
                    "quantity": body_json.get("quantity", 1),
                    "status": "Subscribed",
                    "offer_id": body_json.get("offerId", "unknown"),
                    "purchaser_email": body_json.get("purchaser", {}).get("emailId"),
                    "purchaser_oid": body_json.get("purchaser", {}).get("objectId"),
                    "purchaser_tenant_id": body_json.get("purchaser", {}).get("tenantId"),
                    "beneficiary_email": body_json.get("beneficiary", {}).get("emailId"),
                    "beneficiary_oid": body_json.get("beneficiary", {}).get("objectId"),
                    "beneficiary_tenant_id": body_json.get("beneficiary", {}).get("tenantId"),
                    "raw_data": body_json
                }
                await SubscriptionService.create(db, subscription_data)
                logger.info(f"New subscription created: {subscription_id}")

            elif event_type == "Unsubscribe":
                # 处理取消订阅
                await SubscriptionService.update_status(db, subscription_id, "Unsubscribed")
                logger.info(f"Subscription unsubscribed: {subscription_id}")

            elif event_type == "ChangePlan":
                # 处理更改计划
                await SubscriptionService.update_plan(db, subscription_id, plan_id)
                logger.info(f"Subscription plan changed: {subscription_id} -> {plan_id}")

            elif event_type == "ChangeQuantity":
                # 处理更改数量
                new_quantity = body_json.get("quantity", 1)
                await SubscriptionService.update_quantity(db, subscription_id, new_quantity)
                logger.info(f"Subscription quantity changed: {subscription_id}")

            elif event_type == "Suspend":
                # 处理暂停
                await SubscriptionService.update_status(db, subscription_id, "Suspended")
                logger.info(f"Subscription suspended: {subscription_id}")

            elif event_type == "Reinstate":
                # 处理恢复
                await SubscriptionService.update_status(db, subscription_id, "Subscribed")
                logger.info(f"Subscription reinstated: {subscription_id}")

            # 标记事件为已完成
            await WebhookEventService.mark_completed(db, event_id, {"status": "success"})

        except Exception as processing_error:
            # 标记事件为失�?
            await WebhookEventService.mark_failed(db, event_id, str(processing_error))
            raise

        # 返回成功响应
        return JSONResponse(
            status_code=200,
            content={
                "status": "success",
                "message": f"Event {event_type} processed successfully",
                "subscription_id": subscription_id,
                "event_id": event_id
            }
        )

    except Exception as e:
        logger.error(f"Webhook processing error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# 管理端点
# ============================================================================

@marketplace_router.get("/subscriptions")
async def list_subscriptions(db: AsyncSession = Depends(get_db)):
    """列出所有订�?""
    subscriptions = await SubscriptionService.get_all_active(db)
    return {
        "total": len(subscriptions),
        "subscriptions": [
            {
                "subscription_id": sub.subscription_id,
                "plan_id": sub.plan_id,
                "status": sub.status,
                "quantity": sub.quantity,
                "created_at": sub.created_at.isoformat() if sub.created_at else None,
                "activated_at": sub.activated_at.isoformat() if sub.activated_at else None
            }
            for sub in subscriptions
        ]
    }


@marketplace_router.get("/subscriptions/{subscription_id}")
async def get_subscription(subscription_id: str, db: AsyncSession = Depends(get_db)):
    """获取订阅详情"""
    subscription = await SubscriptionService.get_by_subscription_id(db, subscription_id)
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")

    return {
        "subscription_id": subscription.subscription_id,
        "subscription_name": subscription.subscription_name,
        "plan_id": subscription.plan_id,
        "quantity": subscription.quantity,
        "status": subscription.status,
        "offer_id": subscription.offer_id,
        "purchaser_email": subscription.purchaser_email,
        "beneficiary_email": subscription.beneficiary_email,
        "created_at": subscription.created_at.isoformat() if subscription.created_at else None,
        "activated_at": subscription.activated_at.isoformat() if subscription.activated_at else None,
        "is_active": subscription.is_active,
        "is_suspended": subscription.is_suspended
    }


@marketplace_router.get("/events")
async def list_events(
    limit: int = Query(50, le=500),
    db: AsyncSession = Depends(get_db)
):
    """列出事件日志"""
    from sqlalchemy import select, desc
    from models import WebhookEvent as WebhookEventModel

    result = await db.execute(
        select(WebhookEventModel)
        .order_by(desc(WebhookEventModel.received_at))
        .limit(limit)
    )
    events = result.scalars().all()

    return {
        "total": len(events),
        "events": [
            {
                "event_id": event.event_id,
                "event_type": event.event_type,
                "subscription_id": event.subscription_id,
                "processing_status": event.processing_status,
                "received_at": event.received_at.isoformat() if event.received_at else None,
                "processed_at": event.processed_at.isoformat() if event.processed_at else None
            }
            for event in events
        ]
    }


@marketplace_router.get("/health")
async def marketplace_health(db: AsyncSession = Depends(get_db)):
    """Marketplace 健康检�?""
    from sqlalchemy import select, func
    from models import WebhookEvent as WebhookEventModel

    # 统计订阅数量
    subscription_count_result = await db.execute(
        select(func.count(SubscriptionModel.id))
    )
    subscription_count = subscription_count_result.scalar()

    # 统计事件数量
    event_count_result = await db.execute(
        select(func.count(WebhookEventModel.id))
    )
    event_count = event_count_result.scalar()

    return {
        "status": "healthy",
        "service": "MediaGenie Marketplace Integration",
        "version": "1.0.0",
        "database": "connected",
        "subscriptions": subscription_count,
        "events_logged": event_count,
        "timestamp": datetime.utcnow().isoformat()
    }


# ============================================================================
# 辅助函数
# ============================================================================

def verify_signature(body: bytes, signature: str) -> bool:
    """
    验证 Marketplace Webhook 签名
    
    生产环境必需: 使用共享密钥验证请求来自 Azure Marketplace
    """
    # TODO: 实现签名验证
    # shared_secret = os.getenv("MARKETPLACE_WEBHOOK_SECRET")
    # expected_signature = hmac.new(
    #     shared_secret.encode(),
    #     body,
    #     hashlib.sha256
    # ).hexdigest()
    # return hmac.compare_digest(signature, expected_signature)
    return True  # 演示模式
