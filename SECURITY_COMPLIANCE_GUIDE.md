# 🔐 Azure Marketplace 安全合规指南

## 📋 Azure Marketplace 安全要求

### �?必须遵循的安全规�?

根据 [Azure Marketplace 认证策略](https://docs.microsoft.com/azure/marketplace/certification-policies),以下�?*强制性安全要�?*:

1. **�?禁止硬编码密�?*
   - 不能在代码、脚本或配置文件中包含明文密�?
   - 不能�?GitHub 等公共仓库中暴露密钥

2. **�?使用安全的密钥管�?*
   - Azure Key Vault (推荐)
   - ARM 模板 `securestring` 参数
   - 环境变量 (仅运行时)

3. **�?HTTPS Only**
   - 所�?Web 应用必须强制 HTTPS
   - TLS 1.2 或更高版�?

4. **�?最小权限原�?*
   - 每个组件只能访问必需的资�?
   - 使用托管身份 (Managed Identity) 代替密钥

5. **�?审计和监�?*
   - 启用日志记录
   - 集成 Application Insights (推荐)

---

## 🔑 密钥管理最佳实�?

### 方式 1: Azure Key Vault (生产推荐)

#### 步骤 1: 创建 Key Vault

```bash
# 创建 Key Vault
az keyvault create \
  --name mediagenie-kv-$(date +%s) \
  --resource-group MediaGenie-Marketplace-RG \
  --location eastus \
  --enable-rbac-authorization false

# 获取 Key Vault ID
KEYVAULT_NAME="your-keyvault-name"
KEYVAULT_ID=$(az keyvault show --name $KEYVAULT_NAME --query id -o tsv)
```

#### 步骤 2: 存储密钥�?Key Vault

```bash
# 存储 OpenAI 密钥
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name AzureOpenAIKey \
  --value "your-openai-key"

# 存储 Speech 密钥
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name AzureSpeechKey \
  --value "your-speech-key"

# 存储端点
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name AzureOpenAIEndpoint \
  --value "https://your-openai.openai.azure.com/"
```

#### 步骤 3: 配置 Web App 使用 Key Vault

```bash
# �?Web App 启用托管身份
az webapp identity assign \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG

# 获取 Web App 的身�?ID
PRINCIPAL_ID=$(az webapp identity show \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --query principalId -o tsv)

# 授予 Web App 访问 Key Vault 的权�?
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

#### 步骤 4: �?Web App 中引�?Key Vault

```bash
# 配置应用设置引用 Key Vault
az webapp config appsettings set \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG \
  --settings \
    AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/AzureOpenAIKey/)" \
    AZURE_SPEECH_KEY="@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/AzureSpeechKey/)" \
    AZURE_OPENAI_ENDPOINT="@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/AzureOpenAIEndpoint/)"
```

---

### 方式 2: ARM 模板参数 (Marketplace 推荐)

我已经为你创建了 `azuredeploy-marketplace.json`,它使�?`securestring` 参数:

#### 使用 ARM 模板部署

```bash
# 创建资源�?
az group create \
  --name MediaGenie-Marketplace-RG \
  --location eastus

# 部署模板 (交互式输入密�?
az deployment group create \
  --resource-group MediaGenie-Marketplace-RG \
  --template-file azuredeploy-marketplace.json \
  --parameters \
    azureOpenAIKey="your-openai-key" \
    azureOpenAIEndpoint="https://your-openai.openai.azure.com/" \
    azureSpeechKey="your-speech-key" \
    azureSpeechRegion="eastus"
```

#### 使用参数文件 + Key Vault 引用

编辑 `azuredeploy-marketplace.parameters.json`:

```json
{
  "azureOpenAIKey": {
    "reference": {
      "keyVault": {
        "id": "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault-name}"
      },
      "secretName": "AzureOpenAIKey"
    }
  }
}
```

然后部署:

```bash
az deployment group create \
  --resource-group MediaGenie-Marketplace-RG \
  --template-file azuredeploy-marketplace.json \
  --parameters @azuredeploy-marketplace.parameters.json
```

---

### 方式 3: 环境变量 (仅用于本地测�?

**⚠️ 注意**: 此方式仅用于开�?测试,不符�?Marketplace 生产要求�?

#### 使用 .env 文件

```bash
# �?.env 文件加载密钥
export $(cat backend/media-service/.env | xargs)

# 执行部署脚本
./deploy-marketplace-complete.sh
```

#### 修改后的部署脚本

新版本的 `deploy-marketplace-complete.sh` 已支�?
1. 从环境变量读取密�?
2. 交互式输入密�?
3. 不再硬编码密�?

---

## 🛡�?安全检查清�?

### 部署前检�?

- [ ] **密钥管理**
  - [ ] 已从脚本中移除所有硬编码密钥
  - [ ] 使用 Key Vault �?securestring 参数
  - [ ] .env 文件已添加到 .gitignore

- [ ] **网络安全**
  - [ ] 启用 HTTPS Only
  - [ ] TLS 1.2+
  - [ ] 禁用 FTP (使用 FTPS)

- [ ] **访问控制**
  - [ ] CORS 仅允许特定域�?
  - [ ] 配置托管身份 (Managed Identity)
  - [ ] 最小权限原�?

- [ ] **监控和日�?*
  - [ ] 启用 Application Insights (可�?
  - [ ] 配置日志保留策略
  - [ ] 启用诊断日志

### 部署后验�?

- [ ] **安全扫描**
  ```bash
  # 检�?HTTPS
  curl -I https://mediagenie-api-xxxxxx.azurewebsites.net
  
  # 验证 TLS 版本
  openssl s_client -connect mediagenie-api-xxxxxx.azurewebsites.net:443 -tls1_2
  ```

- [ ] **密钥保护**
  ```bash
  # 确认密钥未暴露在响应�?
  curl https://mediagenie-api-xxxxxx.azurewebsites.net/health
  ```

- [ ] **CORS 配置**
  ```bash
  # 测试 CORS 策略
  curl -H "Origin: https://unauthorized-site.com" \
       -H "Access-Control-Request-Method: POST" \
       -X OPTIONS \
       https://mediagenie-api-xxxxxx.azurewebsites.net/api/speech/text-to-speech
  ```

---

## 📝 .gitignore 配置

确保敏感信息不会提交到版本控�?

```gitignore
# 环境变量和密�?
.env
.env.local
.env.production
*.env

# Azure 部署配置
azuredeploy.parameters.json
*-parameters.json
deployment-secrets.json

# 密钥文件
*.key
*.pem
secrets/
credentials/

# Python
__pycache__/
*.pyc

# Node.js
node_modules/
npm-debug.log
```

---

## 🔄 密钥轮换策略

### 为什么需要轮换密�?

1. **安全合规**: Azure Marketplace 要求定期更新密钥
2. **降低风险**: 减少密钥泄露的影�?
3. **审计要求**: 满足企业安全政策

### 轮换步骤

#### 1. �?Azure Portal 生成新密�?

```bash
# OpenAI 服务
# Portal �?Azure OpenAI �?Keys �?Regenerate Key 2

# Speech 服务
# Portal �?Speech Services �?Keys �?Regenerate Key 2
```

#### 2. 更新 Key Vault 中的密钥

```bash
# 更新 OpenAI 密钥
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name AzureOpenAIKey \
  --value "new-openai-key"

# 更新 Speech 密钥
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name AzureSpeechKey \
  --value "new-speech-key"
```

#### 3. 重启 Web App (自动获取新密�?

```bash
az webapp restart \
  --name mediagenie-api-xxxxxx \
  --resource-group MediaGenie-Marketplace-RG
```

#### 4. 验证新密钥工作正�?

```bash
# 测试健康检�?
curl https://mediagenie-api-xxxxxx.azurewebsites.net/health

# 测试功能
curl -X POST https://mediagenie-api-xxxxxx.azurewebsites.net/api/speech/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{"text":"测试","voice":"zh-CN-XiaoxiaoNeural"}'
```

---

## 🚨 应急响�?

### 密钥泄露处理流程

如果密钥意外泄露:

1. **立即轮换密钥**
   ```bash
   # �?Azure Portal 立即重新生成密钥
   # 使用 Key 2,保持 Key 1 活跃
   ```

2. **更新所有引�?*
   ```bash
   # 更新 Key Vault
   # 重启所�?Web App
   ```

3. **审计访问日志**
   ```bash
   # 检查异常访�?
   az monitor activity-log list \
     --resource-group MediaGenie-Marketplace-RG \
     --start-time 2025-10-20T00:00:00Z
   ```

4. **通知相关�?*
   - 报告安全团队
   - 更新文档
   - 审查安全策略

---

## 📊 成本优化

### Key Vault 成本

| 操作类型 | 价格 (USD) |
|---------|-----------|
| Standard Vault | $0.03/10,000 操作 |
| Premium Vault (HSM) | $1.00/10,000 操作 |
| 存储的密�?| 免费 (�?10,000 �? |

**预估月成�?*: �?$1-5 (小型应用)

---

## 🔗 相关文档

- [Azure Marketplace 认证策略](https://docs.microsoft.com/azure/marketplace/certification-policies)
- [Azure Key Vault 最佳实践](https://docs.microsoft.com/azure/key-vault/general/best-practices)
- [托管身份文档](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)
- [App Service 安全最佳实践](https://docs.microsoft.com/azure/app-service/security-recommendations)

---

## �?合规认证检�?

在提交到 Azure Marketplace 之前,确保:

- [ ] 所有密钥存储在 Key Vault 或使�?securestring
- [ ] 启用 HTTPS Only �?TLS 1.2+
- [ ] 禁用明文 FTP
- [ ] 配置 CORS 限制
- [ ] 实施日志记录和监�?
- [ ] 文档包含密钥管理说明
- [ ] 通过自动化安全扫�?
- [ ] 提供密钥轮换流程文档

---

**🔐 安全第一! 严格遵循这些规范以通过 Azure Marketplace 认证�?*
