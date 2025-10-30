# 🔧 启动错误修复

## �?问题

当运行以下命令时出错�?```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

**错误信息**:
```
ERROR:    Error loading ASGI app. Could not import module "main".
```

---

## 🔍 根本原因

Pydantic v2 的配置方式改变了�?- �?旧方�? `class Config:` 
- �?新方�? `model_config = ConfigDict(...)`

同时�?env 文件中有额外的字段（PORT, AZURE_SPEECH_ENDPOINT 等），Pydantic v2 默认不允许这些额外字段�?
---

## �?解决方案

### 修改 config.py

**�?1 �?*: 导入 ConfigDict
```python
from pydantic import Field, ConfigDict
```

**�?2 �?*: 替换 Config �?```python
# �?旧方�?class Config:
    env_file = ".env"
    env_file_encoding = "utf-8"
    case_sensitive = True

# �?新方�?model_config = ConfigDict(
    env_file=".env",
    env_file_encoding="utf-8",
    case_sensitive=True,
    extra="ignore"  # 忽略 .env 中的额外字段
)
```

---

## �?已完�?
我已经修复了 `backend/media-service/config.py` 文件�?
现在你可以重新启动服务：

```powershell
cd F:\project\mediagenie1001\backend\media-service
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

---

## 🚀 启动服务

### 方法 1: 直接命令

```powershell
cd F:\project\mediagenie1001\backend\media-service
python -m uvicorn main:app --host 0.0.0.0 --port 9001 --reload
```

### 方法 2: 使用启动脚本

```powershell
cd F:\project\mediagenie1001\backend\media-service
powershell -ExecutionPolicy Bypass -File run_server.ps1
```

---

## 📊 预期输出

```
INFO:     Will watch for changes in these directories: ['F:\\project\\mediagenie1001']
INFO:     Uvicorn running on http://0.0.0.0:9001 (Press CTRL+C to quit)
INFO:     Started reloader process [26760] using WatchFiles
INFO:     Application startup complete
```

�?**服务已启动！**

---

## 🌐 访问服务

打开浏览器，访问:
```
http://localhost:9001/docs
```

你会看到 **Swagger UI** - 一个交互式�?API 文档界面�?
---

## 🧪 快速测�?
在浏览器中访问以�?URL 进行快速测试：

1. **健康检�?*: `http://localhost:9001/health`
2. **Marketplace 健康检�?*: `http://localhost:9001/marketplace/health`
3. **API 文档**: `http://localhost:9001/docs`

---

## 💡 关键�?
�?**做这�?*:
- �?在新�?PowerShell 窗口中启动服�?- �?等待 "Application startup complete" 消息
- �?使用 Swagger UI 进行交互式测�?
�?**不要做这�?*:
- �?不要�?VS Code 终端中启�?- �?不要关闭 PostgreSQL 容器
- �?不要修改 .env 文件

---

## 🎉 成功标志

�?**当你看到这些时，说明一切正�?*:

1. �?服务启动消息: `Uvicorn running on http://0.0.0.0:9001`
2. �?应用启动完成: `Application startup complete`
3. �?Swagger UI 可以访问: `http://localhost:9001/docs`
4. �?没有错误消息

---

**现在重新启动服务吧！** 🚀

