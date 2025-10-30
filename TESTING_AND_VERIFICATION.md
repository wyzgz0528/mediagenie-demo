# 🧪 本地开发环�?- 测试和验证指�?
> **状�?*: �?所有服务正常运�? 
> **应用状�?*: �?功能正常  
> **时间**: 2025-10-27

---

## 🎯 快速验�?
### 步骤 1: 验证所有服务都在运�?
```bash
# 运行验证脚本
.\verify-local-setup.ps1
```

**预期输出**:
```
�?PostgreSQL 容器正在运行
�?后端 API 服务正在运行 (端口 9001)
�?前端应用正在运行 (端口 3000)
�?Marketplace Portal 正在运行 (端口 5000)
```

### 步骤 2: 打开浏览器访问应�?
```
http://localhost:3000
```

**预期结果**:
- �?应用正常加载
- �?看到 MediaGenie 界面
- �?可以点击按钮和操�?
### 步骤 3: 打开开发者工具检�?
�?F12 打开开发者工具，切换�?Console 标签

**预期结果**:
- �?没有 404 错误
- �?没有 CORS 错误
- �?可能有一些警告（这是正常的）

---

## 📊 详细测试场景

### 测试 1: 后端健康检�?
**目的**: 验证后端服务正常运行

**步骤**:
1. 打开浏览器访�? http://localhost:9001/health
2. 或者在终端运行: `curl http://localhost:9001/health`

**预期结果**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-27T...",
  "services": {
    "speech": "available",
    "vision": "available",
    "storage": "available"
  }
}
```

**状�?*: �?通过

---

### 测试 2: API 文档访问

**目的**: 验证 Swagger UI 正常工作

**步骤**:
1. 打开浏览器访�? http://localhost:9001/docs
2. 查看 API 端点列表

**预期结果**:
- �?Swagger UI 正常加载
- �?可以看到所�?API 端点
- �?可以展开端点查看详情

**状�?*: �?通过

---

### 测试 3: 前端应用加载

**目的**: 验证前端应用正常加载

**步骤**:
1. 打开浏览器访�? http://localhost:3000
2. 等待应用加载完成
3. 打开开发者工�?(F12)

**预期结果**:
- �?应用正常加载
- �?看到 MediaGenie 界面
- �?没有 404 错误
- �?可能有一些警告（正常�?
**状�?*: �?通过

---

### 测试 4: API 调用测试

**目的**: 验证前端可以调用后端 API

**步骤**:
1. 打开前端应用: http://localhost:3000
2. 打开开发者工�?(F12)
3. 切换�?Network 标签
4. 在应用中执行操作（如上传图片�?5. 查看 Network 标签中的请求

**预期结果**:
- �?API 请求返回 200 �?201 状态码
- �?没有 404 错误
- �?没有 CORS 错误
- �?响应数据正确

**状�?*: �?通过

---

### 测试 5: 数据库连�?
**目的**: 验证数据库正常工�?
**步骤**:
1. 连接到数据库:
   ```bash
   docker exec -it mediagenie-postgres psql -U postgres -d mediagenie
   ```

2. 查询�?
   ```sql
   SELECT * FROM users;
   SELECT * FROM subscriptions;
   SELECT * FROM webhook_events;
   ```

**预期结果**:
- �?可以连接到数据库
- �?表存�?- �?可以查询数据

**状�?*: �?通过

---

### 测试 6: Marketplace Portal

**目的**: 验证 Marketplace Portal 正常工作

**步骤**:
1. 打开浏览器访�? http://localhost:5000
2. 查看 Portal 界面

**预期结果**:
- �?Portal 正常加载
- �?可以看到 Landing Page
- �?可以点击按钮

**状�?*: �?通过

---

## 🔍 浏览器控制台检�?
### 预期的警告（可以忽略�?
```
⚠️ 没有活跃的账�?⚠️ React Router Future Flag Warning
⚠️ [antd: Card] `bodyStyle` is deprecated
```

**说明**: 这些是正常的警告，不影响应用功能

### 不应该出现的错误

```
�?Failed to load resource: 404
�?Access to XMLHttpRequest blocked by CORS policy
�?Uncaught TypeError
```

**说明**: 如果出现这些错误，需要调�?
---

## 📈 性能检�?
### 页面加载时间

**目标**: < 3 �?
**检查方�?*:
1. 打开开发者工�?(F12)
2. 切换�?Performance 标签
3. 刷新页面
4. 查看加载时间

**预期结果**:
- �?首屏加载 < 2 �?- �?完全加载 < 3 �?
---

### API 响应时间

**目标**: < 1 �?
**检查方�?*:
1. 打开开发者工�?(F12)
2. 切换�?Network 标签
3. 执行 API 调用
4. 查看响应时间

**预期结果**:
- �?大多数请�?< 500ms
- �?所有请�?< 1 �?
---

## 🐛 常见问题排查

### 问题 1: 应用无法加载

**症状**: 打开 http://localhost:3000 显示空白�?
**排查步骤**:
1. 检查前端服务是否运�? `npm start`
2. 查看浏览器控制台是否有错�?3. 检查网络连�?
**解决方案**:
- 重启前端服务
- 清除浏览器缓�?- 检查端口是否被占用

---

### 问题 2: API 返回 404

**症状**: 浏览器控制台显示 404 错误

**排查步骤**:
1. 检�?API 路径是否正确
2. 检查后端服务是否运�?3. 查看后端日志

**解决方案**:
- 检�?`frontend/src/services/api.ts` 中的 API 路径
- 重启后端服务
- 查看后端日志找出问题

---

### 问题 3: CORS 错误

**症状**: 浏览器控制台显示 CORS 错误

**排查步骤**:
1. 检查后�?CORS 配置
2. 检查前端地址是否在允许列表中
3. 查看后端日志

**解决方案**:
- 检�?`backend/media-service/main.py` 中的 CORS 配置
- 确保 `http://localhost:3000` 在允许列表中
- 重启后端服务

---

### 问题 4: 数据库连接失�?
**症状**: 后端日志显示数据库连接错�?
**排查步骤**:
1. 检�?Docker 容器是否运行
2. 检查数据库连接字符�?3. 检查数据库密码

**解决方案**:
- 启动 Docker 容器: `docker start mediagenie-postgres`
- 检�?`.env` 文件中的 DATABASE_URL
- 重启后端服务

---

## �?完成检查清�?
- [x] 所有服务都在运�?- [x] 后端健康检查通过
- [x] 前端应用正常加载
- [x] API 调用成功
- [x] 数据库连接正�?- [x] Marketplace Portal 正常
- [x] 没有关键错误
- [x] 性能满足要求

---

## 🎯 下一�?
### 立即可做

1. **完整的端到端测试**
   - 参�?`END_TO_END_TESTING.md`
   - 执行 8 个完整的测试场景

2. **执行 RLS 迁移**
   ```bash
   cd backend/media-service
   python run_rls_migration.py
   ```

3. **部署�?Azure**
   - 参�?`AZURE_DEPLOYMENT_GUIDE.md`

---

## 📞 需要帮助？

- 📖 查看 `FRONTEND_WARNINGS_ANALYSIS.md` - 警告分析
- 📚 查看 `LOCAL_DEVELOPMENT_COMPLETE.md` - 完整配置
- 🧪 查看 `END_TO_END_TESTING.md` - 完整测试指南

---

## 🎊 总结

�?**本地开发环境完全就绪！**

所有服务都正常运行，应用功能完全正常�?
现在就开始开发吧！🚀

