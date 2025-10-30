# 通过 Azure Portal 修复部署问题

## 问题原因
- Azure **没有自动安装** `requirements.txt` 中的依赖�?
- 应用启动时找不到 `requests` 等模�?
- 需要启�?Oryx 自动构建功能

## 🎯 解决步骤（通过 Portal�?

### 步骤 1: 打开应用配置

1. 访问: https://portal.azure.com
2. 导航: 资源�?�?**MediaGenie-RG** �?**mediagenie-marketplace**
3. 左侧菜单: **配置**

### 步骤 2: 添加应用程序设置

�?应用程序设置"选项卡中�?

1. 点击 **"+ 新建应用程序设置"**

2. 添加第一个设置：
   - **名称**: `SCM_DO_BUILD_DURING_DEPLOYMENT`
   - **�?*: `true`
   - 点击 **"确定"**

3. 再次点击 **"+ 新建应用程序设置"**

4. 添加第二个设置：
   - **名称**: `ENABLE_ORYX_BUILD`
   - **�?*: `true`
   - 点击 **"确定"**

5. 点击页面顶部�?**"保存"** 按钮

6. 确认保存（会提示重启应用�?

### 步骤 3: 重启应用

1. 返回 **mediagenie-marketplace** 概述�?
2. 点击顶部工具栏的 **"重启"** 按钮
3. 确认重启

### 步骤 4: 等待并验�?

1. 等待 **2-3 分钟**（首次构建需要时间）

2. 访问: https://mediagenie-marketplace.azurewebsites.net

3. 应该看到 **Landing Page**�?

### 步骤 5: 检查日志（如果还有问题�?

如果仍然失败�?

1. 左侧菜单: **监视** �?**日志�?*
2. 查看实时日志
3. 查找:
   - �?`Collecting Flask...` （正在安装依赖）
   - �?`Successfully installed Flask requests...` （安装成功）
   - �?任何红色错误

---

## 📋 快速链�?

- **应用配置**: https://portal.azure.com/#@/resource/subscriptions/3628daff-52ae-4f64-a310-28ad4b2158ca/resourceGroups/MediaGenie-RG/providers/Microsoft.Web/sites/mediagenie-marketplace/configuration
- **应用概述**: https://portal.azure.com/#@/resource/subscriptions/3628daff-52ae-4f64-a310-28ad4b2158ca/resourceGroups/MediaGenie-RG/providers/Microsoft.Web/sites/mediagenie-marketplace/appServices
- **日志�?*: https://portal.azure.com/#@/resource/subscriptions/3628daff-52ae-4f64-a310-28ad4b2158ca/resourceGroups/MediaGenie-RG/providers/Microsoft.Web/sites/mediagenie-marketplace/logStream

---

## ⚙️ 设置说明

### `SCM_DO_BUILD_DURING_DEPLOYMENT=true`
- 在部署时执行构建
- 自动检测并安装依赖

### `ENABLE_ORYX_BUILD=true`
- 启用 Oryx 构建系统
- 支持 Python、Node.js 等多种语言
- 自动处理 requirements.txt

---

## �?完成�?

配置生效后，Azure 会：
1. 检测到 `requirements.txt`
2. 自动运行 `pip install -r requirements.txt`
3. 安装 Flask、requests、Werkzeug、gunicorn �?
4. 启动应用

Landing Page 将正常显示！🎉
