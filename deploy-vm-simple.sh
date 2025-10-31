#!/bin/bash
set -e

echo "=========================================="
echo "MediaGenie Simple Deployment"
echo "Using pre-built frontend (no build step)"
echo "=========================================="

PROJECT_DIR="$HOME/MediaGenie1001"

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory not found at $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo ""
echo "[1/5] Creating .env file..."
cat > .env << 'EOF'
ENVIRONMENT=production
DEBUG=false
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000
EOF
echo "[OK] .env file created"

echo ""
echo "[2/5] Stopping existing containers..."
docker-compose down 2>/dev/null || true
echo "[OK] Containers stopped"

echo ""
echo "[3/5] Creating simplified docker-compose.yml..."
cat > docker-compose-simple.yml << 'EOF'
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
EOF
echo "[OK] docker-compose-simple.yml created"

echo ""
echo "[4/5] Building backend image..."
echo "This will take 2-3 minutes..."
docker-compose -f docker-compose-simple.yml build backend
echo "[OK] Backend built"

echo ""
echo "[5/5] Starting containers..."
docker-compose -f docker-compose-simple.yml up -d
echo "[OK] Containers started"

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
echo "  docker-compose -f docker-compose-simple.yml ps"
echo ""
echo "View logs:"
echo "  docker-compose -f docker-compose-simple.yml logs -f"
echo ""
echo "Remember to open ports 8000 and 8080 in Azure Portal!"
echo "=========================================="

