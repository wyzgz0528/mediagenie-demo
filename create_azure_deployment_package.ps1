# ============================================================================
# MediaGenie Azure Web App 部署包创建脚本
# ============================================================================

param(
    [string]$OutputDir = "azure-webapp-deploy",
    [switch]$BuildFrontend = $false
)

$ErrorActionPreference = "Stop"
Write-Host "🚀 开始创建 Azure Web App 部署包..." -ForegroundColor Green

# 清理并创建输出目录
if (Test-Path $OutputDir) {
    Write-Host "🧹 清理旧的部署目录..." -ForegroundColor Yellow
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# ============================================================================
# 1. 复制后端代码
# ============================================================================
Write-Host "`n📦 步骤 1: 复制后端代码..." -ForegroundColor Cyan
$backendSource = "backend/media-service"
$backendDest = "$OutputDir/backend"

if (Test-Path $backendSource) {
    Copy-Item -Path $backendSource -Destination $backendDest -Recurse -Force
    Write-Host "✅ 后端代码复制完成" -ForegroundColor Green
} else {
    Write-Host "❌ 找不到后端目录: $backendSource" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 2. 处理前端
# ============================================================================
Write-Host "`n📦 步骤 2: 处理前端..." -ForegroundColor Cyan

if ($BuildFrontend) {
    Write-Host "🔨 构建前端..." -ForegroundColor Yellow
    Push-Location frontend
    try {
        npm install
        npm run build
        Write-Host "✅ 前端构建完成" -ForegroundColor Green
    } catch {
        Write-Host "❌ 前端构建失败: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# 复制前端构建文件和server.js
$frontendDest = "$OutputDir/frontend"
New-Item -ItemType Directory -Path $frontendDest -Force | Out-Null

if (Test-Path "frontend/build") {
    Copy-Item -Path "frontend/build" -Destination $frontendDest -Recurse -Force
    Write-Host "✅ 前端构建文件复制完成" -ForegroundColor Green
} else {
    Write-Host "⚠️ 前端build目录不存在,跳过..." -ForegroundColor Yellow
}

if (Test-Path "frontend/server.js") {
    Copy-Item -Path "frontend/server.js" -Destination $frontendDest -Force
    Write-Host "✅ 前端server.js复制完成" -ForegroundColor Green
}

if (Test-Path "frontend/package.json") {
    Copy-Item -Path "frontend/package.json" -Destination $frontendDest -Force
    Write-Host "✅ 前端package.json复制完成" -ForegroundColor Green
}

# ============================================================================
# 3. 复制Marketplace Portal
# ============================================================================
Write-Host "`n📦 步骤 3: 复制Marketplace Portal..." -ForegroundColor Cyan
$marketplaceDest = "$OutputDir/marketplace-portal"

if (Test-Path "marketplace-portal") {
    Copy-Item -Path "marketplace-portal" -Destination $marketplaceDest -Recurse -Force
    Write-Host "✅ Marketplace Portal复制完成" -ForegroundColor Green
} else {
    Write-Host "⚠️ Marketplace Portal目录不存在,跳过..." -ForegroundColor Yellow
}

# ============================================================================
# 4. 创建根目录requirements.txt (合并所有Python依赖)
# ============================================================================
Write-Host "`n📦 步骤 4: 创建合并的requirements.txt..." -ForegroundColor Cyan

$requirements = @"
# ============================================================================
# MediaGenie Azure Web App Python Dependencies
# ============================================================================

# Web Framework
fastapi>=0.104.0
uvicorn[standard]>=0.23.0
python-multipart>=0.0.6

# Azure SDK
azure-cognitiveservices-speech>=1.31.0
azure-ai-vision-imageanalysis>=1.0.0b1
openai>=1.3.0

# Database
sqlalchemy>=2.0.0
asyncpg>=0.28.0
psycopg2-binary>=2.9.7
alembic>=1.12.0

# Authentication & Security
PyJWT>=2.8.0
cryptography>=41.0.5
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4

# HTTP & API
httpx>=0.25.0
requests>=2.31.0
aiohttp>=3.9.0

# Data Processing
python-dateutil>=2.8.2
pydantic>=2.4.2
pydantic-settings>=2.0.3

# Utilities
python-dotenv>=1.0.0
tenacity>=8.2.3

# Logging & Monitoring
python-json-logger>=2.0.7

# Flask (for marketplace portal)
Flask>=3.0.0
Flask-CORS>=4.0.0
Werkzeug>=3.0.0

# Redis (optional)
redis>=5.0.0

# File handling
Pillow>=10.0.0
"@

Set-Content -Path "$OutputDir/requirements.txt" -Value $requirements -Encoding UTF8
Write-Host "✅ requirements.txt创建完成" -ForegroundColor Green

# ============================================================================
# 5. 创建Azure启动脚本
# ============================================================================
Write-Host "`n📦 步骤 5: 创建启动脚本..." -ForegroundColor Cyan

$startupScript = @'
#!/bin/bash
# ============================================================================
# Azure Web App Startup Script for MediaGenie
# ============================================================================

echo "🚀 Starting MediaGenie Application..."
echo "📍 Working directory: $(pwd)"
echo "🐍 Python version: $(python --version)"
echo "📦 Node version: $(node --version)"

# 设置工作目录
cd /home/site/wwwroot

# 创建日志目录
mkdir -p logs
echo "✅ Log directory created"

# ============================================================================
# 安装Python依赖
# ============================================================================
echo "📦 Installing Python dependencies..."
if [ -f requirements.txt ]; then
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    echo "✅ Python dependencies installed"
else
    echo "⚠️ requirements.txt not found"
fi

# ============================================================================
# 安装前端依赖
# ============================================================================
if [ -d frontend ] && [ -f frontend/package.json ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend
    npm install --production
    cd ..
    echo "✅ Frontend dependencies installed"
fi

# ============================================================================
# 启动应用
# ============================================================================
echo "🎯 Starting MediaGenie services..."

# 使用supervisord管理多进程
if [ -f supervisord.conf ]; then
    echo "🔄 Starting with supervisord..."
    exec supervisord -c supervisord.conf
else
    # 备用方案:直接启动后端
    echo "🔄 Starting backend service directly..."
    cd backend
    exec python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
fi
'@

Set-Content -Path "$OutputDir/startup.sh" -Value $startupScript -Encoding UTF8
Write-Host "✅ startup.sh创建完成" -ForegroundColor Green

# ============================================================================
# 6. 创建Supervisord配置
# ============================================================================
Write-Host "`n📦 步骤 6: 创建Supervisord配置..." -ForegroundColor Cyan

$supervisordConf = @'
[supervisord]
nodaemon=true
logfile=/home/site/wwwroot/logs/supervisord.log
pidfile=/home/site/wwwroot/logs/supervisord.pid
user=root

[program:backend]
command=python -m uvicorn main:app --host 0.0.0.0 --port 8001
directory=/home/site/wwwroot/backend
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/site/wwwroot/logs/backend.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=3
environment=PORT="8001"

[program:frontend]
command=node server.js
directory=/home/site/wwwroot/frontend
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/site/wwwroot/logs/frontend.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=3
environment=PORT="%(ENV_PORT)s"

[program:marketplace]
command=python app.py
directory=/home/site/wwwroot/marketplace-portal
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/site/wwwroot/logs/marketplace.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=3
environment=FLASK_APP="app.py",FLASK_ENV="production"
'@

Set-Content -Path "$OutputDir/supervisord.conf" -Value $supervisordConf -Encoding UTF8
Write-Host "✅ supervisord.conf创建完成" -ForegroundColor Green

# ============================================================================
# 7. 创建.deployment配置
# ============================================================================
Write-Host "`n📦 步骤 7: 创建.deployment配置..." -ForegroundColor Cyan

$deploymentConfig = @"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@

Set-Content -Path "$OutputDir/.deployment" -Value $deploymentConfig -Encoding UTF8
Write-Host "✅ .deployment创建完成" -ForegroundColor Green

# ============================================================================
# 8. 创建环境变量示例文件
# ============================================================================
Write-Host "`n📦 步骤 8: 创建环境变量示例..." -ForegroundColor Cyan

if (Test-Path "azure_env_vars.txt") {
    Copy-Item -Path "azure_env_vars.txt" -Destination "$OutputDir/azure_env_vars.txt" -Force
    Write-Host "✅ 环境变量文件复制完成" -ForegroundColor Green
}

# ============================================================================
# 9. 创建部署说明文档
# ============================================================================
Write-Host "`n📦 步骤 9: 创建部署说明..." -ForegroundColor Cyan

$deploymentGuide = @'
# MediaGenie Azure Web App 部署指南

## 📋 前提条件

1. Azure账号和订阅
2. Azure CLI已安装并登录
3. 已创建Azure Web App (Python 3.11 Linux)
4. 已配置Azure认知服务 (Speech, Vision, OpenAI)

## 🚀 部署步骤

### 方法1: ZIP部署 (推荐)

#### 1. 创建部署ZIP包
```powershell
# 进入部署目录
cd azure-webapp-deploy

# 创建ZIP包
Compress-Archive -Path * -DestinationPath ../mediagenie-webapp.zip -Force
```

#### 2. 使用Azure CLI部署
```bash
# 登录Azure
az login

# 设置变量
RESOURCE_GROUP="your-resource-group"
WEBAPP_NAME="your-webapp-name"

# 部署ZIP包
az webapp deploy --resource-group $RESOURCE_GROUP \
                 --name $WEBAPP_NAME \
                 --src-path mediagenie-webapp.zip \
                 --type zip
```

#### 3. 配置环境变量
```bash
# 使用JSON批量导入环境变量
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEBAPP_NAME \
  --settings @env-settings.json
```

或通过Azure Portal:
1. 进入Web App → 配置 → 应用程序设置
2. 添加以下环境变量:
   - `AZURE_SPEECH_KEY`: Speech服务密钥
   - `AZURE_SPEECH_REGION`: Speech服务区域
   - `AZURE_VISION_KEY`: Vision服务密钥
   - `AZURE_VISION_ENDPOINT`: Vision服务端点
   - `AZURE_OPENAI_KEY`: OpenAI服务密钥
   - `AZURE_OPENAI_ENDPOINT`: OpenAI服务端点
   - `AZURE_OPENAI_DEPLOYMENT`: 部署名称
   - `DATABASE_URL`: PostgreSQL连接字符串
   - `PORT`: 端口(通常由Azure自动设置)

#### 4. 配置启动命令
在Azure Portal中设置启动命令:
```bash
bash startup.sh
```

### 方法2: Git部署

#### 1. 初始化Git仓库
```bash
cd azure-webapp-deploy
git init
git add .
git commit -m "Initial deployment"
```

#### 2. 配置Azure Git远程仓库
```bash
# 获取Git部署URL
az webapp deployment source config-local-git \
  --resource-group $RESOURCE_GROUP \
  --name $WEBAPP_NAME

# 添加远程仓库
git remote add azure <deployment-git-url>

# 推送代码
git push azure master
```

### 方法3: GitHub Actions (CI/CD)

参考 `.github/workflows/azure-deploy.yml` 配置文件

## 🔍 验证部署

### 1. 检查应用状态
```bash
# 查看应用日志
az webapp log tail --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME

# 检查应用健康
curl https://<your-webapp>.azurewebsites.net/health
```

### 2. 测试端点
- 后端API: `https://<your-webapp>.azurewebsites.net/`
- 健康检查: `https://<your-webapp>.azurewebsites.net/health`
- 前端: `https://<your-webapp>.azurewebsites.net`

## 📝 环境变量配置清单

创建 `env-settings.json`:
```json
[
  {
    "name": "AZURE_SPEECH_KEY",
    "value": "your-speech-key",
    "slotSetting": false
  },
  {
    "name": "AZURE_SPEECH_REGION",
    "value": "eastus",
    "slotSetting": false
  },
  {
    "name": "AZURE_VISION_KEY",
    "value": "your-vision-key",
    "slotSetting": false
  },
  {
    "name": "AZURE_VISION_ENDPOINT",
    "value": "https://your-vision.cognitiveservices.azure.com/",
    "slotSetting": false
  },
  {
    "name": "AZURE_OPENAI_KEY",
    "value": "your-openai-key",
    "slotSetting": false
  },
  {
    "name": "AZURE_OPENAI_ENDPOINT",
    "value": "https://your-openai.openai.azure.com/",
    "slotSetting": false
  },
  {
    "name": "AZURE_OPENAI_DEPLOYMENT",
    "value": "gpt-4.1",
    "slotSetting": false
  },
  {
    "name": "AZURE_OPENAI_API_VERSION",
    "value": "2025-01-01-preview",
    "slotSetting": false
  },
  {
    "name": "DATABASE_URL",
    "value": "postgresql+asyncpg://user:pass@host:5432/dbname",
    "slotSetting": false
  },
  {
    "name": "DEBUG",
    "value": "false",
    "slotSetting": false
  },
  {
    "name": "SCM_DO_BUILD_DURING_DEPLOYMENT",
    "value": "true",
    "slotSetting": false
  }
]
```

## 🛠️ 故障排除

### 1. 应用无法启动
- 检查日志: `az webapp log tail`
- 验证Python版本: 确保使用Python 3.11
- 检查依赖安装: 确保requirements.txt正确

### 2. 环境变量未生效
- 在Azure Portal中检查配置
- 重启应用: `az webapp restart`

### 3. 前端无法访问后端
- 检查CORS配置
- 验证API端点URL
- 检查网络规则

## 📞 技术支持

如有问题,请联系:
- Email: support@smartwebco.com
- 文档: https://smartwebco.com/docs
'@

Set-Content -Path "$OutputDir/DEPLOYMENT_GUIDE.md" -Value $deploymentGuide -Encoding UTF8
Write-Host "✅ 部署指南创建完成" -ForegroundColor Green

# ============================================================================
# 10. 创建快速部署脚本
# ============================================================================
Write-Host "`n📦 步骤 10: 创建快速部署脚本..." -ForegroundColor Cyan

$quickDeployScript = @'
#!/bin/bash
# ============================================================================
# MediaGenie 快速部署脚本
# ============================================================================

# 检查参数
if [ $# -lt 2 ]; then
    echo "用法: $0 <resource-group> <webapp-name>"
    echo "示例: $0 MediaGenie-RG mediagenie-app"
    exit 1
fi

RESOURCE_GROUP=$1
WEBAPP_NAME=$2

echo "🚀 开始部署 MediaGenie 到 Azure Web App"
echo "📦 资源组: $RESOURCE_GROUP"
echo "🌐 应用名称: $WEBAPP_NAME"

# 检查Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ 未找到Azure CLI,请先安装"
    exit 1
fi

# 登录检查
echo "🔐 检查Azure登录状态..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "🔐 请先登录Azure..."
    az login
fi

# 创建ZIP包
echo "📦 创建部署包..."
cd "$(dirname "$0")"
rm -f ../mediagenie-webapp.zip
zip -r ../mediagenie-webapp.zip * -x "*.git*" -x "node_modules/*" -x "__pycache__/*"

if [ ! -f ../mediagenie-webapp.zip ]; then
    echo "❌ ZIP包创建失败"
    exit 1
fi

echo "✅ 部署包创建成功"

# 部署到Azure
echo "🚀 部署到 Azure Web App..."
az webapp deploy \
    --resource-group $RESOURCE_GROUP \
    --name $WEBAPP_NAME \
    --src-path ../mediagenie-webapp.zip \
    --type zip \
    --async false

if [ $? -eq 0 ]; then
    echo "✅ 部署成功!"
    echo "🌐 应用URL: https://$WEBAPP_NAME.azurewebsites.net"
    echo ""
    echo "📝 下一步:"
    echo "1. 配置环境变量: az webapp config appsettings set ..."
    echo "2. 设置启动命令: bash startup.sh"
    echo "3. 查看日志: az webapp log tail --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP"
else
    echo "❌ 部署失败,请检查日志"
    exit 1
fi
'@

Set-Content -Path "$OutputDir/deploy-to-azure.sh" -Value $quickDeployScript -Encoding UTF8
Write-Host "✅ 快速部署脚本创建完成" -ForegroundColor Green

# ============================================================================
# 完成
# ============================================================================
Write-Host "`n✅ 部署包创建完成!" -ForegroundColor Green
Write-Host "📁 输出目录: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 进入目录: cd $OutputDir" -ForegroundColor White
Write-Host "2. 查看部署指南: cat DEPLOYMENT_GUIDE.md" -ForegroundColor White
Write-Host "3. 创建ZIP包并部署到Azure Web App" -ForegroundColor White
Write-Host ""
Write-Host "🚀 快速部署命令:" -ForegroundColor Yellow
Write-Host "   cd $OutputDir" -ForegroundColor White
Write-Host "   bash deploy-to-azure.sh <资源组名称> <Web App名称>" -ForegroundColor White
