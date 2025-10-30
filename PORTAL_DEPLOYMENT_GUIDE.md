# MediaGenie Azure Portal 手动部署指南

由于 Azure CLI 遇到�?"The content for this response was already consumed" 错误�?
建议通过 Azure Portal 手动部署�?

## 方法 1：使�?Azure Portal 自定义部署（推荐�?

### 步骤�?

1. **登录 Azure Portal**
   访问：https://portal.azure.com

2. **创建自定义部�?*
   - 在搜索栏输入 "Deploy a custom template"
   - 或直接访问：https://portal.azure.com/#create/Microsoft.Template

3. **构建自己的模�?*
   - 点击 "Build your own template in the editor"
   - 复制 `arm-templates/azuredeploy-v2.json` 的内�?
   - 粘贴到编辑器
   - 点击 "Save"

4. **配置参数**
   - 订阅: 选择您的订阅 (intellnet001)
   - 资源�? 选择 "MediaGenie-RG"
   - 区域: East US
   - App Name Prefix: mediagenie
   - SKU: B1

5. **审阅并创�?*
   - 点击 "Review + create"
   - 检查配置无误后点击 "Create"
   - 等待部署完成（约 3-5 分钟�?

6. **获取输出**
   部署完成后，在部署页面查�?"Outputs" 标签�?
   - landingPageUrl
   - webhookUrl
   - frontendUrl

---

## 方法 2：使�?Azure CLI（命令行修复�?

如果您想继续使用 CLI，请尝试以下修复�?

### 选项 A：升�?Azure CLI

```powershell
# 下载最新版�?
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
rm .\AzureCLI.msi

# 重新登录
az login
```

### 选项 B：使�?Cloud Shell

1. 访问：https://shell.azure.com
2. 选择 "Bash"
3. 上传 `azuredeploy-v2.json` 文件
4. 运行�?

```bash
az deployment group create \
  --resource-group MediaGenie-RG \
  --name mediagenie-deploy \
  --template-file azuredeploy-v2.json \
  --parameters appNamePrefix=mediagenie sku=B1
```

---

## 方法 3：使用简化的 Azure CLI 命令（基于官方文档）

参考官方文档，使用在线模板�?

```powershell
# 部署 Marketplace Portal
az deployment group create `
  --resource-group MediaGenie-RG `
  --parameters webAppName="mediagenie-marketplace" linuxFxVersion="PYTHON|3.11" `
  --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.web/app-service-docs-linux/azuredeploy.json"

# 部署 Backend API
az deployment group create `
  --resource-group MediaGenie-RG `
  --parameters webAppName="mediagenie-backend" linuxFxVersion="PYTHON|3.11" `
  --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.web/app-service-docs-linux/azuredeploy.json"
```

---

## 部署成功后的下一�?

完成部署后，您需要：

1. **部署代码�?Marketplace Portal**
```powershell
cd marketplace-portal
Compress-Archive -Path * -DestinationPath ../marketplace-portal.zip -Force
az webapp deployment source config-zip `
  --resource-group MediaGenie-RG `
  --name <marketplace-app-name> `
  --src ../marketplace-portal.zip
```

2. **部署代码�?Backend API**
```powershell
cd backend\media-service
Compress-Archive -Path * -DestinationPath ..\..\backend-api.zip -Force
az webapp deployment source config-zip `
  --resource-group MediaGenie-RG `
  --name <backend-app-name> `
  --src ..\..\backend-api.zip
```

3. **获取 URL 并提交到 Azure Marketplace**
   - Landing Page URL: `https://<marketplace-app-name>.azurewebsites.net`
   - Webhook URL: `https://<backend-app-name>.azurewebsites.net/api/marketplace/webhook`

---

## 推荐：使�?Azure Portal（最简单）

�?**强烈建议使用方法 1（Azure Portal 自定义部署）**

优点�?
- 可视化界面，易于操作
- 不受 CLI 版本问题影响
- 可以实时查看部署进度
- 错误信息更清�?

访问：https://portal.azure.com/#create/Microsoft.Template
然后复制 azuredeploy-v2.json 的内容即可！
