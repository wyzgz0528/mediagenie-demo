# Azure App Service 简化部署方案

## 🔄 最简单的解决方案

Azure App Service 对 Python 应用有自己的构建和启动流程。我们应该顺应它,而不是对抗它。

### 方案: 使用 Gunicorn 启动单个 FastAPI 应用

#### 步骤 1: 修改 Azure 配置

在 Azure 门户:

1. **配置** → **常规设置** → **启动命令**,改为:
   ```
   gunicorn --bind=0.0.0.0 --timeout 600 --chdir backend/media-service main:app
   ```

2. 或者更简单,留空让 Azure 自动检测

#### 步骤 2: 确保 requirements.txt 包含 gunicorn

检查项目根目录的 `requirements.txt`:

```txt
fastapi
uvicorn[standard]
gunicorn
python-multipart
# 其他依赖...
```

### 为什么这样更简单?

| 方法 | 复杂度 | Azure兼容性 | 推荐度 |
|------|--------|------------|--------|
| Supervisord多服务 | 🔴 高 | ❌ 需要额外配置 | ❌ 不推荐 |
| 自定义Bash脚本 | 🟡 中 | ⚠️ 路径问题多 | ⚠️ 可能有坑 |
| **Gunicorn单服务** | 🟢 低 | ✅ 原生支持 | ✅ **强烈推荐** |

### 架构调整建议

#### 当前架构(复杂):
```
Frontend (Express:8080) ← 用户访问
    ↓
Backend API (FastAPI:8001)
    ↓
Marketplace (Flask:5000)
```

#### 简化架构(推荐):
```
Backend API (FastAPI:8080) ← 直接暴露给用户
    ├─ 静态文件服务 (前端build)
    └─ API路由
```

### 快速实施方案

#### 选项 A: 只部署后端API (最快)

1. 启动命令:
   ```
   cd backend/media-service && gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app
   ```

2. 访问: `https://your-app.azurewebsites.net/docs` 查看API文档

3. 前端另外部署到 Azure Static Web Apps 或 Netlify

#### 选项 B: 后端服务前端静态文件

修改 `backend/media-service/main.py` 添加静态文件服务:

```python
from fastapi.staticfiles import StaticFiles

# 服务前端构建文件
app.mount("/", StaticFiles(directory="../../frontend/build", html=True), name="static")
```

启动命令:
```
cd backend/media-service && gunicorn -w 2 -k uvicorn.workers.UvicornWorker main:app --bind=0.0.0.0:8080
```

### 立即可行的快速方案 🚀

**最简单的测试方案** (5分钟):

1. Azure门户 → **mediagenie-demo** → **配置** → **常规设置**

2. 启动命令改为:
   ```
   python -m uvicorn backend.media-service.main:app --host 0.0.0.0 --port 8080
   ```

3. 保存并重启

4. 访问: `https://mediagenie-demo-gzdvb5cbeceybwh4.eastus-01.azurewebsites.net`

你应该看到 FastAPI 的响应!

### 下一步优化

1. ✅ **先让后端API跑起来** (最重要)
2. 添加 Gunicorn 多worker支持
3. 配置环境变量(Azure服务密钥)
4. 前端静态文件服务或独立部署
5. Marketplace门户单独部署或整合

---

**建议**: 先用最简单的方案让应用跑起来,再逐步优化。现在的问题是想一次性部署太多服务导致复杂度过高。

要我帮你实施"快速方案"吗? 🎯
