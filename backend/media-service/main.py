#!/usr/bin/env python3
"""
MediaGenie Backend - API Service
Simplified FastAPI application for deployment testing
"""

import os
import sys
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Create FastAPI application
app = FastAPI(
    title="MediaGenie Backend API",
    description="MediaGenie Backend Service",
    version="1.0.0"
)

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
    """Root endpoint"""
    return {
        "message": "MediaGenie Backend API",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "mediagenie-backend",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.get("/api/test")
async def test_endpoint():
    """Test endpoint"""
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
