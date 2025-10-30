# MediaGenie Azure Marketplace 部署指南

## 📋 概述

MediaGenie 是一个企业级多媒体内容智能管理SaaS平台，集成了Azure认知服务，提供语音转写、文本转语音、图像分析和GPT聊天等AI功能。本文档详细介绍如何将MediaGenie部署到Azure Marketplace�?
## 🏗�?架构概览

### 核心组件
- **前端应用**: React 18 + TypeScript + Ant Design
- **后端服务**: Python FastAPI微服务架�?- **数据�?*: Azure SQL Database + Redis缓存
- **存储**: Azure Blob Storage
- **AI服务**: Azure Cognitive Services (Speech, Vision, OpenAI)
- **监控**: Azure Application Insights + Log Analytics

### 服务架构
```
┌─────────────────�?   ┌─────────────────�?   ┌─────────────────�?�?  Frontend      �?   �?  API Gateway   �?   �?  Auth Service  �?�?  (React)       │◄──►│   (Nginx)       │◄──►│   (FastAPI)     �?└─────────────────�?   └─────────────────�?   └─────────────────�?                                �?                ┌───────────────┼───────────────�?                �?              �?              �?        ┌───────▼──────�?┌──────▼──────�?┌─────▼──────�?        �?Media Service�?│Billing Service�?│User Service�?        �? (FastAPI)   �?�? (FastAPI)    �?�?(FastAPI)  �?        └──────────────�?└───────────────�?└────────────�?                �?              �?              �?        ┌───────▼───────────────▼───────────────▼──────�?        �?          Azure Services Layer               �?        �? �?SQL Database  �?Blob Storage             �?        �? �?Redis Cache   �?Application Insights     �?        �? �?Speech API    �?Computer Vision          �?        �? �?OpenAI API    �?Key Vault               �?        └─────────────────────────────────────────────�?```

## 🚀 部署前准�?
### 1. Azure服务要求

#### 必需的Azure服务
- **Azure App Service** (B2或更�?
- **Azure SQL Database** (Basic或更�?
- **Azure Storage Account** (Standard_LRS)
- **Azure Cognitive Services**:
  - Speech Services
  - Computer Vision
  - OpenAI Service
- **Azure Application Insights**
- **Azure Key Vault** (推荐)

#### 推荐的Azure服务
- **Azure CDN** (提升前端性能)
- **Azure Front Door** (全球负载均衡)
- **Azure Monitor** (高级监控)
- **Azure Sentinel** (安全监控)

### 2. 环境变量配置

创建 `.env` 文件并配置以下变量：

```bash
# Azure认知服务
AZURE_SPEECH_KEY=your_speech_service_key
AZURE_SPEECH_REGION=eastus
AZURE_VISION_KEY=your_vision_service_key
AZURE_VISION_ENDPOINT=https://your-vision.cognitiveservices.azure.com/
AZURE_OPENAI_KEY=your_openai_key
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/

# 数据�?DATABASE_URL=postgresql://username:password@server:5432/database
REDIS_URL=redis://your-redis-cache.redis.cache.windows.net:6380

# 存储
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=...

# 认证
AZURE_AD_B2C_TENANT_NAME=your-tenant
AZURE_AD_B2C_CLIENT_ID=your-client-id
AZURE_AD_B2C_CLIENT_SECRET=your-client-secret

# 监控
APPINSIGHTS_INSTRUMENTATIONKEY=your-instrumentation-key
LOG_ANALYTICS_WORKSPACE_ID=your-workspace-id

# 安全
JWT_SECRET_KEY=your-jwt-secret-key
ENCRYPTION_KEY=your-encryption-key
```

## 📦 部署步骤

### 方法1: 使用ARM模板部署

1. **准备ARM模板**
   ```bash
   # 克隆项目
   git clone https://github.com/your-org/mediagenie.git
   cd mediagenie/azure-deploy
   ```

2. **配置参数**
   编辑 `parameters.json` 文件�?   ```json
   {
     "siteName": "your-mediagenie-app",
     "hostingPlanName": "your-hosting-plan",
     "sku": "B2",
     "azureSpeechKey": "your-speech-key",
     "azureVisionKey": "YOUR_AZURE_VISION_KEY_HERE",
     "azureOpenAIKey": "your-openai-key"
   }
   ```

3. **执行部署**
   ```bash
   # 登录Azure
   az login
   
   # 创建资源�?   az group create --name MediaGenieRG --location eastus
   
   # 部署ARM模板
   az deployment group create \
     --resource-group MediaGenieRG \
     --template-file mainTemplate.json \
     --parameters @parameters.json
   ```

### 方法2: 使用PowerShell脚本部署

```powershell
# 运行部署脚本
.\deploy.ps1 -ResourceGroupName "MediaGenieRG" `
             -Location "eastus" `
             -SiteName "your-mediagenie-app" `
             -AzureSpeechKey "your-speech-key" `
             -AzureVisionKey "YOUR_AZURE_VISION_KEY_HERE" `
             -AzureVisionEndpoint "your-vision-endpoint" `
             -AzureOpenAIKey "your-openai-key" `
             -AzureOpenAIEndpoint "your-openai-endpoint"
```

### 方法3: 使用Docker容器部署

1. **构建Docker镜像**
   ```bash
   # 构建生产镜像
   docker build -t mediagenie:latest .
   
   # 推送到Azure Container Registry
   az acr login --name yourregistry
   docker tag mediagenie:latest yourregistry.azurecr.io/mediagenie:latest
   docker push yourregistry.azurecr.io/mediagenie:latest
   ```

2. **部署到Azure Container Instances**
   ```bash
   az container create \
     --resource-group MediaGenieRG \
     --name mediagenie-app \
     --image yourregistry.azurecr.io/mediagenie:latest \
     --cpu 2 \
     --memory 4 \
     --ports 80 443 \
     --environment-variables \
       AZURE_SPEECH_KEY=your-key \
       AZURE_VISION_KEY=your-key
   ```

## 🔧 部署后配�?
### 1. 数据库初始化

```sql
-- 创建用户�?CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    subscription_plan VARCHAR(50) DEFAULT 'basic',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建订阅�?CREATE TABLE subscriptions (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(id),
    plan_id VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP
);

-- 创建使用记录�?CREATE TABLE usage_records (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(id),
    service_type VARCHAR(50) NOT NULL,
    usage_amount INTEGER NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. 安全配置

```bash
# 配置SSL证书
az webapp config ssl upload \
  --resource-group MediaGenieRG \
  --name your-app-name \
  --certificate-file certificate.pfx \
  --certificate-password your-password

# 配置自定义域�?az webapp config hostname add \
  --resource-group MediaGenieRG \
  --webapp-name your-app-name \
  --hostname your-domain.com
```

### 3. 监控配置

```bash
# 配置Application Insights
az monitor app-insights component create \
  --app mediagenie-insights \
  --location eastus \
  --resource-group MediaGenieRG \
  --application-type web

# 配置日志分析工作�?az monitor log-analytics workspace create \
  --resource-group MediaGenieRG \
  --workspace-name mediagenie-logs \
  --location eastus
```

## 📊 监控和维�?
### 1. 健康检查端�?
- **应用健康**: `https://your-app.azurewebsites.net/health`
- **数据库健�?*: `https://your-app.azurewebsites.net/health/database`
- **Azure服务健康**: `https://your-app.azurewebsites.net/health/azure`

### 2. 关键指标监控

- **响应时间**: < 2�?- **错误�?*: < 1%
- **可用�?*: > 99.9%
- **CPU使用�?*: < 80%
- **内存使用�?*: < 80%

### 3. 日志管理

```bash
# 查看应用日志
az webapp log tail --resource-group MediaGenieRG --name your-app-name

# 下载日志文件
az webapp log download --resource-group MediaGenieRG --name your-app-name
```

## 🔒 安全最佳实�?
### 1. 网络安全
- 启用Web应用防火�?WAF)
- 配置DDoS防护
- 使用私有端点连接Azure服务

### 2. 数据保护
- 启用透明数据加密(TDE)
- 配置备份和恢复策�?- 实施数据分类和标�?
### 3. 身份和访问管�?- 集成Azure AD B2C
- 启用多因素认�?MFA)
- 实施基于角色的访问控�?RBAC)

## 💰 成本优化

### 1. 资源优化
- 使用Azure Reserved Instances
- 配置自动缩放
- 优化存储层级

### 2. 监控成本
- 设置预算警报
- 使用Azure Cost Management
- 定期审查资源使用情况

## 🚨 故障排除

### 常见问题

1. **应用启动失败**
   - 检查环境变量配�?   - 验证Azure服务连接
   - 查看应用日志

2. **AI服务调用失败**
   - 验证API密钥和端�?   - 检查服务配额限�?   - 确认服务区域设置

3. **数据库连接问�?*
   - 检查连接字符串
   - 验证防火墙规�?   - 确认数据库状�?
### 支持联系方式

- **技术支�?*: support@mediagenie.com
- **文档**: https://docs.mediagenie.com
- **GitHub**: https://github.com/your-org/mediagenie

## 📝 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持语音转写、文本转语音、图像分析、GPT聊天
- 集成Azure Marketplace计费
- 完整的用户认证和授权系统
