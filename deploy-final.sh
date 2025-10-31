#!/bin/bash
set -e

echo "=========================================="
echo "MediaGenie Complete Deployment"
echo "=========================================="

PROJECT_DIR="$HOME/MediaGenie1001"

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory not found at $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo ""
echo "Choose deployment method:"
echo "1) Fast - Use pre-built frontend (2-3 minutes)"
echo "2) Full - Build everything from source (15-20 minutes)"
read -p "Enter choice [1 or 2]: " choice

echo ""
echo "[1/6] Creating .env file..."
cat > .env << 'EOF'
ENVIRONMENT=production
DEBUG=false
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000
EOF
echo "[OK] .env file created"

echo ""
echo "[2/6] Stopping existing containers..."
docker-compose down 2>/dev/null || true
docker system prune -f
echo "[OK] Cleanup complete"

if [ "$choice" = "1" ]; then
    echo ""
    echo "[3/6] Using FAST deployment (pre-built frontend)..."
    
    # Check if frontend/build exists
    if [ ! -d "frontend/build" ] || [ -z "$(ls -A frontend/build 2>/dev/null)" ]; then
        echo "[ERROR] frontend/build directory is missing or empty!"
        echo "Building frontend locally..."
        cd frontend
        npm install
        npm run build
        cd ..
    fi
    
    echo "[OK] Frontend build directory ready"
    
    echo ""
    echo "[4/6] Creating docker-compose-fast.yml..."
    cat > docker-compose-fast.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  backend:
    build:
      context: ./backend/media-service
      dockerfile: Dockerfile
    container_name: mediagenie-backend
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
      - DEBUG=false
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    image: nginx:alpine
    container_name: mediagenie-frontend
    ports:
      - "8080:8080"
    volumes:
      - ./frontend/build:/usr/share/nginx/html:ro
      - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    restart: unless-stopped
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
COMPOSE_EOF
    
    echo "[OK] docker-compose-fast.yml created"
    
    echo ""
    echo "[5/6] Building backend image..."
    docker-compose -f docker-compose-fast.yml build backend
    
    echo ""
    echo "[6/6] Starting containers..."
    docker-compose -f docker-compose-fast.yml up -d
    
    COMPOSE_FILE="docker-compose-fast.yml"
    
else
    echo ""
    echo "[3/6] Using FULL deployment (build from source)..."
    echo "This will take 15-20 minutes..."
    
    echo ""
    echo "[4/6] Building images..."
    docker-compose build
    
    echo ""
    echo "[5/6] Starting containers..."
    docker-compose up -d
    
    COMPOSE_FILE="docker-compose.yml"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Services:"
echo "  - Backend API:  http://13.92.133.12:8000"
echo "  - API Docs:     http://13.92.133.12:8000/docs"
echo "  - Frontend:     http://13.92.133.12:8080"
echo ""
echo "Check status:"
echo "  docker-compose -f $COMPOSE_FILE ps"
echo ""
echo "View logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "Test locally:"
echo "  curl http://localhost:8000/health"
echo "  curl http://localhost:8080"
echo ""
echo "IMPORTANT: Open ports 8000 and 8080 in Azure Portal!"
echo "=========================================="

