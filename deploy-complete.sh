#!/bin/bash
set -e

echo "=========================================="
echo "MediaGenie Complete Deployment"
echo "With Environment Variables"
echo "=========================================="

# Check if .env file exists
if [ ! -f "backend/media-service/.env" ]; then
    echo ""
    echo "ERROR: backend/media-service/.env file not found!"
    echo ""
    echo "Please transfer your .env file first:"
    echo "  From your local machine, run:"
    echo "  scp backend/media-service/.env azure@13.92.133.12:~/backend.env"
    echo ""
    echo "  Then on the VM, run:"
    echo "  mv ~/backend.env ~/MediaGenie1001/backend/media-service/.env"
    echo ""
    exit 1
fi

echo ""
echo "✓ Found .env file with API keys"
echo ""

# Ask deployment method
echo "Choose deployment method:"
echo "1) Direct (No Docker) - Fast, uses .env directly (RECOMMENDED)"
echo "2) Docker - Containerized deployment"
read -p "Enter choice [1 or 2]: " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo "=========================================="
    echo "Direct Deployment (No Docker)"
    echo "=========================================="
    
    # Stop Docker containers if running
    echo ""
    echo "[1/7] Stopping Docker containers..."
    docker-compose down 2>/dev/null || true
    
    # Stop system nginx
    echo ""
    echo "[2/7] Stopping system nginx..."
    sudo systemctl stop nginx 2>/dev/null || true
    sudo systemctl disable nginx 2>/dev/null || true
    
    # Install dependencies
    echo ""
    echo "[3/7] Installing system dependencies..."
    sudo apt update
    sudo apt install -y python3.11 python3.11-venv python3-pip nodejs npm
    
    # Setup backend
    echo ""
    echo "[4/7] Setting up backend..."
    cd backend/media-service
    
    # Create virtual environment if not exists
    if [ ! -d "venv" ]; then
        python3.11 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    
    # Kill existing backend process
    pkill -f "uvicorn main:app" || true
    
    # Start backend
    echo "Starting backend on port 8000..."
    nohup uvicorn main:app --host 0.0.0.0 --port 8000 > ~/backend.log 2>&1 &
    BACKEND_PID=$!
    echo "Backend PID: $BACKEND_PID"
    
    cd ../..
    
    # Setup frontend
    echo ""
    echo "[5/7] Setting up frontend..."
    cd frontend
    
    # Check if build exists
    if [ ! -d "build" ] || [ -z "$(ls -A build 2>/dev/null)" ]; then
        echo "Building frontend (this may take 5-10 minutes)..."
        npm install
        npm run build
    else
        echo "Using existing build directory"
    fi
    
    # Install serve if not exists
    if ! command -v serve &> /dev/null; then
        sudo npm install -g serve
    fi
    
    # Kill existing frontend process
    pkill -f "serve -s build" || true
    
    # Start frontend
    echo "Starting frontend on port 8080..."
    nohup serve -s build -l 8080 > ~/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "Frontend PID: $FRONTEND_PID"
    
    cd ..
    
    # Configure firewall
    echo ""
    echo "[6/7] Configuring firewall..."
    sudo ufw allow 8000 2>/dev/null || true
    sudo ufw allow 8080 2>/dev/null || true
    
    # Wait and verify
    echo ""
    echo "[7/7] Verifying deployment..."
    sleep 5
    
    echo ""
    echo "Backend health check:"
    curl -s http://localhost:8000/health | python3 -m json.tool || echo "Backend not responding"
    
    echo ""
    echo "Frontend check:"
    curl -s -I http://localhost:8080 | head -n 1 || echo "Frontend not responding"
    
    echo ""
    echo "=========================================="
    echo "Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Services:"
    echo "  - Backend:  http://13.92.133.12:8000"
    echo "  - Frontend: http://13.92.133.12:8080"
    echo "  - API Docs: http://13.92.133.12:8000/docs"
    echo ""
    echo "Process IDs:"
    echo "  - Backend:  $BACKEND_PID"
    echo "  - Frontend: $FRONTEND_PID"
    echo ""
    echo "View logs:"
    echo "  tail -f ~/backend.log"
    echo "  tail -f ~/frontend.log"
    echo ""
    echo "Stop services:"
    echo "  pkill -f 'uvicorn main:app'"
    echo "  pkill -f 'serve -s build'"
    echo ""
    echo "Restart services:"
    echo "  cd ~/MediaGenie1001 && ./deploy-complete.sh"
    echo ""
    echo "=========================================="
    
else
    echo ""
    echo "=========================================="
    echo "Docker Deployment"
    echo "=========================================="
    
    # Stop existing containers
    echo ""
    echo "[1/5] Stopping existing containers..."
    docker-compose down 2>/dev/null || true
    docker system prune -f
    
    # Create docker-compose override
    echo ""
    echo "[2/5] Creating docker-compose configuration..."
    cat > docker-compose.override.yml << 'OVERRIDE_EOF'
version: '3.8'

services:
  backend:
    env_file:
      - ./backend/media-service/.env
    environment:
      - ENVIRONMENT=production
      - DEBUG=false
  
  frontend:
    image: nginx:alpine
    volumes:
      - ./frontend/build:/usr/share/nginx/html:ro
    command: sh -c "echo 'server { listen 8080; root /usr/share/nginx/html; index index.html; location / { try_files \$\$uri /index.html; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
OVERRIDE_EOF
    
    # Build frontend if needed
    echo ""
    echo "[3/5] Checking frontend build..."
    if [ ! -d "frontend/build" ] || [ -z "$(ls -A frontend/build 2>/dev/null)" ]; then
        echo "Building frontend (this may take 5-10 minutes)..."
        cd frontend
        npm install
        npm run build
        cd ..
    else
        echo "Using existing build directory"
    fi
    
    # Build and start containers
    echo ""
    echo "[4/5] Building and starting containers..."
    docker-compose build backend
    docker-compose up -d
    
    # Verify
    echo ""
    echo "[5/5] Verifying deployment..."
    sleep 5
    
    docker-compose ps
    
    echo ""
    echo "Backend health check:"
    curl -s http://localhost:8000/health | python3 -m json.tool || echo "Backend not responding"
    
    echo ""
    echo "Frontend check:"
    curl -s -I http://localhost:8080 | head -n 1 || echo "Frontend not responding"
    
    echo ""
    echo "=========================================="
    echo "Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Services:"
    echo "  - Backend:  http://13.92.133.12:8000"
    echo "  - Frontend: http://13.92.133.12:8080"
    echo "  - API Docs: http://13.92.133.12:8000/docs"
    echo ""
    echo "Manage services:"
    echo "  docker-compose ps"
    echo "  docker-compose logs -f"
    echo "  docker-compose restart"
    echo "  docker-compose down"
    echo ""
    echo "=========================================="
fi

