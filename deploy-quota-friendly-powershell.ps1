# ============================================================================
# MediaGenie 配额友好部署脚本 (PowerShell �?
# 使用 F1 (免费) �?S1 (标准) SKU 避免 Basic VM 配额限制
# ============================================================================

param(
    [string]$ResourceGroup = "",
    [string]$Location = "East US"
)

Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "�?     MediaGenie 配额友好部署 (PowerShell)                          �? -ForegroundColor Cyan
Write-Host "�?     避免 Basic VM 配额限制                                        �? -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 配置 - 使用配额友好�?SKU
# ============================================================================
$timestamp = Get-Date -Format "MMddHHmm"
if ([string]::IsNullOrEmpty($ResourceGroup)) {
    $ResourceGroup = "mediagenie-rg-$timestamp"
}

$appNamePrefix = "mediagenie-$timestamp"

# SKU 配置 (避免 Basic VM 限制)
$frontendSku = "F1"  # 免费�?(不占�?Basic VM 配额)
$backendSku = "S1"   # 标准�?(通常配额更充�?

# App 名称
$frontendAppName = "$appNamePrefix-web"
$backendAppName = "$appNamePrefix-api"
$frontendPlanName = "$appNamePrefix-plan-web"
$backendPlanName = "$appNamePrefix-plan-api"

Write-Host "━━�?配置信息 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "资源�? $ResourceGroup" -ForegroundColor Cyan
Write-Host "区域: $Location" -ForegroundColor Cyan
Write-Host "前端SKU: $frontendSku (免费�?" -ForegroundColor Green
Write-Host "后端SKU: $backendSku (标准�?" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 1. 环境检�?
# ============================================================================
Write-Host "━━�?步骤 1: 环境检�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

# 检�?Azure CLI
try {
    $azVersion = az version --output tsv --query '"azure-cli"' 2>$null
    Write-Host "�?Azure CLI 版本: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "�?Azure CLI 未安�? -ForegroundColor Red
    exit 1
}

# 检查登录状�?
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "�?已登�? $($account.user.name)" -ForegroundColor Green
    Write-Host "�?订阅: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "�?未登�?Azure" -ForegroundColor Red
    exit 1
}

# 检查环境变�?
$requiredEnvs = @("AZURE_OPENAI_KEY", "AZURE_OPENAI_ENDPOINT", "AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION")
$missingEnvs = @()

foreach ($env in $requiredEnvs) {
    $value = [System.Environment]::GetEnvironmentVariable($env)
    if ([string]::IsNullOrEmpty($value)) {
        $missingEnvs += $env
        Write-Host "�?缺少: $env" -ForegroundColor Red
    } else {
        Write-Host "�?$env = $($value.Substring(0, [Math]::Min(20, $value.Length)))..." -ForegroundColor Green
    }
}

if ($missingEnvs.Count -gt 0) {
    Write-Host ""
    Write-Host "请设置环境变�?" -ForegroundColor Yellow
    foreach ($env in $missingEnvs) {
        Write-Host "  `$env:$env = 'your-value'" -ForegroundColor Gray
    }
    exit 1
}

Write-Host ""

# ============================================================================
# 2. 配额预检�?
# ============================================================================
Write-Host "━━�?步骤 2: 配额预检�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

# 检�?Microsoft.Web 提供程序
try {
    $webProvider = az provider show --namespace Microsoft.Web --query "registrationState" --output tsv
    Write-Host "Microsoft.Web 状�? $webProvider" -ForegroundColor Cyan
    
    if ($webProvider -ne "Registered") {
        Write-Host "⚠️  正在注册 Microsoft.Web..." -ForegroundColor Yellow
        az provider register --namespace Microsoft.Web
        Write-Host "�?已触发注�? -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  无法检查提供程序状�? -ForegroundColor Yellow
}

# 检查现有资�?
try {
    $existingPlans = az appservice plan list --query "[?location=='$Location' && (sku.tier=='Free' || sku.tier=='Standard')].{name:name, sku:sku.name}" --output json | ConvertFrom-Json
    
    if ($existingPlans.Count -gt 0) {
        Write-Host "💡 发现现有可用 App Service Plans:" -ForegroundColor Cyan
        foreach ($plan in $existingPlans) {
            Write-Host "  $($plan.name) - $($plan.sku)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "⚠️  无法检查现有资�? -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# 3. 资源组管�?
# ============================================================================
Write-Host "━━�?步骤 3: 资源组管�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

$rgExists = az group exists --name $ResourceGroup --output tsv
if ($rgExists -eq "true") {
    Write-Host "�?资源组已存在: $ResourceGroup" -ForegroundColor Green
} else {
    Write-Host "创建资源�? $ResourceGroup" -ForegroundColor White
    az group create --name $ResourceGroup --location $Location --output table
    if ($LASTEXITCODE -eq 0) {
        Write-Host "�?资源组创建成�? -ForegroundColor Green
    } else {
        Write-Host "�?资源组创建失�? -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# ============================================================================
# 4. 创建前端 App Service Plan (免费�?
# ============================================================================
Write-Host "━━�?步骤 4: 创建前端 App Service Plan (免费�? ━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

Write-Host "💡 使用 $frontendSku SKU (免费层，不占�?Basic VM 配额)" -ForegroundColor Cyan

try {
    az appservice plan show --name $frontendPlanName --resource-group $ResourceGroup --output none 2>$null
    Write-Host "�?前端 App Service Plan 已存�? -ForegroundColor Green
} catch {
    Write-Host "创建前端 App Service Plan..." -ForegroundColor White
    az appservice plan create `
        --name $frontendPlanName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku $frontendSku `
        --is-linux `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "�?前端 App Service Plan 创建成功 (SKU: $frontendSku)" -ForegroundColor Green
    } else {
        Write-Host "�?前端 App Service Plan 创建失败" -ForegroundColor Red
        Write-Host "⚠️  尝试其他区域..." -ForegroundColor Yellow
        
        # 备选区�?
        $altLocations = @("West US", "Central US", "West US 2")
        $success = $false
        
        foreach ($altLocation in $altLocations) {
            Write-Host "尝试区域: $altLocation" -ForegroundColor Cyan
            az appservice plan create `
                --name $frontendPlanName `
                --resource-group $ResourceGroup `
                --location $altLocation `
                --sku $frontendSku `
                --is-linux `
                --output table
                
            if ($LASTEXITCODE -eq 0) {
                Write-Host "�?�?$altLocation 创建成功" -ForegroundColor Green
                $Location = $altLocation
                $success = $true
                break
            }
        }
        
        if (-not $success) {
            Write-Host "�?所有区域都失败" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""

# ============================================================================
# 5. 创建后端 App Service Plan (标准�?
# ============================================================================
Write-Host "━━�?步骤 5: 创建后端 App Service Plan (标准�? ━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

Write-Host "💡 使用 $backendSku SKU (标准层，通常配额更充�?" -ForegroundColor Cyan

try {
    az appservice plan show --name $backendPlanName --resource-group $ResourceGroup --output none 2>$null
    Write-Host "�?后端 App Service Plan 已存�? -ForegroundColor Green
} catch {
    Write-Host "创建后端 App Service Plan..." -ForegroundColor White
    az appservice plan create `
        --name $backendPlanName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku $backendSku `
        --is-linux `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "�?后端 App Service Plan 创建成功 (SKU: $backendSku)" -ForegroundColor Green
    } else {
        Write-Host "�?后端 App Service Plan 创建失败" -ForegroundColor Red
        Write-Host "⚠️  尝试降级�?F1..." -ForegroundColor Yellow
        
        # 备选方�? 降级到免费层
        $backendSku = "F1"
        az appservice plan create `
            --name $backendPlanName `
            --resource-group $ResourceGroup `
            --location $Location `
            --sku $backendSku `
            --is-linux `
            --output table
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "�?使用 F1 SKU 创建成功" -ForegroundColor Green
        } else {
            Write-Host "�?所�?SKU 都失�? -ForegroundColor Red
            Write-Host "💡 建议: 更换订阅或请求配额增�? -ForegroundColor Yellow
            exit 1
        }
    }
}

Write-Host ""

# ============================================================================
# 6-8. 继续其余步骤 (与原版相�?
# ============================================================================
Write-Host "━━�?步骤 6: 创建前端 Web App ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

try {
    az webapp show --name $frontendAppName --resource-group $ResourceGroup --output none 2>$null
    Write-Host "�?前端 Web App 已存�? -ForegroundColor Green
} catch {
    az webapp create `
        --name $frontendAppName `
        --resource-group $ResourceGroup `
        --plan $frontendPlanName `
        --runtime "NODE:18-lts" `
        --output table
    Write-Host "�?前端 Web App 创建成功" -ForegroundColor Green
}

Write-Host ""
Write-Host "━━�?步骤 7: 创建后端 Web App ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

try {
    az webapp show --name $backendAppName --resource-group $ResourceGroup --output none 2>$null
    Write-Host "�?后端 Web App 已存�? -ForegroundColor Green
} catch {
    az webapp create `
        --name $backendAppName `
        --resource-group $ResourceGroup `
        --plan $backendPlanName `
        --runtime "PYTHON:3.10" `
        --output table
    Write-Host "�?后端 Web App 创建成功" -ForegroundColor Green
}

# 其余步骤 (环境变量、部署等) 与原版相�?..
Write-Host ""
Write-Host "━━�?步骤 8: 配置后端环境变量 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

az webapp config appsettings set `
    --name $backendAppName `
    --resource-group $ResourceGroup `
    --settings `
        AZURE_OPENAI_KEY="$env:AZURE_OPENAI_KEY" `
        AZURE_OPENAI_ENDPOINT="$env:AZURE_OPENAI_ENDPOINT" `
        AZURE_SPEECH_KEY="$env:AZURE_SPEECH_KEY" `
        AZURE_SPEECH_REGION="$env:AZURE_SPEECH_REGION" `
        PYTHONPATH="/home/site/wwwroot" `
    --output table

Write-Host "�?后端环境变量配置完成" -ForegroundColor Green

Write-Host ""
Write-Host "━━�?步骤 9: 部署后端代码 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow

# 后续步骤继续使用 bash 脚本
Write-Host "💡 切换�?bash 完成剩余部署..." -ForegroundColor Cyan
bash ./deploy-quota-friendly.sh

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "�?PowerShell 部分完成！避免了 Basic VM 配额限制�? -ForegroundColor Green
Write-Host "🎯 使用了配额友好的 SKU:" -ForegroundColor Yellow
Write-Host "   �?前端: $frontendSku (免费�?" -ForegroundColor White
Write-Host "   �?后端: $backendSku ($(if ($backendSku -eq 'F1') { '免费�? } else { '标准�? }))" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray