# �?MediaGenie Azure Marketplace 部署检查清�?

## 📋 部署前准�?

### Azure 账号和订�?
- [ ] 已登�?Azure Portal (https://portal.azure.com)
- [ ] 确认使用订阅: WYZ (3628daff-52ae-4f64-a310-28ad4b2158ca)
- [ ] 确认订阅有足够配�?(App Service Plan B1)
- [ ] 已启�?Cloud Shell

### 本地文件准备
- [x] 部署包已创建: `mediagenie-deploy-20251023_220909.zip` (0.63 MB)
- [x] 包含后端代码和配�?
- [x] 包含前端代码和配�?
- [x] 包含部署脚本 `deploy.sh`
- [x] 包含 README 说明

### Azure 服务验证
- [x] Azure Speech Service 密钥已配�?
- [x] Azure Computer Vision 密钥已配�?
- [x] Azure OpenAI 密钥已配�?
- [x] Azure Storage 连接字符串已配置

---

## 🚀 部署过程检�?

### 第一阶段: 上传部署�?
- [ ] 打开 Azure Cloud Shell
- [ ] 选择 Bash 环境
- [ ] 成功上传 `mediagenie-deploy-20251023_220909.zip`
- [ ] 文件大小正确 (�?0.63 MB)

### 第二阶段: 解压和准�?
```bash
unzip mediagenie-deploy-20251023_220909.zip -d mediagenie-deploy
cd mediagenie-deploy
chmod +x scripts/deploy.sh
```

- [ ] 解压成功,无错�?
- [ ] 进入 `mediagenie-deploy` 目录
- [ ] 脚本权限设置成功

### 第三阶段: 运行部署脚本
```bash
./scripts/deploy.sh
```

#### 资源创建检�?
- [ ] 设置 Azure 订阅成功
- [ ] 创建资源组成�?(mediagenie-marketplace-XXXXX)
- [ ] 创建 App Service Plan 成功 (B1 基本�?
- [ ] 创建后端 Web App 成功 (mediagenie-api-XXXXX)
- [ ] 配置后端环境变量成功 (23 个变�?

#### 后端部署检�?
- [ ] 后端代码打包成功 (backend-deploy.zip)
- [ ] 后端代码上传成功
- [ ] 后端应用启动成功
- [ ] 获得后端 URL: `https://mediagenie-api-XXXXX.azurewebsites.net`

#### 前端部署检�?
- [ ] 创建前端 Web App 成功 (mediagenie-web-XXXXX)
- [ ] 配置前端环境变量成功 (包含后端 API URL)
- [ ] 前端代码打包成功 (frontend-deploy.zip)
- [ ] 前端代码上传成功
- [ ] 前端应用启动成功
- [ ] 获得前端 URL: `https://mediagenie-web-XXXXX.azurewebsites.net`

### 第四阶段: 部署信息记录
- [ ] 复制资源组名�? ___________________________
- [ ] 复制后端应用�? ___________________________
- [ ] 复制前端应用�? ___________________________
- [ ] 复制后端 URL: ___________________________
- [ ] 复制前端 URL: ___________________________
- [ ] 复制 Landing Page URL: ___________________________/marketplace/landing
- [ ] 复制 Webhook URL: ___________________________/marketplace/webhook
- [ ] 保存 deployment-info.json 文件

---

## 🧪 部署后验�?

### 基础健康检�?
```bash
curl https://mediagenie-api-XXXXX.azurewebsites.net/health
```

预期结果:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "services": {
    "speech": "ok",
    "vision": "ok",
    "openai": "ok",
    "storage": "ok"
  }
}
```

- [ ] 健康检查返�?200 OK
- [ ] 所有服务状态为 "ok"
- [ ] 响应时间 < 2 �?

### 后端 API 验证

#### 1. API 文档访问
浏览器访�? `https://mediagenie-api-XXXXX.azurewebsites.net/docs`

- [ ] 页面加载成功
- [ ] 看到 FastAPI Swagger UI
- [ ] 显示所�?API 端点

#### 2. Marketplace 端点测试
```bash
# Landing Page
curl https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing

# Webhook (GET)
curl https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/webhook
```

- [ ] Landing Page 返回 HTML 内容
- [ ] Webhook 返回正确响应
- [ ] �?404 �?500 错误

#### 3. 核心 API 测试
```bash
# 语音转文�?(需要音频文�?
curl -X POST https://mediagenie-api-XXXXX.azurewebsites.net/api/speech-to-text \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.wav"

# 文本转语�?
curl -X POST https://mediagenie-api-XXXXX.azurewebsites.net/api/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World","language":"en-US"}'
```

- [ ] 语音转文�?API 正常工作
- [ ] 文本转语�?API 正常工作
- [ ] 图像分析 API 正常工作
- [ ] GPT 聊天 API 正常工作

### 前端应用验证

浏览器访�? `https://mediagenie-web-XXXXX.azurewebsites.net`

#### 页面加载检�?
- [ ] 首页/登录页加载成�?
- [ ] �?JavaScript 错误 (F12 控制�?
- [ ] �?CSS 加载错误
- [ ] Logo 和图片正常显�?

#### 功能模块检�?
- [ ] 语音转文本模块可访问
- [ ] 文本转语音模块可访问
- [ ] 图像分析模块可访�?
- [ ] GPT 聊天模块可访�?
- [ ] 用户中心可访�?

#### 前后端连接检�?
- [ ] 前端可以连接到后�?API
- [ ] API 请求�?CORS 错误
- [ ] 文件上传功能正常
- [ ] 实时响应正常显示

### Azure Portal 验证

访问 Azure Portal: https://portal.azure.com

- [ ] 在订阅中找到资源�?`mediagenie-marketplace-XXXXX`
- [ ] 资源组包�?3 个资�?
  - [ ] App Service Plan (mediagenie-plan-XXXXX)
  - [ ] App Service (mediagenie-api-XXXXX) - 后端
  - [ ] App Service (mediagenie-web-XXXXX) - 前端
- [ ] 所有资源状态为"正在运行"
- [ ] 无错误或警告

---

## 🔗 Partner Center 配置

### 访问 Partner Center
- [ ] 登录: https://partner.microsoft.com/dashboard
- [ ] 找到 MediaGenie SaaS Offer
- [ ] 进入"Technical Configuration"部分

### 填写技术配�?
- [ ] Landing Page URL: `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/landing`
- [ ] Connection Webhook: `https://mediagenie-api-XXXXX.azurewebsites.net/marketplace/webhook`
- [ ] Azure AD Tenant ID: ___________________________
- [ ] Azure AD Application ID: ___________________________

### 测试配置
- [ ] 保存配置
- [ ] 运行 Partner Center 集成测试
- [ ] 测试通过,无错�?

### 提交审核
- [ ] 所有必填项已完�?
- [ ] 预览版本测试通过
- [ ] 提交 Offer 审核
- [ ] 等待 Microsoft 审核结果

---

## 📊 性能和监�?

### 应用性能检�?
- [ ] 后端响应时间 < 2 �?
- [ ] 前端首页加载时间 < 3 �?
- [ ] API 端点平均响应 < 1 �?
- [ ] 无内存泄漏或�?CPU 使用

### 日志配置
```bash
# 启用应用日志
az webapp log config \
  --name mediagenie-api-XXXXX \
  --resource-group mediagenie-marketplace-XXXXX \
  --application-logging filesystem \
  --web-server-logging filesystem
```

- [ ] 后端日志已启�?
- [ ] 前端日志已启�?
- [ ] 可以查看实时日志�?

### 监控设置(可�?
- [ ] 启用 Application Insights
- [ ] 配置告警规则 (错误�?> 5%)
- [ ] 设置可用性测�?
- [ ] 配置 Dashboard 仪表�?

---

## 🔒 安全性检�?

### HTTPS 配置
- [ ] 所�?URL 使用 HTTPS
- [ ] SSL 证书有效
- [ ] 无证书警�?

### 环境变量安全
- [ ] 密钥不在代码中硬编码
- [ ] 敏感信息仅在 App Service Settings
- [ ] 生产环境使用 Azure Key Vault (推荐)

### CORS 配置
- [ ] CORS 策略正确配置
- [ ] 允许前端域名访问后端
- [ ] 生产环境限制 CORS 域名

### 认证授权
- [ ] Marketplace webhook 验证正确
- [ ] Azure AD 集成配置正确
- [ ] API 端点需要的认证已实�?

---

## 💰 成本和配�?

### 资源成本确认
- [ ] App Service Plan: B1 (�?$54.75/�?
- [ ] Speech Service: 按使用量计费
- [ ] Computer Vision: 按使用量计费
- [ ] OpenAI: �?token 计费
- [ ] Storage: 按使用量计费

### 配额检�?
- [ ] App Service 配额充足
- [ ] Speech Service 配额充足
- [ ] Vision Service 配额充足
- [ ] OpenAI Service 配额充足

---

## 🚨 应急准�?

### 回滚计划
- [ ] 记录部署时间和版�?
- [ ] 保留上一个工作版本的部署�?
- [ ] 了解如何快速重新部�?

### 支持联系方式
- [ ] Azure 支持计划已激�?
- [ ] 知道如何提交 Azure 支持工单
- [ ] 保存 Partner Center 支持联系方式

### 备份策略
- [ ] 配置 Storage 备份
- [ ] 保存所有环境变�?
- [ ] 导出资源配置模板

---

## �?最终确�?

### 部署完成检�?
- [ ] 所有上述检查项已完�?
- [ ] 所�?URL 已记录并保存
- [ ] 所有服务运行正�?
- [ ] 前后端通信正常
- [ ] Marketplace 集成就绪

### 文档和交�?
- [ ] deployment-info.json 已保�?
- [ ] 部署 URL 清单已整�?
- [ ] Partner Center 配置已完�?
- [ ] 用户文档已准�?如需�?

### 下一步行�?
- [ ] 通知团队部署完成
- [ ] 进行用户验收测试 (UAT)
- [ ] 准备 Marketplace 上线材料
- [ ] 制定运维监控计划

---

## 📅 部署记录

**部署执行�?*: ___________________________

**部署日期**: ___________________________

**部署开始时�?*: ___________________________

**部署完成时间**: ___________________________

**总耗时**: ___________________________

**遇到的问�?*: 
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**解决方案**: 
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**备注**: 
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## 🎉 恭喜!

如果所有检查项都已完成,你的 MediaGenie 应用已成功部署到 Azure Marketplace!

**下一�?*: 
1. 持续监控应用性能
2. 收集用户反馈
3. 迭代优化功能
4. 准备扩展到更多市�?

祝你的应用在 Azure Marketplace 上取得成�? 🚀
