#!/bin/bash
# Azure App Service optimized startup script for MediaGenie
# This version doesn't require supervisord

echo "🚀 Starting MediaGenie Application on Azure App Service..."

# Set working directory
cd /home/site/wwwroot

# Install system dependencies if needed
echo "📦 Checking system dependencies..."
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Install Python dependencies
if [ -f requirements.txt ]; then
    echo "📦 Installing Python dependencies..."
    python -m pip install --upgrade pip
    pip install -r requirements.txt
fi

# Install frontend dependencies
if [ -d frontend ] && [ -f frontend/package.json ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend
    if [ ! -d node_modules ]; then
        npm install --production
    fi
    cd ..
fi

# Start backend service on port 8001 in background
echo "🎯 Starting backend service (FastAPI)..."
cd /home/site/wwwroot/backend/media-service
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi
nohup python -m uvicorn main:app --host 0.0.0.0 --port 8001 > /home/site/wwwroot/backend.log 2>&1 &
BACKEND_PID=$!
echo "✅ Backend started with PID: $BACKEND_PID"

# Wait a moment for backend to start
sleep 3

# Start marketplace portal on port 5000 in background
echo "🎯 Starting marketplace portal (Flask)..."
cd /home/site/wwwroot/marketplace-portal
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi
nohup python app.py > /home/site/wwwroot/marketplace.log 2>&1 &
MARKETPLACE_PID=$!
echo "✅ Marketplace started with PID: $MARKETPLACE_PID"

# Wait a moment
sleep 2

# Start frontend server on PORT (Azure assigns this, typically 8080)
echo "🎯 Starting frontend server (Express)..."
cd /home/site/wwwroot/frontend

# Use Azure's PORT environment variable or default to 8080
export PORT=${PORT:-8080}
echo "Frontend will listen on port: $PORT"

# Start Express server (this runs in foreground to keep container alive)
exec node server.js
