# MediaGenie VM 部署指南

## 虚拟机信息

- **IP 地址**: 13.92.133.12
- **用户名**: azure
- **密码**: p@ssw0rd2025
- **操作系统**: Ubuntu 24.04
- **位置**: East US

---

## 快速部署（推荐）

### 方法 1: 自动化脚本部署

#### 步骤 1: 准备文件传输

在本地 Windows 机器上运行：

```powershell
.\transfer-to-vm.ps1
```

这个脚本会：
- 创建项目压缩包
- 尝试通过 SCP 传输到 VM
- 如果 SCP 不可用，提供其他传输方法

#### 步骤 2: SSH 连接到 VM

打开 PowerShell 或 CMD：

```bash
ssh azure@13.92.133.12
```

输入密码：`p@ssw0rd2025`

#### 步骤 3: 解压项目文件

```bash
cd ~
unzip mediagenie.zip -d MediaGenie1001
cd MediaGenie1001
```

#### 步骤 4: 运行自动部署脚本

```bash
chmod +x deploy-vm-auto.sh
./deploy-vm-auto.sh
```

脚本会自动：
- 安装 Docker 和 Docker Compose
- 配置防火墙
- 创建 .env 文件
- 构建并启动容器

#### 步骤 5: 配置数据库连接

编辑 .env 文件：

```bash
nano .env
```

更新数据库密码：

```env
DATABASE_URL=postgresql+asyncpg://dbadmin:YOUR_ACTUAL_PASSWORD@mediagenie-db-5428.postgres.database.azure.com:5432/mediagenie
```

保存并退出（Ctrl+X, Y, Enter）

#### 步骤 6: 重启容器

```bash
docker-compose restart
```

#### 步骤 7: 配置 Azure NSG

在 Azure Portal 中：
1. 进入虚拟机的网络安全组 (NSG)
2. 添加入站规则：
   - **端口 8000** (Backend API)
   - **端口 8080** (Frontend)
   - **端口 80** (HTTP)
   - **端口 443** (HTTPS)

#### 步骤 8: 访问应用

- **后端 API**: http://13.92.133.12:8000
- **后端文档**: http://13.92.133.12:8000/docs
- **前端应用**: http://13.92.133.12:8080

---

## 方法 2: 手动部署

### 1. 连接到 VM

```bash
ssh azure@13.92.133.12
```

### 2. 安装 Docker

```bash
# 更新系统
sudo apt-get update

# 安装 Docker
sudo apt-get install -y docker.io docker-compose

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到 docker 组
sudo usermod -aG docker azure

# 重新登录以应用组更改
exit
ssh azure@13.92.133.12
```

### 3. 传输项目文件

**选项 A: 使用 Git**

```bash
cd ~
git clone https://github.com/wyzgz0528/mediagenie-demo.git MediaGenie1001
cd MediaGenie1001
```

**选项 B: 使用 SCP（从本地机器运行）**

```powershell
# 在本地 Windows 机器上
scp -r F:\project\MediaGenie1001 azure@13.92.133.12:~/
```

**选项 C: 使用 WinSCP**

1. 下载 WinSCP: https://winscp.net/
2. 连接到 VM (13.92.133.12)
3. 上传整个项目文件夹

### 4. 创建 .env 文件

```bash
cd ~/MediaGenie1001
nano .env
```

添加以下内容：

```env
# Database
DATABASE_URL=postgresql+asyncpg://dbadmin:YOUR_PASSWORD@mediagenie-db-5428.postgres.database.azure.com:5432/mediagenie

# Backend
ENVIRONMENT=production
DEBUG=false

# Frontend
REACT_APP_ENV=production
REACT_APP_MEDIA_SERVICE_URL=http://13.92.133.12:8000

# Azure Services (可选)
AZURE_SPEECH_KEY=
AZURE_SPEECH_REGION=
AZURE_STORAGE_CONNECTION_STRING=
AZURE_OPENAI_KEY=
AZURE_OPENAI_ENDPOINT=
```

### 5. 构建并启动容器

```bash
cd ~/MediaGenie1001

# 构建镜像
docker-compose build

# 启动容器
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 6. 配置防火墙

```bash
# 启用防火墙
sudo ufw enable

# 允许必要的端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8000/tcp  # Backend
sudo ufw allow 8080/tcp  # Frontend

# 查看状态
sudo ufw status
```

---

## 常用命令

### Docker 管理

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 重新构建并启动
docker-compose up -d --build

# 进入容器
docker exec -it mediagenie-backend bash
docker exec -it mediagenie-frontend sh
```

### 系统管理

```bash
# 查看系统资源
htop
df -h
free -h

# 查看端口占用
sudo netstat -tulpn | grep LISTEN

# 查看防火墙状态
sudo ufw status

# 查看 Docker 资源使用
docker stats
```

---

## 故障排除

### 问题 1: 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
sudo netstat -tulpn | grep 8000
sudo netstat -tulpn | grep 8080

# 重新构建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题 2: 无法访问应用

1. **检查容器状态**:
   ```bash
   docker-compose ps
   ```

2. **检查防火墙**:
   ```bash
   sudo ufw status
   ```

3. **检查 Azure NSG**: 确保在 Azure Portal 中开放了端口

4. **检查日志**:
   ```bash
   docker-compose logs -f
   ```

### 问题 3: 数据库连接失败

1. **检查 .env 文件**:
   ```bash
   cat .env | grep DATABASE_URL
   ```

2. **测试数据库连接**:
   ```bash
   docker exec -it mediagenie-backend python -c "
   import asyncpg
   import asyncio
   async def test():
       conn = await asyncpg.connect('YOUR_DATABASE_URL')
       print('Connected!')
       await conn.close()
   asyncio.run(test())
   "
   ```

3. **检查 PostgreSQL 防火墙规则**: 在 Azure Portal 中确保 VM 的 IP 被允许

### 问题 4: 前端无法连接后端

1. **检查环境变量**:
   ```bash
   docker exec -it mediagenie-frontend env | grep REACT_APP
   ```

2. **更新 .env 并重启**:
   ```bash
   nano .env
   # 更新 REACT_APP_MEDIA_SERVICE_URL
   docker-compose restart frontend
   ```

---

## 性能优化

### 1. 使用 Nginx 反向代理

```bash
# 安装 Nginx
sudo apt-get install -y nginx

# 配置反向代理
sudo nano /etc/nginx/sites-available/mediagenie
```

添加配置：

```nginx
server {
    listen 80;
    server_name 13.92.133.12;

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/mediagenie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 2. 配置 SSL (HTTPS)

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 获取证书（需要域名）
sudo certbot --nginx -d your-domain.com
```

---

## 监控和日志

### 设置日志轮转

```bash
# 配置 Docker 日志大小限制
sudo nano /etc/docker/daemon.json
```

添加：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

重启 Docker：

```bash
sudo systemctl restart docker
docker-compose up -d
```

---

## 备份和恢复

### 备份数据

```bash
# 备份 .env 文件
cp .env .env.backup

# 导出 Docker 镜像
docker save mediagenie1001-backend:latest | gzip > backend-image.tar.gz
docker save mediagenie1001-frontend:latest | gzip > frontend-image.tar.gz
```

### 恢复数据

```bash
# 恢复镜像
docker load < backend-image.tar.gz
docker load < frontend-image.tar.gz

# 恢复 .env
cp .env.backup .env

# 重启服务
docker-compose up -d
```

---

## 安全建议

1. **更改默认密码**: 修改 VM 的 azure 用户密码
2. **配置 SSH 密钥**: 使用 SSH 密钥而不是密码登录
3. **限制 SSH 访问**: 只允许特定 IP 访问 SSH
4. **定期更新**: 定期更新系统和 Docker 镜像
5. **使用 HTTPS**: 配置 SSL 证书
6. **配置防火墙**: 只开放必要的端口

---

## 联系和支持

如有问题，请查看：
- 项目文档: `README.md`
- GitHub Issues: https://github.com/wyzgz0528/mediagenie-demo/issues

