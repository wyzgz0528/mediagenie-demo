#!/bin/bash
# Simplified startup script for Azure App Service
# This runs from the extracted directory by Oryx

echo "🚀 Starting MediaGenie Application..."

# Get the actual app directory (Oryx sets this)
APP_DIR="${APP_PATH:-/tmp/8de177c89523a44}"
echo "App directory: $APP_DIR"

cd "$APP_DIR" || cd /home/site/wwwroot

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found, trying /home/site/wwwroot..."
    cd /home/site/wwwroot
fi

echo "Current directory: $(pwd)"
ls -la

# Start backend service in background
echo "🎯 Starting backend API..."
cd backend/media-service 2>/dev/null || cd /home/site/wwwroot/backend/media-service
if [ -f "main.py" ]; then
    nohup python -m uvicorn main:app --host 0.0.0.0 --port 8001 &
    echo "✅ Backend started on port 8001"
    sleep 2
else
    echo "⚠️ Backend main.py not found"
fi

# Start marketplace in background
echo "🎯 Starting marketplace portal..."
cd "$APP_DIR/marketplace-portal" 2>/dev/null || cd /home/site/wwwroot/marketplace-portal
if [ -f "app.py" ]; then
    nohup python app.py &
    echo "✅ Marketplace started on port 5000"
    sleep 2
else
    echo "⚠️ Marketplace app.py not found"
fi

# Start frontend server (foreground to keep container alive)
echo "🎯 Starting frontend server..."
cd "$APP_DIR/frontend" 2>/dev/null || cd /home/site/wwwroot/frontend

if [ -f "server.js" ]; then
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing Node.js dependencies..."
        npm install --production
    fi
    
    echo "✅ Starting Express server on PORT=${PORT:-8080}"
    exec node server.js
else
    echo "❌ Frontend server.js not found!"
    echo "Available files:"
    ls -la
    
    # Fallback: start a simple Python server
    echo "⚠️ Falling back to simple HTTP server..."
    cd "$APP_DIR" 2>/dev/null || cd /home/site/wwwroot
    exec python -m http.server "${PORT:-8080}"
fi
