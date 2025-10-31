# MediaGenie - 多媒体内容智能管理平台

[![Deploy to Azure](https://img.shields.io/badge/Deploy%20to-Azure-0078D4?logo=microsoft-azure)](https://portal.azure.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

MediaGenie 是一个基于 Azure 认知服务的多媒体内容智能管理平台，提供语音转文字、文字转语音、图像分析等功能。

## 🚀 快速开始

### 方式 1: 使用 Docker Compose (推荐)

```bash
# 1. 克隆仓库
git clone https://github.com/wyzgz0528/mediagenie-demo.git
cd mediagenie-demo

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入你的 Azure 配置

# 3. 启动服务
docker-compose up -d

# 4. 访问应用
# 前端: http://localhost:8080
# 后端: http://localhost:8000
# API 文档: http://localhost:8000/docs
```

### 方式 2: 本地开发

**后端:**
```bash
cd backend/media-service
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

**前端:**
```bash
cd frontend
npm install
npm start
```

## ☁️ 部署到 Azure

### 一键部署脚本

```powershell
# 运行自动化部署脚本
.\quick-deploy.ps1
```

这个脚本会自动:
1. ✅ 创建 Azure Container Registry
2. ✅ 配置 Web App 使用容器
3. ✅ 获取发布配置文件
4. ✅ 显示 GitHub Secrets 配置信息

### 手动部署

详细步骤请参考:
- 📖 [完整部署指南](DEPLOYMENT_GUIDE.md)
- 📝 [下一步操作](NEXT_STEPS.md)
- ⚡ [快速命令参考](QUICK_COMMANDS.md)

## 🏗️ 项目结构

```
MediaGenie1001/
 backend/
    media-service/          # FastAPI 后端服务
        main.py             # 主应用入口
        config.py           # 配置管理
        database.py         # 数据库连接
        models.py           # 数据模型
        requirements.txt    # Python 依赖
        Dockerfile          # 后端 Docker 配置
 frontend/                   # React 前端应用
    src/                    # 源代码
    public/                 # 静态资源
    package.json            # Node.js 依赖
    Dockerfile              # 前端 Docker 配置
 .github/
    workflows/
        azure-deploy.yml    # GitHub Actions CI/CD
 docker-compose.yml          # Docker Compose 配置
 quick-deploy.ps1            # 一键部署脚本
 README.md                   # 项目文档
```

## 🛠️ 技术栈

### 后端
- **框架**: FastAPI 0.104+
- **服务器**: Gunicorn + Uvicorn
- **数据库**: PostgreSQL (Azure Database)
- **ORM**: SQLAlchemy 2.0+
- **Azure 服务**:
  - Azure Cognitive Services (Speech)
  - Azure Storage Blob
  - Azure OpenAI

### 前端
- **框架**: React 18.2
- **语言**: TypeScript
- **UI 库**: Ant Design
- **状态管理**: Redux Toolkit
- **路由**: React Router
- **认证**: Azure MSAL

### DevOps
- **容器化**: Docker
- **编排**: Docker Compose
- **CI/CD**: GitHub Actions
- **镜像仓库**: Azure Container Registry
- **托管**: Azure Web App for Containers

## 📚 文档

| 文档 | 描述 |
|------|------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | 完整的 Azure 部署指南 |
| [NEXT_STEPS.md](NEXT_STEPS.md) | 部署后的下一步操作 |
| [QUICK_COMMANDS.md](QUICK_COMMANDS.md) | 常用命令快速参考 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | 项目重构总结 |

##  配置说明

### 环境变量

**后端 (backend/media-service)**
```env
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
ENVIRONMENT=production
DEBUG=false
AZURE_SPEECH_KEY=your_key
AZURE_SPEECH_REGION=your_region
AZURE_STORAGE_CONNECTION_STRING=your_connection_string
OPENAI_API_KEY=your_key
```

**前端 (frontend)**
```env
REACT_APP_MEDIA_SERVICE_URL=https://your-backend-url
REACT_APP_ENV=production
```

##  访问 URL

部署完成后:
- **前端应用**: https://mediagenie-frontend.azurewebsites.net
- **后端 API**: https://mediagenie-backend.azurewebsites.net
- **API 文档**: https://mediagenie-backend.azurewebsites.net/docs

##  贡献

欢迎提交 Issue 和 Pull Request！

##  许可证

MIT License

##  作者

MediaGenie Team

---

**快速开始**: 运行 `.\quick-deploy.ps1` 开始部署到 Azure！ 
