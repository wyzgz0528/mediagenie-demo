# MediaGenie GitHub 部署 - 最后步骤

## ✅ 已完成的配置

1. ✅ 代码已成功推送到 GitHub: https://github.com/wyzgz0528/mediagenie-demo
2. ✅ Azure Web App 已配置 GitHub 部署源
3. ✅ Python 3.11 运行时已配置
4. ✅ 启动命令已设置为 `startup.sh`

## 🔧 需要你完成的步骤

### 步骤 1: 在 Azure 门户触发部署

由于本地网络环境限制,请按以下步骤在 Azure 门户手动触发部署:

1. 打开 Azure 门户: https://portal.azure.com
2. 找到你的 Web App: **mediagenie-demo**
3. 在左侧菜单找到 **部署中心** (Deployment Center)
4. 你应该会看到已配置的 GitHub 仓库
5. 点击 **同步** 或 **刷新** 按钮触发部署

### 步骤 2: 配置环境变量

部署完成后,需要配置 Azure 服务密钥:

1. 在 Web App 页面,左侧菜单找到 **配置** (Configuration)
2. 点击 **应用程序设置** (Application settings)
3. 添加以下环境变量:

```
AZURE_SPEECH_KEY=你的Azure语音服务密钥
AZURE_SPEECH_REGION=你的Azure语音服务区域
AZURE_VISION_KEY=你的Azure视觉服务密钥
AZURE_VISION_ENDPOINT=你的Azure视觉服务端点
AZURE_OPENAI_KEY=你的Azure OpenAI密钥
AZURE_OPENAI_ENDPOINT=你的Azure OpenAI端点
AZURE_OPENAI_DEPLOYMENT_NAME=你的GPT模型部署名称
AZURE_STORAGE_CONNECTION_STRING=你的Azure存储连接字符串
POSTGRES_HOST=你的PostgreSQL主机地址
POSTGRES_DB=你的数据库名
POSTGRES_USER=你的数据库用户名
POSTGRES_PASSWORD=你的数据库密码
POSTGRES_PORT=5432
```

4. 点击 **保存** 并等待应用重启

### 步骤 3: 验证部署

1. 在 Web App 概述页面,找到 **URL**
2. 点击 URL 打开应用
3. 你应该看到 MediaGenie 的前端界面

### 步骤 4: 查看日志(如果遇到问题)

如果部署失败或应用无法启动:

1. 在 Web App 左侧菜单找到 **日志流** (Log stream)
2. 查看实时日志输出
3. 或者在 **监视** > **日志** 中查看历史日志

## 📋 项目结构说明

部署到 Azure 后的结构:

```
/home/site/wwwroot/
├── backend/
│   └── media-service/      # FastAPI 后端 (端口 8001)
│       ├── main.py
│       └── requirements.txt
├── frontend/
│   ├── build/              # React 构建产物
│   ├── server.js           # Express 服务器 (端口 8080)
│   └── package.json
├── marketplace-portal/     # Flask 市场门户 (端口 5000)
│   └── app.py
├── startup.sh             # 启动脚本
├── supervisord-demo.conf  # 进程管理配置
└── requirements.txt       # Python 依赖
```

## 🚀 启动流程

1. Azure Web App 执行 `startup.sh`
2. `startup.sh` 安装 Python 依赖
3. `startup.sh` 安装 Node.js 依赖
4. `startup.sh` 启动 Supervisord
5. Supervisord 管理三个服务:
   - Backend API (FastAPI, 端口 8001)
   - Frontend Server (Express, 端口 8080)
   - Marketplace Portal (Flask, 端口 5000)

## ⚡ 快速命令参考

如果需要使用 Azure CLI:

```bash
# 查看应用状态
az webapp show --name mediagenie-demo --resource-group mediagenie-demo-rg

# 重启应用
az webapp restart --name mediagenie-demo --resource-group mediagenie-demo-rg

# 查看日志
az webapp log tail --name mediagenie-demo --resource-group mediagenie-demo-rg

# 手动触发部署同步
az webapp deployment source sync --name mediagenie-demo --resource-group mediagenie-demo-rg
```

## 🔍 故障排查

### 问题 1: 应用启动失败
- 检查环境变量是否都已配置
- 查看日志流,找到具体错误信息

### 问题 2: 无法访问前端
- 确认 startup.sh 有执行权限
- 检查 supervisord 是否正常启动

### 问题 3: API 调用失败
- 检查后端服务是否在端口 8001 运行
- 验证 Azure 服务密钥是否正确

## 📞 需要帮助?

如果遇到问题,请提供:
1. 错误截图
2. Azure 门户的日志输出
3. 具体的错误信息

---

**部署资源信息:**
- Web App 名称: `mediagenie-demo`
- 资源组: `mediagenie-demo-rg`
- 区域: `East US`
- GitHub 仓库: `wyzgz0528/mediagenie-demo`
- 分支: `main`
