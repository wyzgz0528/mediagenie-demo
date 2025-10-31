# MediaGenie 虚拟机部署 - 超简单版

## ✨ 无需数据库！3 步完成部署！

---

## 📋 虚拟机信息

- **IP**: 13.92.133.12
- **用户**: azure
- **密码**: p@ssw0rd2025
- **系统**: Ubuntu 24.04

---

## 🚀 部署步骤

### 第 1 步: 连接到虚拟机

打开 PowerShell 或 CMD：

```bash
ssh azure@13.92.133.12
```

输入密码：`p@ssw0rd2025`

---

### 第 2 步: 运行一键部署命令

在虚拟机上复制粘贴以下**完整命令**：

```bash
cd ~ && \
git clone https://github.com/wyzgz0528/mediagenie-demo.git MediaGenie1001 && \
cd MediaGenie1001 && \
chmod +x deploy-vm-auto.sh && \
./deploy-vm-auto.sh
```

**等待 5-10 分钟**，脚本会自动：
- ✅ 安装 Docker
- ✅ 配置防火墙
- ✅ 构建应用
- ✅ 启动服务

---

### 第 3 步: 开放端口（Azure Portal）

1. 打开 Azure Portal: https://portal.azure.com
2. 找到虚拟机 **mediagenie-demo**
3. 点击 **"网络"** → **"添加入站端口规则"**
4. 添加两个规则：

**规则 1: 后端**
- 端口：`8000`
- 协议：`TCP`
- 名称：`Allow-Backend`

**规则 2: 前端**
- 端口：`8080`
- 协议：`TCP`
- 名称：`Allow-Frontend`

---

## 🎉 完成！访问应用

- **后端 API**: http://13.92.133.12:8000
- **后端文档**: http://13.92.133.12:8000/docs
- **前端应用**: http://13.92.133.12:8080

---

## ❓ 常见问题

### Q1: 为什么不需要数据库？

**A**: 当前版本是测试版，数据存储在内存中。如果需要持久化存储，可以后续添加数据库。

### Q2: 重启后数据会丢失吗？

**A**: 是的，内存数据会丢失。如需持久化，请配置数据库或使用文件存储。

### Q3: 如何查看应用日志？

**A**: 在虚拟机上运行：

```bash
cd ~/MediaGenie1001
docker-compose logs -f
```

按 `Ctrl + C` 退出。

### Q4: 如何重启应用？

**A**: 在虚拟机上运行：

```bash
cd ~/MediaGenie1001
docker-compose restart
```

### Q5: 如何停止应用？

**A**: 在虚拟机上运行：

```bash
cd ~/MediaGenie1001
docker-compose down
```

### Q6: 无法访问应用怎么办？

**检查清单**:
1. ✅ 虚拟机是否运行？
2. ✅ 容器是否启动？运行 `docker-compose ps`
3. ✅ Azure NSG 是否开放端口 8000 和 8080？
4. ✅ 虚拟机防火墙是否允许？运行 `sudo ufw status`

---

## 🛠️ 常用命令

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

# 重新构建
docker-compose up -d --build
```

---

## 📊 验证部署

在虚拟机上运行：

```bash
# 检查容器状态
docker-compose ps

# 测试后端
curl http://localhost:8000/health

# 测试前端
curl http://localhost:8080
```

应该看到正常的响应。

---

## 🔧 故障排除

### 问题：容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 重新构建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题：端口被占用

```bash
# 查看端口占用
sudo netstat -tulpn | grep 8000
sudo netstat -tulpn | grep 8080

# 停止占用端口的进程
sudo kill -9 <PID>
```

### 问题：磁盘空间不足

```bash
# 清理 Docker 资源
docker system prune -a

# 查看磁盘使用
df -h
```

---

## 📈 性能优化（可选）

### 1. 配置 Nginx 反向代理

```bash
sudo apt-get install -y nginx

sudo nano /etc/nginx/sites-available/mediagenie
```

添加配置：

```nginx
server {
    listen 80;
    server_name 13.92.133.12;

    location /api/ {
        proxy_pass http://localhost:8000/;
    }

    location / {
        proxy_pass http://localhost:8080/;
    }
}
```

启用：

```bash
sudo ln -s /etc/nginx/sites-available/mediagenie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 2. 配置自动重启

编辑 docker-compose.yml，确保有：

```yaml
restart: unless-stopped
```

---

## 🎯 下一步

1. **添加域名** (可选)
   - 将域名指向 13.92.133.12
   - 配置 SSL 证书

2. **添加数据库** (可选)
   - 配置 PostgreSQL 或 MySQL
   - 更新 .env 文件

3. **配置监控** (可选)
   - 设置日志收集
   - 配置告警

---

## 📚 更多信息

- 详细指南: `VM_DEPLOYMENT_GUIDE.md`
- 快速开始: `QUICK_START_VM.md`
- GitHub: https://github.com/wyzgz0528/mediagenie-demo

---

## ✅ 部署检查清单

- [ ] SSH 连接成功
- [ ] 一键部署命令运行完成
- [ ] Azure NSG 端口已开放
- [ ] 可以访问 http://13.92.133.12:8000
- [ ] 可以访问 http://13.92.133.12:8080
- [ ] 容器状态正常 (`docker-compose ps`)

---

**就这么简单！** 🎉

如有问题，查看日志：`docker-compose logs -f`

