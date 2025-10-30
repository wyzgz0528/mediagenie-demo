# 🔧 Azure 应用设置配置指南

**日期**: 2025-10-27

---

## 📍 如何找到应用设置

在你当前�?Azure Portal 界面中，我看到左侧菜单有很多选项。应用设置在这里�?
### 方法 1: 通过左侧菜单 (推荐)

1. **打开 mediagenie-backend Web App**
   - �?Azure Portal 中搜�?"mediagenie-backend"
   - 点击打开

2. **在左侧菜单中找到 "配置"**
   - 左侧菜单向下滚动
   - 找到 "设置" 部分
   - 点击 **"配置"** (Configuration)

3. **在配置页面中**
   - 你会看到几个标签�? "常规设置", "高级编辑", "诊断设置(预览)"
   - 点击 **"常规设置"** 标签�?
4. **在常规设置中找到应用设置**
   - 向下滚动
   - 找到 **"应用设置"** 部分
   - 点击 **"新应用设�?** 按钮

---

## 📝 添加应用设置

### 对于后端 (mediagenie-backend)

1. 点击 **"新应用设�?**
2. 在弹出的对话框中填写:

   **�?1 个设�?*:
   ```
   名称: DATABASE_URL
   �? postgresql+asyncpg://dbadmin:PASSWORD@mediagenie-db-XXXX.postgres.database.azure.com:5432/mediagenie
   ```
   (�?PASSWORD �?XXXX 替换为你的实际�?

   **�?2 个设�?*:
   ```
   名称: ENVIRONMENT
   �? production
   ```

   **�?3 个设�?*:
   ```
   名称: DEBUG
   �? false
   ```

3. 每添加一个设置后，点�?**"确定"**

4. 所有设置添加完成后，点击页面顶部的 **"保存"** 按钮

---

### 对于前端 (mediagenie-frontend)

1. 打开 mediagenie-frontend Web App
2. 重复上述步骤
3. 添加以下设置:

   **�?1 个设�?*:
   ```
   名称: REACT_APP_MEDIA_SERVICE_URL
   �? https://mediagenie-backend.azurewebsites.net
   ```

   **�?2 个设�?*:
   ```
   名称: REACT_APP_ENV
   �? production
   ```

4. 点击 **"保存"**

---

## 🔍 如果找不到应用设�?
如果你在 "配置" 页面中找不到 "应用设置"，可能是因为:

1. **页面还在加载** - 等待几秒�?2. **需要向下滚�?* - 向下滚动页面
3. **在不同的标签�?* - 确保你在 "常规设置" 标签�?
### 替代方法: 使用高级编辑

1. 打开 "配置" 页面
2. 点击 **"高级编辑"** 标签�?3. 你会看到一�?JSON 编辑�?4. �?JSON 中添加你的设�?

```json
[
  {
    "name": "DATABASE_URL",
    "value": "postgresql+asyncpg://dbadmin:PASSWORD@mediagenie-db-XXXX.postgres.database.azure.com:5432/mediagenie",
    "slotSetting": false
  },
  {
    "name": "ENVIRONMENT",
    "value": "production",
    "slotSetting": false
  },
  {
    "name": "DEBUG",
    "value": "false",
    "slotSetting": false
  }
]
```

5. 点击 **"保存"**

---

## 💾 获取数据库连接信�?
### �?Azure Portal 获取数据库信�?
1. �?Azure Portal 中搜�?"mediagenie-db-XXXX"
2. 打开你的 PostgreSQL 数据�?3. 在左侧菜单中找到 **"连接字符�?** �?**"概述"**
4. 你会看到:
   ```
   服务器名�? mediagenie-db-XXXX.postgres.database.azure.com
   管理员用户名: dbadmin
   管理员密�? [你创建时设置的密码]
   ```

5. 构建连接字符�?
   ```
   postgresql+asyncpg://dbadmin:PASSWORD@mediagenie-db-XXXX.postgres.database.azure.com:5432/mediagenie
   ```

---

## �?验证设置

### 检查应用设置是否已保存

1. 打开 Web App �?"配置" 页面
2. �?"应用设置" 部分中应该能看到你添加的所有设�?3. 如果看到了，说明设置已成功保�?
### 重启应用

1. �?Web App 的概述页面中
2. 点击 **"重启"** 按钮
3. 等待应用重启 (通常需�?1-2 分钟)

---

## 🚀 下一�?
配置完应用设置后:

1. �?VSCode 中部署后端代�?2. �?VSCode 中部署前端代�?3. 验证应用是否正常运行

---

## 📞 常见问题

### Q: 我找不到 "配置" 选项

**A**: 
- 确保你打开的是 Web App (不是资源组或其他资源)
- 在左侧菜单中向下滚动
- 找到 "设置" 部分
- 点击 "配置"

### Q: 应用设置保存后没有生�?
**A**:
- 重启 Web App
- 等待 1-2 分钟
- 刷新浏览�?
### Q: 我不知道数据库密�?
**A**:
- �?Azure Portal 中打开你的 PostgreSQL 数据�?- 在左侧菜单中找到 "重置密码"
- 设置新密�?
---

**现在就去配置应用设置吧！** 🚀

