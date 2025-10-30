# MediaGenie 环境变量配置助手
# 运行此脚本生成环境变量配�?

Write-Host "=== MediaGenie 环境变量配置助手 ===" -ForegroundColor Green
Write-Host ""

# 提示用户输入必要信息
Write-Host "请提供以下Azure服务信息�? -ForegroundColor Yellow
Write-Host ""

$azureClientId = Read-Host "Azure AD 应用客户端ID"
$azureClientSecret = Read-Host "Azure AD 应用客户端密�?(输入将隐�?" -AsSecureString
$azureTenantId = Read-Host "Azure AD 租户ID"
$azureSubscriptionId = Read-Host "Azure 订阅ID"

$cognitiveKey = Read-Host "Azure 认知服务密钥 (输入将隐�?" -AsSecureString
$cognitiveEndpoint = Read-Host "Azure 认知服务端点 (例如: https://eastus.api.cognitive.microsoft.com/)"

$dbPassword = Read-Host "数据库管理员密码 (输入将隐�?" -AsSecureString
$dbHost = Read-Host "数据库主机名 (例如: mediagenie-demo-db.postgres.database.azure.com)"

$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# 转换安全字符�?
$azureClientSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($azureClientSecret))
$cognitiveKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($cognitiveKey))
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))

# 生成环境变量
Write-Host ""
Write-Host "=== 复制以下内容�?Azure App Service 环境变量 ===" -ForegroundColor Green
Write-Host ""

@"
ENVIRONMENT=demo
AZURE_CLIENT_ID=$azureClientId
AZURE_CLIENT_SECRET=$azureClientSecretPlain
AZURE_TENANT_ID=$azureTenantId
AZURE_SUBSCRIPTION_ID=$azureSubscriptionId
AZURE_COGNITIVE_SERVICES_KEY=$cognitiveKeyPlain
AZURE_COGNITIVE_SERVICES_ENDPOINT=$cognitiveEndpoint
DATABASE_URL=postgresql://mediagenie_admin:$dbPasswordPlain@$dbHost`:5432/mediagenie_demo?sslmode=require
JWT_SECRET_KEY=$jwtSecret
LOG_LEVEL=INFO
"@

Write-Host ""
Write-Host "=== 可选的 Marketplace 集成变量 (如果需�? ===" -ForegroundColor Cyan
Write-Host "AZURE_MARKETPLACE_CLIENT_ID=你的市场应用客户端ID" -ForegroundColor Gray
Write-Host "AZURE_MARKETPLACE_CLIENT_SECRET=你的市场应用客户端密�? -ForegroundColor Gray
Write-Host "AZURE_MARKETPLACE_TENANT_ID=你的市场租户ID" -ForegroundColor Gray

Write-Host ""
Write-Host "配置完成！请复制上述变量�?Azure App Service 的环境变量设置中�? -ForegroundColor Green