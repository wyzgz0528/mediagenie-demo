"""
Azure Marketplace SaaS Fulfillment API v2 客户�?

功能:
1. Resolve: 解析 marketplace token,获取订阅详情
2. Activate: 激活订�?开始计�?
3. Update: 变更订阅计划或数�?
4. Delete: 取消订阅
5. Get Subscription: 查询订阅状�?
6. List Subscriptions: 列出所有订�?

API 文档: https://learn.microsoft.com/en-us/azure/marketplace/partner-center-portal/pc-saas-fulfillment-api-v2
"""

import logging
from typing import Optional, Dict, Any, List
from enum import Enum
from datetime import datetime

import httpx
from pydantic import BaseModel, Field
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

from auth_middleware import AzureADServicePrincipal, get_service_principal

logger = logging.getLogger(__name__)


# ============================================
# 数据模型
# ============================================

class SubscriptionStatus(str, Enum):
    """订阅状态枚�?""
    PENDING_FULFILLMENT_START = "PendingFulfillmentStart"  # 待激�?
    SUBSCRIBED = "Subscribed"  # 已激�?
    SUSPENDED = "Suspended"  # 已暂�?(支付失败)
    UNSUBSCRIBED = "Unsubscribed"  # 已取�?


class SessionMode(str, Enum):
    """会话模式"""
    NONE = "None"
    DRY_RUN = "DryRun"


class SandboxType(str, Enum):
    """沙箱类型"""
    NONE = "None"
    CINT = "Cint"


class Beneficiary(BaseModel):
    """受益�?(实际使用�?"""
    email_id: str = Field(alias="emailId")
    object_id: str = Field(alias="objectId")
    tenant_id: str = Field(alias="tenantId")
    puid: Optional[str] = None
    
    class Config:
        populate_by_name = True


class Purchaser(BaseModel):
    """购买�?""
    email_id: str = Field(alias="emailId")
    object_id: str = Field(alias="objectId")
    tenant_id: str = Field(alias="tenantId")
    puid: Optional[str] = None
    
    class Config:
        populate_by_name = True


class Term(BaseModel):
    """订阅期限"""
    start_date: datetime = Field(alias="startDate")
    end_date: datetime = Field(alias="endDate")
    term_unit: str = Field(alias="termUnit")  # P1M (1个月), P1Y (1�?
    
    class Config:
        populate_by_name = True


class MarketplaceSubscription(BaseModel):
    """Marketplace 订阅完整信息"""
    id: str
    publisher_id: str = Field(alias="publisherId")
    offer_id: str = Field(alias="offerId")
    name: str
    saas_subscription_status: SubscriptionStatus = Field(alias="saasSubscriptionStatus")
    beneficiary: Beneficiary
    purchaser: Purchaser
    plan_id: str = Field(alias="planId")
    term: Term
    is_free_trial: bool = Field(alias="isFreeTrial")
    is_test: bool = Field(alias="isTest")
    allowed_customer_operations: List[str] = Field(alias="allowedCustomerOperations")
    session_mode: SessionMode = Field(alias="sessionMode")
    sandbox_type: SandboxType = Field(alias="sandboxType")
    created: datetime
    last_modified: datetime = Field(alias="lastModified")
    
    # 可选字�?
    quantity: Optional[int] = None
    subscription_name: Optional[str] = Field(None, alias="subscriptionName")
    
    class Config:
        populate_by_name = True


class ResolvedSubscription(BaseModel):
    """Resolve API 响应"""
    id: str
    subscription_name: str = Field(alias="subscriptionName")
    offer_id: str = Field(alias="offerId")
    plan_id: str = Field(alias="planId")
    quantity: Optional[int] = None
    subscription: MarketplaceSubscription
    
    class Config:
        populate_by_name = True


class SubscriptionUpdate(BaseModel):
    """订阅更新请求"""
    plan_id: str = Field(alias="planId")
    quantity: Optional[int] = None
    
    class Config:
        populate_by_name = True


# ============================================
# SaaS Fulfillment API 客户�?
# ============================================

class SaaSFulfillmentClient:
    """Azure Marketplace SaaS Fulfillment API v2 客户�?""
    
    def __init__(
        self,
        service_principal: AzureADServicePrincipal,
        api_base_url: str = "https://marketplaceapi.microsoft.com/api",
        api_version: str = "2018-08-31"
    ):
        """
        初始化客户端
        
        Args:
            service_principal: Azure AD Service Principal (用于获取 access token)
            api_base_url: Marketplace API 基础 URL
            api_version: API 版本
        """
        self.service_principal = service_principal
        self.api_base_url = api_base_url.rstrip("/")
        self.api_version = api_version
        
        logger.info(f"SaaS Fulfillment Client initialized: {api_base_url}")
    
    async def _get_headers(
        self,
        marketplace_token: Optional[str] = None
    ) -> Dict[str, str]:
        """
        构建请求�?
        
        Args:
            marketplace_token: Marketplace token (仅用�?Resolve API)
            
        Returns:
            Dict[str, str]: 请求�?
        """
        # 获取 access token
        access_token = await self.service_principal.get_access_token()
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        # Resolve API 需要额外的 marketplace token
        if marketplace_token:
            headers["x-ms-marketplace-token"] = marketplace_token
        
        return headers
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(httpx.HTTPStatusError),
        reraise=True
    )
    async def _make_request(
        self,
        method: str,
        url: str,
        headers: Dict[str, str],
        json: Optional[Dict[str, Any]] = None
    ) -> httpx.Response:
        """
        发起 HTTP 请求 (带重试机�?
        
        Args:
            method: HTTP 方法
            url: 完整 URL
            headers: 请求�?
            json: 请求�?(JSON)
            
        Returns:
            httpx.Response: 响应对象
            
        Raises:
            httpx.HTTPStatusError: HTTP 错误
        """
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.request(
                method=method,
                url=url,
                headers=headers,
                json=json
            )
            
            # 记录请求日志
            logger.info(
                f"{method} {url} -> {response.status_code}"
            )
            
            if response.status_code >= 400:
                logger.error(
                    f"API Error: {response.status_code} - {response.text}"
                )
            
            response.raise_for_status()
            return response
    
    # ============================================
    # 核心 API 方法
    # ============================================
    
    async def resolve_subscription(
        self,
        marketplace_token: str
    ) -> ResolvedSubscription:
        """
        Resolve API: 解析 marketplace token,获取订阅详情
        
        用�? Landing page 接收 token 后调用此 API 获取订阅信息
        
        Args:
            marketplace_token: Marketplace 重定向时携带�?token
            
        Returns:
            ResolvedSubscription: 订阅详情
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info("Resolving subscription from marketplace token")
        
        url = (
            f"{self.api_base_url}/saas/subscriptions/resolve"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers(marketplace_token=marketplace_token)
        
        response = await self._make_request("POST", url, headers)
        data = response.json()
        
        resolved = ResolvedSubscription(**data)
        logger.info(
            f"Resolved subscription: {resolved.id} "
            f"(plan: {resolved.plan_id}, status: {resolved.subscription.saas_subscription_status})"
        )
        
        return resolved
    
    async def activate_subscription(
        self,
        subscription_id: str,
        plan_id: str,
        quantity: Optional[int] = None
    ) -> bool:
        """
        Activate API: 激活订�?开始计�?
        
        用�? Landing page 用户确认后调用此 API 激活订�?
        
        Args:
            subscription_id: 订阅 ID
            plan_id: 计划 ID
            quantity: 数量 (可�?
            
        Returns:
            bool: 激活是否成�?
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info(
            f"Activating subscription {subscription_id} "
            f"with plan {plan_id}, quantity {quantity}"
        )
        
        url = (
            f"{self.api_base_url}/saas/subscriptions/{subscription_id}/activate"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers()
        
        payload = {"planId": plan_id}
        if quantity is not None:
            payload["quantity"] = quantity
        
        try:
            response = await self._make_request("POST", url, headers, json=payload)
            logger.info(f"Subscription {subscription_id} activated successfully")
            return True
        
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 409:
                # 409 Conflict: 订阅已激�?
                logger.warning(f"Subscription {subscription_id} already activated")
                return True  # 视为成功
            raise
    
    async def get_subscription(
        self,
        subscription_id: str
    ) -> MarketplaceSubscription:
        """
        Get Subscription API: 查询订阅详情
        
        用�? 同步订阅状�?验证订阅有效�?
        
        Args:
            subscription_id: 订阅 ID
            
        Returns:
            MarketplaceSubscription: 订阅详情
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info(f"Getting subscription details for {subscription_id}")
        
        url = (
            f"{self.api_base_url}/saas/subscriptions/{subscription_id}"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers()
        
        response = await self._make_request("GET", url, headers)
        data = response.json()
        
        subscription = MarketplaceSubscription(**data)
        logger.info(
            f"Got subscription: {subscription.id} "
            f"(status: {subscription.saas_subscription_status})"
        )
        
        return subscription
    
    async def list_subscriptions(self) -> List[MarketplaceSubscription]:
        """
        List Subscriptions API: 列出所有订�?
        
        用�? 定期同步所有订阅状�?
        
        Returns:
            List[MarketplaceSubscription]: 订阅列表
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info("Listing all subscriptions")
        
        url = (
            f"{self.api_base_url}/saas/subscriptions"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers()
        
        response = await self._make_request("GET", url, headers)
        data = response.json()
        
        # API 返回 {"subscriptions": [...]}
        subscriptions_data = data.get("subscriptions", [])
        subscriptions = [
            MarketplaceSubscription(**sub) for sub in subscriptions_data
        ]
        
        logger.info(f"Found {len(subscriptions)} subscriptions")
        return subscriptions
    
    async def update_subscription(
        self,
        subscription_id: str,
        plan_id: str,
        quantity: Optional[int] = None
    ) -> bool:
        """
        Update Subscription API: 变更订阅计划或数�?
        
        注意: �?API 返回 202 Accepted,实际变更通过 Webhook 通知
        
        Args:
            subscription_id: 订阅 ID
            plan_id: 新计�?ID
            quantity: 新数�?(可�?
            
        Returns:
            bool: 请求是否接受
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info(
            f"Updating subscription {subscription_id} "
            f"to plan {plan_id}, quantity {quantity}"
        )
        
        url = (
            f"{self.api_base_url}/saas/subscriptions/{subscription_id}"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers()
        
        payload = {"planId": plan_id}
        if quantity is not None:
            payload["quantity"] = quantity
        
        response = await self._make_request("PATCH", url, headers, json=payload)
        
        if response.status_code == 202:
            logger.info(f"Subscription update request accepted for {subscription_id}")
            return True
        
        return False
    
    async def delete_subscription(
        self,
        subscription_id: str
    ) -> bool:
        """
        Delete Subscription API: 取消订阅
        
        注意: �?API 返回 202 Accepted,实际删除通过 Webhook 通知
        
        Args:
            subscription_id: 订阅 ID
            
        Returns:
            bool: 请求是否接受
            
        Raises:
            httpx.HTTPStatusError: API 调用失败
        """
        logger.info(f"Deleting subscription {subscription_id}")
        
        url = (
            f"{self.api_base_url}/saas/subscriptions/{subscription_id}"
            f"?api-version={self.api_version}"
        )
        
        headers = await self._get_headers()
        
        response = await self._make_request("DELETE", url, headers)
        
        if response.status_code == 202:
            logger.info(f"Subscription deletion request accepted for {subscription_id}")
            return True
        
        return False
    
    # ============================================
    # 便捷方法
    # ============================================
    
    async def is_subscription_active(self, subscription_id: str) -> bool:
        """
        检查订阅是否处于激活状�?
        
        Args:
            subscription_id: 订阅 ID
            
        Returns:
            bool: 是否激�?
        """
        try:
            subscription = await self.get_subscription(subscription_id)
            return subscription.saas_subscription_status == SubscriptionStatus.SUBSCRIBED
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                logger.warning(f"Subscription {subscription_id} not found")
                return False
            raise
    
    async def get_subscription_plan(self, subscription_id: str) -> Optional[str]:
        """
        获取订阅的当前计�?
        
        Args:
            subscription_id: 订阅 ID
            
        Returns:
            Optional[str]: 计划 ID,如果订阅不存在则返回 None
        """
        try:
            subscription = await self.get_subscription(subscription_id)
            return subscription.plan_id
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                return None
            raise


# ============================================
# 全局客户端实�?
# ============================================

_client_instance: Optional[SaaSFulfillmentClient] = None


def get_saas_client() -> SaaSFulfillmentClient:
    """
    获取 SaaS Fulfillment Client 单例
    
    Returns:
        SaaSFulfillmentClient: 客户端实�?
    """
    global _client_instance
    
    if _client_instance is None:
        service_principal = get_service_principal()
        _client_instance = SaaSFulfillmentClient(service_principal)
    
    return _client_instance


# ============================================
# 使用示例
# ============================================

"""
# �?Landing Page 中使�?

from saas_fulfillment_client import get_saas_client, SubscriptionStatus

@app.get("/landing")
async def landing_page(token: str, subscription_id: str):
    client = get_saas_client()
    
    # 1. 解析 token,获取订阅详情
    try:
        resolved = await client.resolve_subscription(token)
        
        # 检查订阅状�?
        if resolved.subscription.saas_subscription_status != SubscriptionStatus.PENDING_FULFILLMENT_START:
            return {"error": "Subscription already activated"}
        
        # 2. 显示订阅信息给用户确�?
        return {
            "subscription_id": resolved.id,
            "plan_id": resolved.plan_id,
            "quantity": resolved.quantity,
            "beneficiary": resolved.subscription.beneficiary.email_id
        }
    
    except httpx.HTTPStatusError as e:
        logger.error(f"Resolve failed: {e}")
        return {"error": "Invalid token"}


@app.post("/landing/activate")
async def activate(subscription_id: str):
    client = get_saas_client()
    
    # 1. 获取订阅详情
    subscription = await client.get_subscription(subscription_id)
    
    # 2. 激活订�?
    success = await client.activate_subscription(
        subscription_id=subscription.id,
        plan_id=subscription.plan_id,
        quantity=subscription.quantity
    )
    
    if success:
        # 3. 创建用户账号,关联订阅
        # ... (数据库操�?
        
        return {"message": "Subscription activated successfully"}
    else:
        return {"error": "Activation failed"}


# 在定时任务中同步订阅状�?

async def sync_subscriptions():
    client = get_saas_client()
    
    # 获取所有订�?
    subscriptions = await client.list_subscriptions()
    
    for sub in subscriptions:
        # 更新数据库中的订阅状�?
        logger.info(f"Subscription {sub.id}: {sub.saas_subscription_status}")
"""
