# MediaGenie 部署修复指南 - 完整解决方案

## 🔍 问题诊断

从日志中看到的关键错误:
```
supervisord: not found
Container didn't respond to HTTP pings on port: 8001
```

**原因**: Azure App Service的Python镜像默认没有安装 supervisord。

## ✅ 解决方案

我已经创建了一个新的启动脚本 `startup_azure.sh`,不依赖supervisord,直接启动所有服务。

### 方案 1: 在Azure门户手动配置(推荐 - 最简单)

#### 步骤 1: 更新启动命令

1. 打开 Azure 门户: https://portal.azure.com
2. 找到 Web App: **mediagenie-demo**
3. 左侧菜单 → **配置**
4. 点击 **常规设置** 标签
5. 找到 **启动命令** 字段
6. 将内容改为:
   ```
   /home/site/wwwroot/startup_azure.sh
   ```
7. 点击顶部的 **保存**
8. 点击 **继续** 确认重启

#### 步骤 2: 重新同步部署

1. 左侧菜单 → **部署中心**
2. 点击 **同步** 按钮
3. 等待 3-5 分钟让部署完成

#### 步骤 3: 查看日志验证

1. 左侧菜单 → **日志流**
2. 你应该看到:
   ```
   🚀 Starting MediaGenie Application on Azure App Service...
   📦 Installing Python dependencies...
   🎯 Starting backend service (FastAPI)...
   ✅ Backend started with PID: xxx
   🎯 Starting marketplace portal (Flask)...
   ✅ Marketplace started with PID: xxx
   🎯 Starting frontend server (Express)...
   ```

### 方案 2: 使用 Azure CLI

如果你偏好命令行(需要网络连接正常):

```powershell
# 重新登录
az login

# 更新启动命令
az webapp config set `
  --resource-group mediagenie-demo-rg `
  --name mediagenie-demo `
  --startup-file "/home/site/wwwroot/startup_azure.sh"

# 重启应用
az webapp restart `
  --resource-group mediagenie-demo-rg `
  --name mediagenie-demo

# 查看日志
az webapp log tail `
  --resource-group mediagenie-demo-rg `
  --name mediagenie-demo
```

## 📝 新启动脚本的优势

`startup_azure.sh` vs 原来的 `startup.sh`:

| 特性 | startup_azure.sh | 原来的startup.sh |
|------|-----------------|-----------------|
| 依赖supervisord | ❌ 不需要 | ✅ 需要(未安装) |
| Azure兼容性 | ✅ 完全兼容 | ❌ 依赖缺失 |
| 进程管理 | Bash后台进程 | Supervisord |
| 日志输出 | 分离到各自日志 | 统一管理 |

## 🔧 如果还有问题

### 问题 1: Node.js 未安装

如果看到 `node: not found` 错误,需要在启动脚本中安装Node.js。启动脚本已包含自动安装逻辑。

### 问题 2: 端口冲突

Azure App Service 自动分配 `PORT` 环境变量。新脚本会:
- Backend: 固定 8001 端口
- Marketplace: 固定 5000 端口  
- Frontend: 使用 Azure 的 `$PORT` 变量(通常是 8080)

### 问题 3: 依赖安装失败

检查 `requirements.txt` 是否包含所有必需的包:
```
fastapi
uvicorn
flask
# ... 其他依赖
```

## ⚡ 快速诊断命令

```bash
# SSH 到 Azure App Service 容器
az webapp ssh --resource-group mediagenie-demo-rg --name mediagenie-demo

# 进入后执行:
cd /home/site/wwwroot
ls -la startup_azure.sh         # 检查文件是否存在
chmod +x startup_azure.sh        # 确保可执行
./startup_azure.sh               # 手动测试启动

# 查看后台服务日志
cat backend.log
cat marketplace.log

# 检查进程
ps aux | grep python
ps aux | grep node
```

## 📊 预期的部署流程

1. **代码推送到GitHub** ✅ 已完成
2. **Azure从GitHub拉取代码** ✅ 同步完成  
3. **Oryx构建系统构建** ✅ 成功
4. **执行startup_azure.sh** ⏳ 等待配置
5. **启动所有服务** ⏳ 待验证
6. **应用响应健康检查** ⏳ 待验证

## 🎯 完成后的验证步骤

1. **访问应用URL**: https://mediagenie-demo-gzdvb5cbeceybwh4.eastus-01.azurewebsites.net
2. **检查前端**: 应该看到 MediaGenie 界面
3. **测试API**: 访问 `https://<your-app>.azurewebsites.net/docs` 查看 FastAPI 文档

## 💡 后续优化建议

完成部署后,考虑:

1. **启用应用洞察(Application Insights)** - 更好的监控
2. **配置自定义域名** - 更专业的访问地址
3. **启用HTTPS证书** - 增强安全性
4. **设置自动扩展** - 根据负载自动调整实例数

---

**当前状态**:
- ✅ GitHub仓库: https://github.com/wyzgz0528/mediagenie-demo
- ✅ 新启动脚本: `startup_azure.sh` (已推送)
- ⏳ 待配置: 启动命令指向新脚本
- ⏳ 待配置: 环境变量(Azure服务密钥)

**下一步**: 在Azure门户按照 **方案 1** 的步骤操作即可! 🚀
