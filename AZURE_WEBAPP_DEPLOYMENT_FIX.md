# 🚨 Azure Web App 前端部署问题修复

## 问题分析

### 🔍 错误原因
你的前端部署失败是因为：

1. **错误的启动方�?*: Azure Web App 试图运行 `react-scripts start`（开发模式）
2. **缺少生产配置**: 没有正确的生产环�?package.json
3. **缺少静态文件服务器**: React 构建后需�?Express 服务器来服务静态文�?
### 📋 错误日志分析
```
Invalid options object. Dev Server has been initialized using an options object that does not match the API schema.
- options.allowedHosts[0] should be a non-empty string.
```

这表�?`react-scripts start` 在生产环境中无法正常工作�?
---

## �?解决方案

### 1. 更新前端文件结构

我已经为你创建了以下文件�?
```
frontend/
├── server.js                 �?新的生产服务�?├── package-production.json   �?生产环境依赖
├── web.config                �?IIS配置（Azure Web App�?├── .deployment               �?Kudu部署配置
├── deploy.cmd                �?部署脚本
└── build/                    �?React构建文件（已存在�?```

### 2. 关键文件说明

#### `server.js` - 生产服务�?- �?使用 Express 服务静态文�?- �?支持 SPA 路由
- �?包含健康检查端�?- �?正确的错误处�?
#### `package-production.json` - 生产依赖
- �?只包�?Express（轻量级�?- �?指定 Node.js 版本
- �?正确的启动脚�?
#### `web.config` - Azure Web App 配置
- �?IIS + Node.js 集成
- �?URL 重写规则
- �?静态文件缓�?- �?安全头配�?
---

## 🚀 重新部署步骤

### 方法1: 使用 Azure CLI（推荐）

```bash
# 1. 进入前端目录
cd frontend

# 2. 确保构建文件存在
ls build/  # 应该看到 index.html �?static/ 目录

# 3. 创建部署�?zip -r frontend-production.zip . -x "node_modules/*" "src/*" "public/*" "*.log"

# 4. 部署�?Azure Web App
az webapp deployment source config-zip \
  --resource-group "你的资源组名�? \
  --name "你的前端应用名称" \
  --src frontend-production.zip
```

### 方法2: 使用 VS Code Azure 扩展

1. **选择正确的文�?*:
   - �?包含 `build/` 目录
   - �?包含 `server.js`
   - �?包含 `package-production.json`
   - �?包含 `web.config`
   - �?排除 `node_modules/`
   - �?排除 `src/`

2. **部署设置**:
   - Runtime: Node.js 18 LTS
   - Startup Command: `node server.js`

---

## 🔧 Azure Web App 配置

### 应用设置（Application Settings�?
�?Azure Portal 中添加以下设置：

```bash
WEBSITE_NODE_DEFAULT_VERSION = "18-lts"
SCM_DO_BUILD_DURING_DEPLOYMENT = "false"  # 重要：禁用构�?```

### 启动命令（Startup Command�?
```bash
node server.js
```

---

## �?验证部署

### 1. 检查健康状�?```bash
curl https://你的前端应用.azurewebsites.net/health
```

**期望响应**:
```json
{
  "status": "ok",
  "service": "mediagenie-frontend",
  "timestamp": "2025-10-27T13:45:00.000Z",
  "port": 8080
}
```

### 2. 检查前端页�?访问: `https://你的前端应用.azurewebsites.net`

应该看到 MediaGenie 登录页面�?
### 3. 检查日�?�?Azure Portal 中查看日志流�?
**正确的日志应该显�?*:
```
🚀 MediaGenie Frontend Server Starting...
📁 Serving from: D:\home\site\wwwroot
🌐 Port: 8080
�?MediaGenie Frontend Server running on port 8080
```

---

## 🔄 如果仍有问题

### 常见问题排查

1. **构建文件缺失**:
   ```bash
   # 本地重新构建
   cd frontend
   npm run build
   ```

2. **端口问题**:
   - Azure Web App 自动设置 `PORT` 环境变量
   - 我们�?`server.js` 已经正确处理

3. **路由问题**:
   - `web.config` 已配�?SPA 路由支持
   - 所有路由都会返�?`index.html`

### 调试命令

```bash
# 检查应用状�?az webapp show --name "你的前端应用名称" --resource-group "你的资源组名�?

# 查看日志
az webapp log tail --name "你的前端应用名称" --resource-group "你的资源组名�?

# 重启应用
az webapp restart --name "你的前端应用名称" --resource-group "你的资源组名�?
```

---

## 📝 下一�?
1. **重新部署前端** 使用新的配置文件
2. **验证前端访问** 确保页面正常加载
3. **测试后端连接** 确保前端能调用后�?API
4. **配置 CORS** 确保跨域请求正常

需要我帮你执行重新部署吗？
