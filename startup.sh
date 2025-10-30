#!/bin/bash
# Azure App Service startup script for MediaGenie

echo "🚀 Starting MediaGenie Application..."

# Set working directory
cd /home/site/wwwroot

# Install Python dependencies for backend
if [ -f requirements.txt ]; then
    echo "📦 Installing backend dependencies..."
    python -m pip install --upgrade pip
    pip install -r requirements.txt
fi

# Install marketplace dependencies
if [ -d marketplace-portal ] && [ -f marketplace-portal/requirements.txt ]; then
    echo "📦 Installing marketplace dependencies..."
    cd marketplace-portal
    pip install -r requirements.txt
    cd ..
fi

# Ensure supervisord configuration exists
if [ ! -f supervisord-demo.conf ]; then
    echo "�?supervisord-demo.conf not found!"
    exit 1
fi

# Start supervisord to manage all services
echo "🎯 Starting supervisord with all services..."
exec supervisord -c supervisord-demo.conf
