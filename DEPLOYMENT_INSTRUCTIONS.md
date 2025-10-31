# MediaGenie VM Deployment Instructions

## 🚀 Quick Start (Recommended)

### Prerequisites
- Azure VM: 13.92.133.12
- User: azure
- Docker and Docker Compose installed

### Option 1: Fast Deployment (2-3 minutes) ⚡

Uses pre-built frontend files, only builds backend.

```bash
cd ~/MediaGenie1001
git pull origin main
chmod +x deploy-final.sh
./deploy-final.sh
# Choose option 1 when prompted
```

### Option 2: Full Deployment (15-20 minutes) 🐳

Builds everything from source.

```bash
cd ~/MediaGenie1001
git pull origin main
chmod +x deploy-final.sh
./deploy-final.sh
# Choose option 2 when prompted
```

---

## 📋 Manual Deployment Steps

### Step 1: Prepare Environment

```bash
# Navigate to project
cd ~/MediaGenie1001

# Pull latest code
git pull origin main

# Create .env file
cat > .env << 'EOF'
ENVIRONMENT=production
DEBUG=false
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000
EOF
```

### Step 2: Clean Up

```bash
# Stop existing containers
docker-compose down

# Clean up Docker resources
docker system prune -f
```

### Step 3A: Fast Deployment (Recommended)

```bash
# Use pre-built frontend
docker-compose -f docker-compose.fast.yml build backend
docker-compose -f docker-compose.fast.yml up -d
```

### Step 3B: Full Deployment

```bash
# Build everything from source
docker-compose build
docker-compose up -d
```

### Step 4: Verify Deployment

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Test backend
curl http://localhost:8000/health

# Test frontend
curl http://localhost:8080
```

---

## 🔧 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs mediagenie-backend
docker logs mediagenie-frontend

# Restart containers
docker-compose restart
```

### Port Already in Use

```bash
# Check what's using the port
sudo netstat -tlnp | grep -E '(8000|8080)'

# Stop system nginx if needed
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### Frontend Build Directory Missing

```bash
# Build frontend locally
cd ~/MediaGenie1001/frontend
npm install
npm run build
cd ..

# Then use fast deployment
docker-compose -f docker-compose.fast.yml up -d
```

---

## 🌐 Azure Portal Configuration

### Open Required Ports

1. Go to Azure Portal
2. Navigate to your VM: **mediagenie-demo**
3. Click **Networking** → **Network settings**
4. Click **Create port rule** → **Inbound port rule**
5. Add two rules:

**Rule 1: Backend**
- Source: Any
- Source port ranges: *
- Destination: Any
- Service: Custom
- Destination port ranges: **8000**
- Protocol: TCP
- Action: Allow
- Priority: 310
- Name: Allow-Backend-8000

**Rule 2: Frontend**
- Source: Any
- Source port ranges: *
- Destination: Any
- Service: Custom
- Destination port ranges: **8080**
- Protocol: TCP
- Action: Allow
- Priority: 320
- Name: Allow-Frontend-8080

---

## 📊 Service URLs

After deployment and port configuration:

- **Frontend**: http://13.92.133.12:8080
- **Backend API**: http://13.92.133.12:8000
- **API Documentation**: http://13.92.133.12:8000/docs
- **Health Check**: http://13.92.133.12:8000/health

---

## 🔄 Common Commands

```bash
# View status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build

# Clean everything
docker-compose down
docker system prune -af
```

---

## 📝 Architecture

### Fast Deployment
- **Backend**: Docker container (Python 3.11 + FastAPI + Gunicorn)
- **Frontend**: Nginx container serving pre-built static files
- **Build Time**: 2-3 minutes

### Full Deployment
- **Backend**: Docker container (Python 3.11 + FastAPI + Gunicorn)
- **Frontend**: Multi-stage Docker build (Node.js build + Nginx serve)
- **Build Time**: 15-20 minutes

---

## ⚠️ Important Notes

1. **Pre-built Frontend**: The `frontend/build/` directory contains pre-built React files. This is NOT in git due to `.gitignore`, but exists locally.

2. **Memory Usage**: The VM has 2GB RAM. Full deployment (building frontend) may be slow or fail due to memory constraints. Use fast deployment if possible.

3. **Firewall**: Both UFW (on VM) and Azure NSG (in portal) must allow ports 8000 and 8080.

4. **No Database**: Current version uses in-memory storage. Data is lost on restart.

---

## 🆘 Support

If deployment fails:

1. Check container logs: `docker-compose logs`
2. Check system resources: `free -h` and `df -h`
3. Verify ports: `sudo netstat -tlnp | grep -E '(8000|8080)'`
4. Test locally: `curl http://localhost:8000/health`

