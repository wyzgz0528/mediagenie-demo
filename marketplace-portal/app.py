from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import os
import json
import requests
from datetime import datetime
import logging
import sys

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

# 配置
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:9001')
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')

# Azure AD 配置
AZURE_AD_TENANT_ID = os.getenv('AZURE_AD_TENANT_ID')
AZURE_AD_CLIENT_ID = os.getenv('AZURE_AD_CLIENT_ID')
AZURE_AD_CLIENT_SECRET = os.getenv('AZURE_AD_CLIENT_SECRET')

# Marketplace API 配置
MARKETPLACE_API_BASE_URL = os.getenv('MARKETPLACE_API_BASE_URL', 'https://marketplaceapi.microsoft.com/api')
MARKETPLACE_API_VERSION = os.getenv('MARKETPLACE_API_VERSION', '2018-08-31')

# 本地开发模�?- 用于测试，不需要真实的 Azure AD 凭证
DEV_MODE = os.getenv('DEV_MODE', 'true').lower() == 'true'
logger.info(f"DEV_MODE: {DEV_MODE}")


def get_access_token():
    """
    获取 Azure AD 访问令牌
    用于调用 Marketplace SaaS Fulfillment API
    """
    if not all([AZURE_AD_TENANT_ID, AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET]):
        logger.error("Azure AD credentials not configured")
        return None

    token_url = f"https://login.microsoftonline.com/{AZURE_AD_TENANT_ID}/oauth2/v2.0/token"

    data = {
        'grant_type': 'client_credentials',
        'client_id': AZURE_AD_CLIENT_ID,
        'client_secret': AZURE_AD_CLIENT_SECRET,
        'scope': '20e940b3-4c77-4b0b-9a53-9e16a1b010a7/.default'  # Marketplace API scope
    }

    try:
        response = requests.post(token_url, data=data, timeout=10)
        response.raise_for_status()
        token_data = response.json()
        return token_data.get('access_token')
    except Exception as e:
        logger.error(f"Failed to get access token: {e}")
        return None


def resolve_subscription(marketplace_token):
    """
    调用 Resolve API 解析 Marketplace token
    获取订阅详情
    """
    access_token = get_access_token()
    if not access_token:
        raise Exception("Failed to get access token")

    url = f"{MARKETPLACE_API_BASE_URL}/saas/subscriptions/resolve?api-version={MARKETPLACE_API_VERSION}"

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json',
        'x-ms-marketplace-token': marketplace_token
    }

    try:
        logger.info(f"Calling Resolve API: {url}")
        response = requests.post(url, headers=headers, timeout=30)
        response.raise_for_status()
        subscription_data = response.json()
        logger.info(f"Resolve API success: {subscription_data.get('id')}")
        return subscription_data
    except Exception as e:
        logger.error(f"Resolve API failed: {e}")
        raise


def activate_subscription(subscription_id, plan_id, quantity=None):
    """
    调用 Activate API 激活订�?
    开始计�?
    """
    access_token = get_access_token()
    if not access_token:
        raise Exception("Failed to get access token")

    url = f"{MARKETPLACE_API_BASE_URL}/saas/subscriptions/{subscription_id}/activate?api-version={MARKETPLACE_API_VERSION}"

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }

    payload = {'planId': plan_id}
    if quantity is not None:
        payload['quantity'] = quantity

    try:
        logger.info(f"Calling Activate API: {url}")
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        logger.info(f"Activate API success: {subscription_id}")
        return True
    except Exception as e:
        logger.error(f"Activate API failed: {e}")
        raise


@app.route('/')
@app.route('/landing')
def landing_page():
    """
    Azure Marketplace Landing Page

    用户�?Marketplace 购买后首次访问此页面
    查询参数:
    - token: Marketplace 提供的临时令�?
    """
    marketplace_token = request.args.get('token')

    if not marketplace_token:
        logger.warning("Landing page accessed without token")
        return render_template('landing_activate.html',
                             error="Missing marketplace token. Please start from Azure Marketplace.",
                             frontend_url=FRONTEND_URL,
                             backend_url=BACKEND_URL)

    try:
        # 调用 Resolve API 获取订阅详情
        logger.info(f"Resolving subscription with token: {marketplace_token[:20]}...")
        subscription_data = resolve_subscription(marketplace_token)

        # 存储�?session
        session['subscription_data'] = subscription_data
        session['marketplace_token'] = marketplace_token

        logger.info(f"Subscription resolved: {subscription_data.get('id')}")

        # 渲染激活页�?
        return render_template('landing_activate.html',
                             subscription=subscription_data,
                             frontend_url=FRONTEND_URL,
                             backend_url=BACKEND_URL)

    except Exception as e:
        logger.error(f"Landing page error: {e}")
        return render_template('landing_activate.html',
                             error=f"Failed to resolve subscription: {str(e)}",
                             frontend_url=FRONTEND_URL,
                             backend_url=BACKEND_URL)

@app.route('/activate', methods=['POST'])
def activate():
    """
    激活订阅端�?

    用户�?Landing Page 点击"激�?按钮后调�?
    """
    try:
        # �?session 获取订阅数据
        subscription_data = session.get('subscription_data')

        if not subscription_data:
            return jsonify({
                "status": "error",
                "message": "No subscription data found. Please start from the landing page."
            }), 400

        subscription_id = subscription_data.get('id')
        plan_id = subscription_data.get('planId')
        quantity = subscription_data.get('quantity')

        logger.info(f"Activating subscription: {subscription_id}")

        # 调用 Activate API
        success = activate_subscription(subscription_id, plan_id, quantity)

        if success:
            # 保存订阅到后端数据库
            try:
                backend_response = requests.post(
                    f"{BACKEND_URL}/api/marketplace/subscriptions",
                    json=subscription_data,
                    timeout=10
                )
                logger.info(f"Saved subscription to backend: {backend_response.status_code}")
            except Exception as e:
                logger.warning(f"Failed to save to backend: {e}")

            # 清除 session
            session.pop('subscription_data', None)
            session.pop('marketplace_token', None)

            return jsonify({
                "status": "success",
                "message": "Subscription activated successfully",
                "subscription_id": subscription_id,
                "redirect_url": FRONTEND_URL
            })
        else:
            return jsonify({
                "status": "error",
                "message": "Failed to activate subscription"
            }), 500

    except Exception as e:
        logger.error(f"Activation error: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/health')
def health_check():
    """健康检查端�?""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "MediaGenie Marketplace Portal"
    })

@app.route('/api/marketplace/webhook', methods=['POST'])
def marketplace_webhook():
    """Azure Marketplace Connection Webhook"""
    try:
        # 获取请求数据
        webhook_data = request.get_json()
        
        # 记录webhook调用
        app.logger.info(f"Marketplace webhook called: {webhook_data}")
        
        # 处理不同类型的webhook事件
        action = webhook_data.get('action', 'unknown')
        
        if action == 'subscribe':
            return handle_subscribe(webhook_data)
        elif action == 'unsubscribe':
            return handle_unsubscribe(webhook_data)
        elif action == 'changePlan':
            return handle_change_plan(webhook_data)
        elif action == 'changeQuantity':
            return handle_change_quantity(webhook_data)
        else:
            return jsonify({
                "status": "success",
                "message": "Webhook received",
                "action": action
            }), 200
            
    except Exception as e:
        app.logger.error(f"Webhook error: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

def handle_subscribe(data):
    """处理订阅事件"""
    subscription_id = data.get('id')
    plan_id = data.get('planId')
    
    # 这里可以添加实际的订阅处理逻辑
    # 例如：创建用户账户、激活服务等
    
    return jsonify({
        "status": "success",
        "message": "Subscription activated",
        "subscriptionId": subscription_id,
        "planId": plan_id
    }), 200

def handle_unsubscribe(data):
    """处理取消订阅事件"""
    subscription_id = data.get('id')
    
    # 这里可以添加实际的取消订阅处理逻辑
    # 例如：停用服务、清理数据等
    
    return jsonify({
        "status": "success",
        "message": "Subscription cancelled",
        "subscriptionId": subscription_id
    }), 200

def handle_change_plan(data):
    """处理计划变更事件"""
    subscription_id = data.get('id')
    new_plan_id = data.get('planId')
    
    return jsonify({
        "status": "success",
        "message": "Plan changed",
        "subscriptionId": subscription_id,
        "newPlanId": new_plan_id
    }), 200

def handle_change_quantity(data):
    """处理数量变更事件"""
    subscription_id = data.get('id')
    quantity = data.get('quantity')
    
    return jsonify({
        "status": "success",
        "message": "Quantity changed",
        "subscriptionId": subscription_id,
        "quantity": quantity
    }), 200

@app.route('/api/status')
def api_status():
    """API状态检�?""
    try:
        # 检查后端服务状�?
        backend_status = "unknown"
        try:
            response = requests.get(f"{BACKEND_URL}/health", timeout=5)
            backend_status = "healthy" if response.status_code == 200 else "unhealthy"
        except:
            backend_status = "unreachable"

        return jsonify({
            "marketplace_portal": "healthy",
            "backend_service": backend_status,
            "frontend_url": FRONTEND_URL,
            "backend_url": BACKEND_URL,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/api/subscription/status/<subscription_id>')
def subscription_status(subscription_id):
    """
    查询订阅状�?

    用于前端查询订阅是否已激�?
    """
    try:
        # 从后端查询订阅状�?
        response = requests.get(
            f"{BACKEND_URL}/api/marketplace/subscriptions/{subscription_id}",
            timeout=10
        )

        if response.status_code == 200:
            return jsonify(response.json())
        elif response.status_code == 404:
            return jsonify({
                "status": "not_found",
                "message": "Subscription not found"
            }), 404
        else:
            return jsonify({
                "status": "error",
                "message": "Failed to query subscription status"
            }), 500

    except Exception as e:
        logger.error(f"Subscription status query error: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    # 读取环境变量 PORT �?WEBSITES_PORT (Azure App Service)
    port = int(os.getenv('WEBSITES_PORT', os.getenv('PORT', '5000')))
    app.run(host='0.0.0.0', port=port, debug=False)