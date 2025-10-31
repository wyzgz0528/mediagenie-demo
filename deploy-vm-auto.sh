#!/bin/bash
# Automated deployment script for MediaGenie on Azure VM
# Run this script ON THE VM after transferring project files

set -e  # Exit on error

echo "========================================"
echo "   MediaGenie VM Deployment Script"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
PROJECT_DIR="$HOME/MediaGenie1001"
BACKEND_DIR="$PROJECT_DIR/backend/media-service"
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo -e "${YELLOW}[1/10] Checking system...${NC}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}[ERROR] Project directory not found: $PROJECT_DIR${NC}"
    echo "Please transfer project files first"
    exit 1
fi
echo -e "${GREEN}[OK] Project directory found${NC}"

echo -e "\n${YELLOW}[2/10] Updating system packages...${NC}"
sudo apt-get update -qq
echo -e "${GREEN}[OK] System updated${NC}"

echo -e "\n${YELLOW}[3/10] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo -e "${GREEN}[OK] Docker installed${NC}"
else
    echo -e "${GREEN}[OK] Docker already installed${NC}"
fi

echo -e "\n${YELLOW}[4/10] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt-get install -y docker-compose
    echo -e "${GREEN}[OK] Docker Compose installed${NC}"
else
    echo -e "${GREEN}[OK] Docker Compose already installed${NC}"
fi

echo -e "\n${YELLOW}[5/10] Installing additional tools...${NC}"
sudo apt-get install -y nginx certbot python3-certbot-nginx ufw
echo -e "${GREEN}[OK] Tools installed${NC}"

echo -e "\n${YELLOW}[6/10] Configuring firewall...${NC}"
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8000/tcp  # Backend
sudo ufw allow 8080/tcp  # Frontend
echo -e "${GREEN}[OK] Firewall configured${NC}"

echo -e "\n${YELLOW}[7/10] Creating .env file...${NC}"
if [ ! -f "$PROJECT_DIR/.env" ]; then
    cat > "$PROJECT_DIR/.env" << 'EOF'
# Database Configuration
DATABASE_URL=postgresql+asyncpg://dbadmin:YOUR_DB_PASSWORD@mediagenie-db-5428.postgres.database.azure.com:5432/mediagenie

# Backend Configuration
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=your-secret-key-here

# Frontend Configuration
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000

# Azure Services (Optional)
AZURE_SPEECH_KEY=
AZURE_SPEECH_REGION=
AZURE_STORAGE_CONNECTION_STRING=
AZURE_OPENAI_KEY=
AZURE_OPENAI_ENDPOINT=
EOF
    echo -e "${GREEN}[OK] .env file created${NC}"
    echo -e "${YELLOW}[WARNING] Please edit .env file with your actual credentials${NC}"
    echo "Run: nano $PROJECT_DIR/.env"
else
    echo -e "${GREEN}[OK] .env file already exists${NC}"
fi

echo -e "\n${YELLOW}[8/10] Stopping existing containers...${NC}"
cd "$PROJECT_DIR"
docker-compose down 2>/dev/null || true
echo -e "${GREEN}[OK] Existing containers stopped${NC}"

echo -e "\n${YELLOW}[9/10] Building Docker images...${NC}"
echo "This may take 5-10 minutes..."
docker-compose build --no-cache
echo -e "${GREEN}[OK] Docker images built${NC}"

echo -e "\n${YELLOW}[10/10] Starting containers...${NC}"
docker-compose up -d
echo -e "${GREEN}[OK] Containers started${NC}"

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Check container status
echo -e "\n${YELLOW}Container Status:${NC}"
docker-compose ps

# Check logs
echo -e "\n${YELLOW}Recent logs:${NC}"
docker-compose logs --tail=20

echo ""
echo "========================================"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo "========================================"
echo ""
echo -e "${YELLOW}Application URLs:${NC}"
echo "  Backend API:  http://13.92.133.12:8000"
echo "  Backend Docs: http://13.92.133.12:8000/docs"
echo "  Frontend:     http://13.92.133.12:8080"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  View logs:        docker-compose logs -f"
echo "  Restart:          docker-compose restart"
echo "  Stop:             docker-compose down"
echo "  Rebuild:          docker-compose up -d --build"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Edit .env file with your database credentials"
echo "  2. Restart containers: docker-compose restart"
echo "  3. Configure Azure NSG to allow ports 8000, 8080"
echo "  4. Access the application URLs above"
echo ""
echo -e "${GREEN}[SUCCESS] Deployment script completed!${NC}"
echo ""

