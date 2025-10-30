# MediaGenie 部署�?WYZ 订阅 - 完整指南

## 问题说明
本地 Azure CLI 存在已知 bug: "The content for this response was already consumed"，无法完�?ARM 模板部署�?

## 解决方案：使�?Azure Cloud Shell 部署

Azure Cloud Shell 是微软提供的基于浏览器的命令行工具，不受本地 CLI bug 影响�?

---

## 部署步骤（推荐方法）

### 方法 1: Azure Cloud Shell 部署（最简单）

#### 步骤 1: 打开 Azure Cloud Shell
1. 访问: https://shell.azure.com
2. 使用您的 Azure 账号登录
3. 选择 **Bash** 环境

#### 步骤 2: 上传 ARM 模板
1. 点击 Cloud Shell 工具栏的 **上传/下载文件** 按钮（向上箭头图标）
2. 选择 **上传**
3. 上传文件: `F:\project\MediaGenie1001\arm-templates\azuredeploy-v2.json`
4. 文件会上传到 Cloud Shell 的当前目录（通常�?`~/`)

#### 步骤 3: 上传部署脚本（可选）
上传文件: `F:\project\MediaGenie1001\deploy-cloudshell-wyz.sh`

#### 步骤 4: 运行部署命令
�?Cloud Shell 中运行以下命令：

```bash
# 确认当前订阅
az account show --query "{Name:name, ID:id}" -o table

# 如果不是 WYZ，切换订�?
az account set --subscription "WYZ"

# 创建资源组（如果已存在会显示警告但不影响�?
az group create --name MediaGenie-RG --location eastus

# 部署 ARM 模板
az deployment group create \
  --resource-group MediaGenie-RG \
  --name mediagenie-deployment \
  --template-file azuredeploy-v2.json \
  --parameters appNamePrefix=mediagenie location=eastus sku=B1
```

#### 步骤 5: 等待部署完成
- 部署通常需�?3-5 分钟
- 等待命令执行完成，会显示部署详情

#### 步骤 6: 获取部署输出（重要！�?
```bash
az deployment group show \
  --resource-group MediaGenie-RG \
  --name mediagenie-deployment \
  --query "properties.outputs" \
  --output json
```

这会返回�?
- `landingPageUrl`: Landing Page URL（用�?Marketplace�?
- `webhookUrl`: Webhook URL（用�?Marketplace�?
- `marketplaceAppName`: Marketplace Portal 应用名称
- `backendAppName`: Backend API 应用名称
- `storageAccountName`: 存储账户名称
- `frontendUrl`: Frontend 静态网�?URL

**请保存这些输出信息！**

---

### 方法 2: Azure Portal 部署（图形界面）

如果您更喜欢使用图形界面�?

#### 步骤 1: 打开 Azure Portal
访问: https://portal.azure.com

#### 步骤 2: 切换�?WYZ 订阅
1. 点击右上角账�?
2. 确认当前目录�?"深圳智网同盛科技有限公司"
3. 点击顶部搜索栏，输入 "订阅"
4. 选择 **WYZ** 订阅

#### 步骤 3: 进入资源�?
1. �?WYZ 订阅页面，点击左�?"资源�?
2. 找到并点�?**MediaGenie-RG**（如果不存在，先创建它）

#### 步骤 4: 部署自定义模�?
1. 在资源组页面，点击顶�?**+ 创建**
2. 搜索 "Template deployment"
3. 选择 **"Template deployment (deploy using custom templates)"**
4. 点击 **"创建"**

#### 步骤 5: 构建自定义模�?
1. 点击 **"在编辑器中生成自己的模板"**
2. 删除默认内容
3. 复制 `F:\project\MediaGenie1001\arm-templates\azuredeploy-v2.json` 的完整内�?
4. 粘贴到编辑器�?
5. 点击 **"保存"**

#### 步骤 6: 配置参数
- **订阅**: WYZ
- **资源�?*: MediaGenie-RG
- **区域**: East US
- **App Name Prefix**: mediagenie
- **Location**: eastus
- **Sku**: B1

#### 步骤 7: 审阅并创�?
1. 点击 **"审阅 + 创建"**
2. 等待验证通过
3. 点击 **"创建"**

#### 步骤 8: 查看部署输出
1. 部署完成后，点击 **"转到部署"**
2. 点击 **"输出"** 选项�?
3. 记录所有输出值（特别�?landingPageUrl �?webhookUrl�?

---

## 部署后的资源

部署完成后，�?**MediaGenie-RG** 资源组中会创建以下资源：

1. **App Service Plan** (Linux, B1)
   - 名称: `mediagenie-plan-<uniqueSuffix>`
   
2. **Marketplace Portal** (App Service)
   - 名称: `mediagenie-marketplace-<uniqueSuffix>`
   - URL: `https://mediagenie-marketplace-<uniqueSuffix>.azurewebsites.net`
   - **这是您的 Landing Page URL**

3. **Backend API** (App Service)
   - 名称: `mediagenie-backend-<uniqueSuffix>`
   - URL: `https://mediagenie-backend-<uniqueSuffix>.azurewebsites.net`
   - Webhook: `https://mediagenie-backend-<uniqueSuffix>.azurewebsites.net/api/marketplace/webhook`
   - **这是您的 Webhook URL**

4. **Storage Account**
   - 名称: `mediageniesa<uniqueSuffix>`
   - 静态网�?URL: `https://mediageniesa<uniqueSuffix>.z13.web.core.windows.net`
   - **这是 Frontend �?URL**

---

## 下一步：部署应用代码

ARM 模板只创建了基础设施，还需要部署应用代码�?

### 部署 Marketplace Portal
```bash
cd marketplace-portal
zip -r ../marketplace-portal.zip .
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name <marketplace-app-name> \
  --src ../marketplace-portal.zip
```

### 部署 Backend API
```bash
cd backend/media-service
zip -r ../../backend-api.zip .
az webapp deployment source config-zip \
  --resource-group MediaGenie-RG \
  --name <backend-app-name> \
  --src ../../backend-api.zip
```

### 部署 Frontend
```bash
cd frontend
npm install
REACT_APP_MEDIA_SERVICE_URL=https://<backend-app-name>.azurewebsites.net npm run build
az storage blob upload-batch \
  --account-name <storage-account-name> \
  --destination '$web' \
  --source build/ \
  --overwrite
```

---

## 验证部署

1. **Landing Page**: 访问 `https://<marketplace-app-name>.azurewebsites.net`
2. **Backend Health**: 访问 `https://<backend-app-name>.azurewebsites.net/health`
3. **Backend Docs**: 访问 `https://<backend-app-name>.azurewebsites.net/docs`
4. **Frontend**: 访问 `https://<storage-account-name>.z13.web.core.windows.net`

---

## 故障排查

### 如果部署失败
�?Cloud Shell �?Portal 中查看部署详情：
```bash
az deployment group show \
  --resource-group MediaGenie-RG \
  --name mediagenie-deployment \
  --query "properties.error" \
  --output json
```

### 如果应用无法启动
查看应用日志�?
```bash
az webapp log tail \
  --resource-group MediaGenie-RG \
  --name <app-name>
```

---

## 联系信息

- 资源�? MediaGenie-RG
- 订阅: WYZ (3628daff-52ae-4f64-a310-28ad4b2158ca)
- 区域: East US
- ARM 模板: arm-templates/azuredeploy-v2.json
