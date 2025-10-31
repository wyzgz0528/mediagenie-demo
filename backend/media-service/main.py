from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os
#!/usr/bin/env python3
"""
MediaGenie Backend - 测试版本
最简化的FastAPI应用，用于验证部署环境
"""

import os
import sys
#!/usr/bin/env python3
"""
MediaGenie Backend - 测试版本
最简化的FastAPI应用，用于验证部署环境
"""

import os
import sys
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 创建FastAPI应用
app = FastAPI(
    title="MediaGenie Backend - Test",
    description="MediaGenie 后端服务测试版本",
    version="1.0.0-test"
)

# 挂载前端静态文件到 /static 路径
app.mount("/static", StaticFiles(directory="static", html=True), name="static")

# fallback: 除API外的所有路径都返回 index.html（支持前端路由）
@app.get("/{full_path:path}")
async def frontend_fallback(full_path: str):
    index_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path, media_type="text/html")
    return {"error": "index.html not found"}

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 测试时允许所有来源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """根路径 - 返回前端 index.html（前端一体化）"""
    index_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path, media_type="text/html")
    # 回退到后端的简单 JSON（如果前端文件缺失）
    return {
        "message": "MediaGenie Backend Test API",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0-test"
    }

@app.get("/health")
async def health_check():
    """健康检查端点"""
    return {
        "status": "healthy",
        "service": "mediagenie-backend-test",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0-test",
        "python_version": sys.version,
        "environment": {
            "PORT": os.getenv("PORT", "8000"),
            "WEBSITES_PORT": os.getenv("WEBSITES_PORT", "Not set"),
            "PYTHONPATH": os.getenv("PYTHONPATH", "Not set"),
            "PWD": os.getcwd()
        }
    }

@app.get("/test")
async def test_endpoint():
    """测试端点"""
    return {
        "message": "Test endpoint working!",
        "timestamp": datetime.utcnow().isoformat(),
        "status": "success"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("WEBSITES_PORT", os.getenv("PORT", "8000")))
    print(f"🚀 Starting MediaGenie Test Backend on port {port}")
    print(f"🐍 Python version: {sys.version}")
    print(f"📁 Working directory: {os.getcwd()}")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=False,
        log_level="info"
    )
