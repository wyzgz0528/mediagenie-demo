# �?快速参考指�?
> **用�?*: 快速查找常用命令和配置  
> **更新**: 2025-10-27

---

## 🚀 快速启�?
### 启动所有服�?(3 个终�?

**终端 1: 后端服务**
```bash
cd backend/media-service
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

**终端 2: Marketplace Portal**
```bash
cd marketplace-portal
python app.py
```

**终端 3: 前端应用**
```bash
cd frontend
npm start
```

### 访问应用

- 后端 API: `http://localhost:9001/docs`
- Marketplace Portal: `http://localhost:5000`
- 前端应用: `http://localhost:3000`

---

## 🗄�?数据库操�?
### 启动 PostgreSQL

```bash
# 启动 Docker 容器
docker run -d --name mediagenie-postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine

# 连接到数据库
psql -U postgres -d mediagenie
```

### 执行迁移

```bash
cd backend/media-service

# 执行基础迁移
python run_migration.py

# 执行 RLS 迁移
python run_rls_migration.py
```

### 常用 SQL 查询

```sql
-- 查看所有用�?SELECT * FROM users;

-- 查看所有订�?SELECT * FROM subscriptions;

-- 查看所有事�?SELECT * FROM webhook_events;

-- 查看审计日志
SELECT * FROM audit_logs ORDER BY created_at DESC;

-- 查看 RLS 策略
SELECT * FROM pg_policies;
```

---

## 🧪 测试命令

### 健康检�?
```bash
# 后端健康检�?curl http://localhost:9001/health

# Marketplace 健康检�?curl http://localhost:9001/marketplace/health
```

### 发�?Webhook

```bash
curl -X POST http://localhost:9001/marketplace/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "webhook-test-001",
    "activityId": "activity-001",
    "subscriptionId": "sub-test-001",
    "offerId": "offer-test",
    "publisherId": "publisher-test",
    "planId": "basic",
    "quantity": 1,
    "timeStamp": "2025-10-27T10:00:00Z",
    "action": "Subscribe",
    "status": "Success"
  }'
```

### 查询事件

```bash
curl http://localhost:9001/marketplace/events
```

---

## 📝 环境变量

### 后端 (.env)

```env
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/mediagenie
AZURE_AD_TENANT_ID=your-tenant-id
AZURE_AD_CLIENT_ID=your-client-id
AZURE_AD_CLIENT_SECRET=your-client-secret
MARKETPLACE_API_BASE_URL=https://marketplaceapi.microsoft.com/api
CORS_ORIGINS=["http://localhost:3000"]
ENVIRONMENT=development
DEBUG=true
```

### 前端 (.env)

```env
REACT_APP_MEDIA_SERVICE_URL=http://localhost:9001
REACT_APP_AZURE_AD_TENANT_ID=your-tenant-id
REACT_APP_AZURE_AD_CLIENT_ID=your-client-id
REACT_APP_REDIRECT_URI=http://localhost:3000
```

---

## 🔧 常见问题解决

### 后端无法启动

```bash
# 检�?Python 版本
python --version

# 检查依�?pip install -r requirements.txt

# 检查数据库连接
python -c "import asyncpg; print('OK')"

# 检查端口占�?lsof -i :9001
```

### 前端无法启动

```bash
# 清除缓存
rm -rf node_modules package-lock.json

# 重新安装
npm install

# 启动
npm start
```

### 数据库连接失�?
```bash
# 检�?Docker 容器
docker ps

# 查看容器日志
docker logs mediagenie-postgres

# 重启容器
docker restart mediagenie-postgres
```

---

## 📊 文件位置

### 后端文件

| 文件 | 位置 |
|------|------|
| 主应�?| `backend/media-service/main.py` |
| 模型 | `backend/media-service/models.py` |
| 数据�?| `backend/media-service/database.py` |
| 服务 | `backend/media-service/db_service.py` |
| Marketplace | `backend/media-service/marketplace.py` |
| Webhook | `backend/media-service/marketplace_webhook.py` |
| 租户上下�?| `backend/media-service/tenant_context.py` |
| 配置 | `backend/media-service/config.py` |

### 前端文件

| 文件 | 位置 |
|------|------|
| 主应�?| `frontend/src/App.tsx` |
| MSAL 配置 | `frontend/src/config/msalConfig.ts` |
| 认证服务 | `frontend/src/services/authService.ts` |
| API 服务 | `frontend/src/services/api.ts` |
| Redux | `frontend/src/store/slices/authSlice.ts` |
| 登录按钮 | `frontend/src/components/LoginButton.tsx` |
| 环境变量 | `frontend/.env.example` |

### 数据库文�?
| 文件 | 位置 |
|------|------|
| 基础迁移 | `backend/media-service/migrations/001_marketplace_tables.sql` |
| RLS 迁移 | `backend/media-service/migrations/002_multi_tenant_rls.sql` |
| 迁移脚本 | `backend/media-service/run_migration.py` |
| RLS 脚本 | `backend/media-service/run_rls_migration.py` |

### 文档文件

| 文件 | 用�?|
|------|------|
| `PHASE_4_IMPLEMENTATION.md` | Phase 4 实现指南 |
| `PHASE_5_IMPLEMENTATION.md` | Phase 5 实现指南 |
| `END_TO_END_TESTING.md` | 端到端测试指�?|
| `AZURE_DEPLOYMENT_GUIDE.md` | Azure 部署指南 |
| `PROJECT_COMPLETION_SUMMARY.md` | 项目总结 |
| `FINAL_REPORT.md` | 最终报�?|

---

## 🔐 安全检查清�?
- [ ] 检�?.env 文件不在版本控制�?- [ ] 检�?Azure AD 凭证已配�?- [ ] 检�?JWT 令牌验证已启�?- [ ] 检�?CORS 配置正确
- [ ] 检�?RLS 策略已启�?- [ ] 检查审计日志已启用
- [ ] 检�?SSL/TLS 已配�?- [ ] 检查密钥已存储�?Key Vault

---

## 📈 性能检查清�?
- [ ] 检查数据库连接池配�?- [ ] 检查查询性能
- [ ] 检查缓存策�?- [ ] 检�?API 响应时间
- [ ] 检查前端加载时�?- [ ] 检查内存使�?- [ ] 检�?CPU 使用
- [ ] 检查网络带�?
---

## 🚀 部署检查清�?
- [ ] 检查所有依赖已安装
- [ ] 检查环境变量已配置
- [ ] 检查数据库迁移已执�?- [ ] 检�?SSL 证书已配�?- [ ] 检查备份已配置
- [ ] 检查监控已启用
- [ ] 检查日志已配置
- [ ] 检�?CI/CD 已配�?
---

## 💡 有用的链�?
### 文档
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [React 文档](https://react.dev/)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Azure 文档](https://docs.microsoft.com/azure/)
- [MSAL.js 文档](https://github.com/AzureAD/microsoft-authentication-library-for-js)

### 工具
- [Swagger UI](http://localhost:9001/docs)
- [PostgreSQL 客户端](https://www.pgadmin.org/)
- [Azure CLI](https://docs.microsoft.com/cli/azure/)
- [VS Code](https://code.visualstudio.com/)

---

## 📞 快速支�?
### 查看日志

```bash
# 后端日志
tail -f backend/media-service/logs/app.log

# 前端日志
# 打开浏览器开发者工�?(F12) -> Console

# 数据库日�?docker logs mediagenie-postgres
```

### 重启服务

```bash
# 重启后端
# 在启动后端的终端中按 Ctrl+C，然后重新运�?
# 重启前端
# 在启动前端的终端中按 Ctrl+C，然后重新运�?
# 重启数据�?docker restart mediagenie-postgres
```

### 清除缓存

```bash
# 清除 Python 缓存
find . -type d -name __pycache__ -exec rm -r {} +
find . -type f -name "*.pyc" -delete

# 清除 Node 缓存
rm -rf node_modules package-lock.json
npm cache clean --force

# 清除 Docker 缓存
docker system prune -a
```

---

## �?完成检�?
- [x] 后端 API 完整
- [x] 前端应用完整
- [x] 数据库集成完�?- [x] 安全认证完整
- [x] 多租户隔离完�?- [x] 文档完整
- [x] 测试指南完整
- [x] 部署指南完整

---

**需要帮助？** 参考相应的指南文档或查�?`FINAL_REPORT.md`

**准备好了吗？** 选择执行 RLS 迁移、运行端到端测试或部署到 Azure�?
