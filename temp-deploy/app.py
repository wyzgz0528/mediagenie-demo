from flask import Flask, render_template, request, jsonify, redirect, url_for
import os
import json
import requests
from datetime import datetime

app = Flask(__name__)

# 配置
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:8001')
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')

@app.route('/')
def landing_page():
    """Azure Marketplace Landing Page"""
    return render_template('landing.html', 
                         frontend_url=FRONTEND_URL,
                         backend_url=BACKEND_URL)

@app.route('/health')
def health_check():
    """健康检查端�?""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
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
            "timestamp": datetime.utcnow().isoformat()
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    # 读取环境变量 PORT �?WEBSITES_PORT (Azure App Service)
    port = int(os.getenv('WEBSITES_PORT', os.getenv('PORT', '5000')))
    app.run(host='0.0.0.0', port=port, debug=False)