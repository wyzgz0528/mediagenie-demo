"""
Azure Marketplace Webhook 处理�?

功能:
1. 接收 Marketplace 订阅事件
2. 验证 Webhook 签名 (HMAC-SHA256)
3. 处理事件: Subscribe, Unsubscribe, ChangePlan, ChangeQuantity, Suspend, Reinstate
4. 持久化事件到数据�?
5. 触发业务逻辑 (更新订阅状态、发送通知�?
"""

import logging
import hmac
import hashlib
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum

from fastapi import APIRouter, Request, HTTPException, status, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import get_db
from saas_fulfillment_client import get_saas_client, SaaSFulfillmentClient

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/marketplace", tags=["Marketplace Webhook"])


# ============================================
# 数据模型
# ============================================

class WebhookEventType(str, Enum):
    """Webhook 事件类型"""
    SUBSCRIBE = "Subscribe"
    UNSUBSCRIBE = "Unsubscribe"
    CHANGE_PLAN = "ChangePlan"
    CHANGE_QUANTITY = "ChangeQuantity"
    SUSPEND = "Suspend"
    REINSTATE = "Reinstate"
    RENEW = "Renew"


class WebhookEventStatus(str, Enum):
    """事件状�?""
    SUCCESS = "Success"
    FAILURE = "Failure"
    IN_PROGRESS = "InProgress"


class ProcessingStatus(str, Enum):
    """处理状�?""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class WebhookPayload(BaseModel):
    """Webhook 事件 Payload"""
    id: str  # 事件 ID (幂等�?
    activity_id: str = Field(alias="activityId")
    subscription_id: str = Field(alias="subscriptionId")
    offer_id: str = Field(alias="offerId")
    publisher_id: str = Field(alias="publisherId")
    plan_id: str = Field(alias="planId")
    quantity: Optional[int] = None
    time_stamp: datetime = Field(alias="timeStamp")
    action: WebhookEventType
    status: WebhookEventStatus
    operation_request_source: Optional[str] = Field(None, alias="operationRequestSource")
    
    class Config:
        populate_by_name = True


# ============================================
# 签名验证
# ============================================

def verify_webhook_signature(
    request_body: bytes,
    signature_header: Optional[str],
    secret: str
) -> bool:
    """
    验证 Webhook 签名
    
    注意: Azure Marketplace 使用 x-ms-marketplace-token header
    具体签名算法需参考最新文�?这里提供基础实现
    
    Args:
        request_body: 原始请求 body (bytes)
        signature_header: 签名 header �?
        secret: Azure AD Client Secret
        
    Returns:
        bool: 签名是否有效
    """
    if not settings.WEBHOOK_SIGNATURE_ENABLED:
        logger.warning("Webhook signature verification is disabled")
        return True
    
    if not signature_header:
        logger.error("Missing signature header")
        return False
    
    try:
        # 计算期望的签�?(HMAC-SHA256)
        expected_signature = hmac.new(
            secret.encode('utf-8'),
            request_body,
            hashlib.sha256
        ).hexdigest()
        
        # 比较签名 (防止时序攻击)
        is_valid = hmac.compare_digest(
            expected_signature.lower(),
            signature_header.lower()
        )
        
        if not is_valid:
            logger.error("Webhook signature mismatch")
        
        return is_valid
    
    except Exception as e:
        logger.error(f"Signature verification error: {str(e)}")
        return False


# ============================================
# 事件处理�?
# ============================================

class WebhookEventProcessor:
    """Webhook 事件处理�?""
    
    def __init__(
        self,
        db: AsyncSession,
        saas_client: SaaSFulfillmentClient
    ):
        self.db = db
        self.saas_client = saas_client
    
    async def is_duplicate_event(self, event_id: str) -> bool:
        """
        检查事件是否已处理 (幂等�?
        
        Args:
            event_id: 事件 ID
            
        Returns:
            bool: 是否重复
        """
        from sqlalchemy import select, text
        
        query = text(
            "SELECT 1 FROM webhook_events WHERE event_id = :event_id LIMIT 1"
        )
        result = await self.db.execute(query, {"event_id": event_id})
        return result.scalar() is not None
    
    async def save_event(
        self,
        payload: WebhookPayload,
        raw_data: Dict[str, Any],
        processing_status: ProcessingStatus = ProcessingStatus.PENDING
    ) -> str:
        """
        保存事件到数据库
        
        Args:
            payload: Webhook payload
            raw_data: 原始 JSON 数据
            processing_status: 处理状�?
            
        Returns:
            str: 事件数据�?ID
        """
        from sqlalchemy import text
        import json
        
        query = text("""
            INSERT INTO webhook_events (
                event_id, activity_id, event_type, subscription_id,
                offer_id, publisher_id, plan_id, quantity,
                event_status, processing_status, event_timestamp,
                raw_payload, received_at
            ) VALUES (
                :event_id, :activity_id, :event_type, :subscription_id,
                :offer_id, :publisher_id, :plan_id, :quantity,
                :event_status, :processing_status, :event_timestamp,
                :raw_payload, CURRENT_TIMESTAMP
            )
            ON CONFLICT (event_id) DO NOTHING
            RETURNING id::text
        """)
        
        result = await self.db.execute(query, {
            "event_id": payload.id,
            "activity_id": payload.activity_id,
            "event_type": payload.action.value,
            "subscription_id": payload.subscription_id,
            "offer_id": payload.offer_id,
            "publisher_id": payload.publisher_id,
            "plan_id": payload.plan_id,
            "quantity": payload.quantity,
            "event_status": payload.status.value,
            "processing_status": processing_status.value,
            "event_timestamp": payload.time_stamp,
            "raw_payload": json.dumps(raw_data)
        })
        
        await self.db.commit()
        
        event_db_id = result.scalar()
        return event_db_id or payload.id
    
    async def update_event_status(
        self,
        event_id: str,
        processing_status: ProcessingStatus,
        error_message: Optional[str] = None
    ):
        """更新事件处理状�?""
        from sqlalchemy import text
        
        query = text("""
            UPDATE webhook_events
            SET processing_status = :status,
                processed_at = CURRENT_TIMESTAMP,
                error_message = :error_message
            WHERE event_id = :event_id
        """)
        
        await self.db.execute(query, {
            "event_id": event_id,
            "status": processing_status.value,
            "error_message": error_message
        })
        await self.db.commit()
    
    async def update_subscription_status(
        self,
        subscription_id: str,
        status: str,
        plan_id: Optional[str] = None,
        quantity: Optional[int] = None
    ):
        """更新订阅状�?""
        from sqlalchemy import text
        
        update_fields = ["status = :status", "updated_at = CURRENT_TIMESTAMP"]
        params = {
            "subscription_id": subscription_id,
            "status": status
        }
        
        if plan_id:
            update_fields.append("plan_id = :plan_id")
            params["plan_id"] = plan_id
        
        if quantity is not None:
            update_fields.append("quantity = :quantity")
            params["quantity"] = quantity
        
        query = text(f"""
            UPDATE subscriptions
            SET {', '.join(update_fields)}
            WHERE subscription_id = :subscription_id
        """)
        
        await self.db.execute(query, params)
        await self.db.commit()
    
    async def process_subscribe_event(self, payload: WebhookPayload):
        """处理订阅事件 (新订阅激�?"""
        logger.info(f"Processing Subscribe event for {payload.subscription_id}")
        
        # 更新订阅状态为 Subscribed
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Subscribed"
        )
        
        # TODO: 发送欢迎邮�?
        # TODO: 启用用户功能访问
        
        logger.info(f"Subscribe event processed: {payload.subscription_id}")
    
    async def process_unsubscribe_event(self, payload: WebhookPayload):
        """处理取消订阅事件"""
        logger.info(f"Processing Unsubscribe event for {payload.subscription_id}")
        
        # 更新订阅状态为 Unsubscribed
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Unsubscribed"
        )
        
        # TODO: 禁用用户功能访问
        # TODO: 发送取消确认邮�?
        
        logger.info(f"Unsubscribe event processed: {payload.subscription_id}")
    
    async def process_change_plan_event(self, payload: WebhookPayload):
        """处理变更计划事件"""
        logger.info(
            f"Processing ChangePlan event for {payload.subscription_id} "
            f"to plan {payload.plan_id}"
        )
        
        # 更新订阅计划
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Subscribed",
            plan_id=payload.plan_id
        )
        
        # TODO: 调整功能权限
        # TODO: 发送变更通知邮件
        
        logger.info(f"ChangePlan event processed: {payload.subscription_id}")
    
    async def process_change_quantity_event(self, payload: WebhookPayload):
        """处理变更数量事件"""
        logger.info(
            f"Processing ChangeQuantity event for {payload.subscription_id} "
            f"to quantity {payload.quantity}"
        )
        
        # 更新订阅数量
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Subscribed",
            quantity=payload.quantity
        )
        
        # TODO: 调整配额限制
        # TODO: 发送变更通知邮件
        
        logger.info(f"ChangeQuantity event processed: {payload.subscription_id}")
    
    async def process_suspend_event(self, payload: WebhookPayload):
        """处理暂停事件 (通常因为支付失败)"""
        logger.info(f"Processing Suspend event for {payload.subscription_id}")
        
        # 更新订阅状态为 Suspended
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Suspended"
        )
        
        # TODO: 限制功能访问
        # TODO: 发送支付提醒邮�?
        
        logger.warning(f"Subscription suspended: {payload.subscription_id}")
    
    async def process_reinstate_event(self, payload: WebhookPayload):
        """处理恢复事件 (支付恢复�?"""
        logger.info(f"Processing Reinstate event for {payload.subscription_id}")
        
        # 更新订阅状态为 Subscribed
        await self.update_subscription_status(
            subscription_id=payload.subscription_id,
            status="Subscribed"
        )
        
        # TODO: 恢复功能访问
        # TODO: 发送恢复确认邮�?
        
        logger.info(f"Subscription reinstated: {payload.subscription_id}")
    
    async def process_renew_event(self, payload: WebhookPayload):
        """处理续费事件"""
        logger.info(f"Processing Renew event for {payload.subscription_id}")
        
        # 同步订阅信息 (获取新的 term dates)
        try:
            subscription = await self.saas_client.get_subscription(
                payload.subscription_id
            )
            
            # 更新订阅期限
            from sqlalchemy import text
            query = text("""
                UPDATE subscriptions
                SET term_start_date = :start_date,
                    term_end_date = :end_date,
                    updated_at = CURRENT_TIMESTAMP
                WHERE subscription_id = :subscription_id
            """)
            
            await self.db.execute(query, {
                "subscription_id": payload.subscription_id,
                "start_date": subscription.term.start_date,
                "end_date": subscription.term.end_date
            })
            await self.db.commit()
            
            logger.info(f"Subscription renewed: {payload.subscription_id}")
        
        except Exception as e:
            logger.error(f"Failed to process renew event: {str(e)}")
            raise
    
    async def process_event(self, payload: WebhookPayload):
        """
        路由事件到对应的处理�?
        
        Args:
            payload: Webhook payload
        """
        handlers = {
            WebhookEventType.SUBSCRIBE: self.process_subscribe_event,
            WebhookEventType.UNSUBSCRIBE: self.process_unsubscribe_event,
            WebhookEventType.CHANGE_PLAN: self.process_change_plan_event,
            WebhookEventType.CHANGE_QUANTITY: self.process_change_quantity_event,
            WebhookEventType.SUSPEND: self.process_suspend_event,
            WebhookEventType.REINSTATE: self.process_reinstate_event,
            WebhookEventType.RENEW: self.process_renew_event,
        }
        
        handler = handlers.get(payload.action)
        if not handler:
            raise ValueError(f"Unknown event type: {payload.action}")
        
        await handler(payload)


# ============================================
# API 端点
# ============================================

@router.post("/webhook")
async def handle_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    saas_client: SaaSFulfillmentClient = Depends(get_saas_client)
):
    """
    接收 Azure Marketplace Webhook 事件
    
    此端点必�?
    1. 快速响�?(< 30�?
    2. 返回 200 OK
    3. 实现幂等�?(同一事件多次触发只处理一�?
    """
    # 1. 读取原始 body (用于签名验证)
    body_bytes = await request.body()
    
    # 2. 验证签名
    signature_header = request.headers.get("x-ms-marketplace-token")
    
    if settings.WEBHOOK_SIGNATURE_ENABLED:
        is_valid = verify_webhook_signature(
            request_body=body_bytes,
            signature_header=signature_header,
            secret=settings.AZURE_AD_CLIENT_SECRET
        )
        
        if not is_valid:
            logger.error("Webhook signature verification failed")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid signature"
            )
    
    # 3. 解析 payload
    try:
        data = await request.json()
        payload = WebhookPayload(**data)
    except Exception as e:
        logger.error(f"Failed to parse webhook payload: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payload format"
        )
    
    # 4. 检查幂等�?
    processor = WebhookEventProcessor(db, saas_client)
    
    if await processor.is_duplicate_event(payload.id):
        logger.info(f"Duplicate event {payload.id}, skipping")
        return {"status": "skipped", "message": "Event already processed"}
    
    # 5. 保存事件 (pending 状�?
    try:
        await processor.save_event(payload, data, ProcessingStatus.PENDING)
    except Exception as e:
        logger.error(f"Failed to save event: {str(e)}")
        # 即使保存失败也返�?200,避免 Marketplace 重试
        return {"status": "error", "message": "Failed to save event"}
    
    # 6. 异步处理事件 (后台任务)
    async def process_event_background():
        try:
            await processor.update_event_status(
                payload.id,
                ProcessingStatus.PROCESSING
            )
            
            await processor.process_event(payload)
            
            await processor.update_event_status(
                payload.id,
                ProcessingStatus.COMPLETED
            )
            
            logger.info(f"Event {payload.id} processed successfully")
        
        except Exception as e:
            logger.error(f"Failed to process event {payload.id}: {str(e)}")
            
            await processor.update_event_status(
                payload.id,
                ProcessingStatus.FAILED,
                error_message=str(e)
            )
    
    background_tasks.add_task(process_event_background)
    
    # 7. 立即返回 200 OK
    return {
        "status": "accepted",
        "event_id": payload.id,
        "message": "Event accepted for processing"
    }


@router.get("/webhook/health")
async def webhook_health():
    """Webhook 健康检查端�?""
    return {
        "status": "ok",
        "service": "marketplace-webhook",
        "timestamp": datetime.now().isoformat()
    }


# ============================================
# 使用示例
# ============================================

"""
# �?main.py 中注册路�?

from marketplace_webhook import router as marketplace_webhook_router

app.include_router(marketplace_webhook_router)


# �?Partner Center 配置 Webhook URL:
# https://mediagenie-backend.azurewebsites.net/marketplace/webhook


# 测试 Webhook (使用 curl)

curl -X POST https://mediagenie-backend.azurewebsites.net/marketplace/webhook \
  -H "Content-Type: application/json" \
  -H "x-ms-marketplace-token: test-signature" \
  -d '{
    "id": "test-event-1",
    "activityId": "test-activity-1",
    "subscriptionId": "sub-123",
    "offerId": "mediagenie",
    "publisherId": "your-publisher-id",
    "planId": "standard",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'
"""
