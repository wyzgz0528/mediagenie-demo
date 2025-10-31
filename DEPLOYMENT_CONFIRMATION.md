# MediaGenie 部署确认文档

## ✅ 项目完整性检查

### 📦 **前端 (Frontend)**

✅ **源代码完整**
- `frontend/src/` - React TypeScript 源代码
- `frontend/public/` - 静态资源
- `frontend/package.json` - 依赖配置

✅ **构建产物存在**
- `frontend/build/index.html` - 已构建的 HTML
- `frontend/build/static/` - 已构建的 JS/CSS

✅ **Docker 配置完整**
- `frontend/Dockerfile` - 多阶段构建配置
- `frontend/nginx.conf` - Nginx 服务器配置

✅ **技术栈**
- React 18.2.0
- TypeScript
- Ant Design UI
- Redux Toolkit
- Nginx (生产环境)

---

### 🔧 **后端 (Backend)**

✅ **源代码完整**
- `backend/media-service/main.py` - FastAPI 主应用
- `backend/media-service/config.py` - 配置管理
- `backend/media-service/models.py` - 数据模型

✅ **依赖配置完整**
- `backend/media-service/requirements.txt` - Python 依赖
  - FastAPI 0.104+
  - Uvicorn + Gunicorn
  - Azure SDK (Speech, Storage, OpenAI)
  - SQLAlchemy (可选，当前未使用)

✅ **Docker 配置完整**
- `backend/media-service/Dockerfile` - 生产环境配置
- 使用 Gunicorn + Uvicorn workers
- 4 个工作进程

✅ **技术栈**
- Python 3.11
- FastAPI
- Gunicorn + Uvicorn
- Azure Cognitive Services

---

### 🐳 **Docker 编排**

✅ **docker-compose.yml 完整**
- 后端服务配置 (端口 8000)
- 前端服务配置 (端口 8080)
- 健康检查配置
- 自动重启策略
- 网络配置

---

## 🚀 **部署方式**

### **方式 1: 完全自动化部署（推荐）**

```bash
# 在虚拟机上运行一条命令
cd ~ && \
git clone https://github.com/wyzgz0528/mediagenie-demo.git MediaGenie1001 && \
cd MediaGenie1001 && \
chmod +x deploy-vm-auto.sh && \
./deploy-vm-auto.sh
```

**这个命令会自动**：
1. ✅ 克隆完整项目代码（前端 + 后端）
2. ✅ 安装 Docker 和 Docker Compose
3. ✅ 配置防火墙
4. ✅ 创建 .env 配置文件
5. ✅ 构建 Docker 镜像（前端 + 后端）
6. ✅ 启动容器（前端 + 后端）

**预计时间**: 5-10 分钟

---

### **方式 2: 手动部署**

```bash
# 1. 克隆项目
git clone https://github.com/wyzgz0528/mediagenie-demo.git MediaGenie1001
cd MediaGenie1001

# 2. 创建 .env 文件
cat > .env << 'EOF'
ENVIRONMENT=production
DEBUG=false
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000
EOF

# 3. 构建并启动
docker-compose build
docker-compose up -d
```

---

## 📋 **部署后会运行什么？**

### **后端容器 (mediagenie-backend)**
- **镜像构建过程**:
  1. 使用 Python 3.11-slim 基础镜像
  2. 安装系统依赖 (gcc)
  3. 安装 Python 依赖 (FastAPI, Gunicorn, Azure SDK 等)
  4. 复制后端代码
  5. 创建非 root 用户
  
- **运行时**:
  - 启动 Gunicorn 服务器
  - 4 个 Uvicorn worker 进程
  - 监听端口 8000
  - 提供 REST API 服务

- **API 端点**:
  - `GET /` - 根路径
  - `GET /health` - 健康检查
  - `GET /test` - 测试端点
  - `GET /docs` - API 文档 (Swagger UI)

### **前端容器 (mediagenie-frontend)**
- **镜像构建过程**:
  1. 第一阶段 (builder):
     - 使用 Node.js 18-alpine
     - 安装 npm 依赖
     - 构建 React 应用 (`npm run build`)
  2. 第二阶段 (production):
     - 使用 Nginx alpine
     - 复制构建产物到 Nginx 目录
     - 配置 Nginx 服务器

- **运行时**:
  - 启动 Nginx 服务器
  - 监听端口 8080
  - 提供静态文件服务
  - 支持 React Router (SPA 路由)

---

## 🌐 **访问地址**

部署完成后，可以通过以下地址访问：

| 服务 | URL | 说明 |
|------|-----|------|
| 前端应用 | http://13.92.133.12:8080 | React 单页应用 |
| 后端 API | http://13.92.133.12:8000 | FastAPI REST API |
| API 文档 | http://13.92.133.12:8000/docs | Swagger UI 交互式文档 |
| 健康检查 | http://13.92.133.12:8000/health | 服务健康状态 |

---

## 🔍 **验证部署**

### **1. 检查容器状态**

```bash
docker-compose ps
```

应该看到：
```
NAME                    STATUS
mediagenie-backend      Up (healthy)
mediagenie-frontend     Up (healthy)
```

### **2. 测试后端 API**

```bash
# 健康检查
curl http://localhost:8000/health

# 测试端点
curl http://localhost:8000/test
```

### **3. 测试前端**

```bash
# 检查前端是否响应
curl http://localhost:8080

# 应该返回 HTML 内容
```

### **4. 查看日志**

```bash
# 查看所有日志
docker-compose logs -f

# 只看后端
docker-compose logs -f backend

# 只看前端
docker-compose logs -f frontend
```

---

## 📊 **资源使用**

### **Docker 镜像大小**
- 后端镜像: ~200-300 MB
- 前端镜像: ~50-80 MB
- 总计: ~250-380 MB

### **运行时资源**
- 后端容器: ~200-400 MB RAM
- 前端容器: ~20-50 MB RAM
- 总计: ~220-450 MB RAM

### **虚拟机要求**
- **最低配置**: 1 vCPU, 2 GB RAM (当前配置 ✅)
- **推荐配置**: 2 vCPU, 4 GB RAM
- **磁盘空间**: 至少 10 GB 可用空间

---

## ⚙️ **配置说明**

### **环境变量 (.env)**

```env
# 后端配置
ENVIRONMENT=production          # 运行环境
DEBUG=false                     # 调试模式（生产环境关闭）

# 前端配置
REACT_APP_ENV=production        # 前端环境
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000  # 后端 API 地址

# Azure 服务（可选）
AZURE_SPEECH_KEY=               # Azure 语音服务密钥
AZURE_SPEECH_REGION=            # Azure 区域
AZURE_STORAGE_CONNECTION_STRING=  # Azure 存储连接字符串
AZURE_OPENAI_KEY=               # Azure OpenAI 密钥
AZURE_OPENAI_ENDPOINT=          # Azure OpenAI 端点
```

### **数据库配置（可选）**

当前版本**不需要数据库**，数据存储在内存中。

如果需要持久化存储，可以添加：
```env
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/database
```

---

## 🔒 **安全配置**

### **已配置的安全措施**

✅ **容器安全**
- 使用非 root 用户运行
- 最小化基础镜像
- 只暴露必要端口

✅ **网络安全**
- 防火墙配置 (UFW)
- 只开放必要端口 (22, 80, 443, 8000, 8080)

✅ **CORS 配置**
- 后端配置了 CORS 中间件
- 允许跨域请求

### **建议的额外安全措施**

⚠️ **生产环境建议**:
1. 配置 HTTPS (SSL/TLS)
2. 使用环境变量管理敏感信息
3. 配置 Nginx 反向代理
4. 启用速率限制
5. 配置日志监控

---

## 🛠️ **常用管理命令**

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 启动服务
docker-compose up -d

# 重新构建并启动
docker-compose up -d --build

# 进入容器
docker exec -it mediagenie-backend bash
docker exec -it mediagenie-frontend sh

# 查看资源使用
docker stats

# 清理未使用的资源
docker system prune -a
```

---

## ✅ **部署检查清单**

- [ ] 项目代码已克隆到虚拟机
- [ ] Docker 和 Docker Compose 已安装
- [ ] .env 文件已创建
- [ ] Docker 镜像已构建（前端 + 后端）
- [ ] 容器已启动并运行
- [ ] 容器健康检查通过
- [ ] 防火墙已配置
- [ ] Azure NSG 端口已开放
- [ ] 可以访问前端 (http://13.92.133.12:8080)
- [ ] 可以访问后端 (http://13.92.133.12:8000)
- [ ] API 文档可访问 (http://13.92.133.12:8000/docs)

---

## 🎯 **总结**

### **是的，这是完整的部署！**

✅ **包含前端**
- React 应用
- 已构建的静态文件
- Nginx 服务器

✅ **包含后端**
- FastAPI 应用
- Gunicorn + Uvicorn
- REST API 服务

✅ **一键部署**
- 运行一条命令即可
- 自动安装所有依赖
- 自动构建和启动

✅ **直接可用**
- 无需额外配置
- 无需数据库
- 开箱即用

---

## 📚 **相关文档**

- `DEPLOY_VM_SIMPLE.md` - 超简单部署指南
- `QUICK_START_VM.md` - 快速开始指南
- `VM_DEPLOYMENT_GUIDE.md` - 完整部署指南

---

**现在就可以开始部署了！** 🚀

