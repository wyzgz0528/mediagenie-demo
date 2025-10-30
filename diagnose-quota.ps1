# Azure App Service 配额问题诊断工具
# 检查配额、区域、订阅状态等

param(
    [string]$Location = "East US"
)

Write-Host "╔═══════════════════════════════════════════════════════════════�? -ForegroundColor Cyan
Write-Host "�?         Azure App Service 配额诊断工具                       �? -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════�? -ForegroundColor Cyan
Write-Host ""

# 1. 检查订阅状�?
Write-Host "━━�?1. 检查订阅状�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "�?订阅ID: $($account.id)" -ForegroundColor Green
    Write-Host "�?订阅�? $($account.name)" -ForegroundColor Green
    Write-Host "�?状�? $($account.state)" -ForegroundColor Green
    Write-Host "�?类型: $($account.user.type)" -ForegroundColor Green
    
    if ($account.state -ne "Enabled") {
        Write-Host "�?警告: 订阅状态不�?Enabled" -ForegroundColor Red
    }
} catch {
    Write-Host "�?无法获取订阅信息: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 2. 检查区域可用�?
Write-Host "━━�?2. 检查区域可用�?━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow
try {
    $locations = az account list-locations --query "[?displayName=='$Location' || name=='$Location'].{Name:name, DisplayName:displayName}" --output json | ConvertFrom-Json
    
    if ($locations.Count -gt 0) {
        foreach ($loc in $locations) {
            Write-Host "�?区域: $($loc.DisplayName) ($($loc.Name))" -ForegroundColor Green
        }
    } else {
        Write-Host "�?区域 '$Location' 不可�? -ForegroundColor Red
        Write-Host "可用区域:" -ForegroundColor Yellow
        az account list-locations --query "[].{Name:name, DisplayName:displayName}" --output table
    }
} catch {
    Write-Host "�?无法检查区�? $_" -ForegroundColor Red
}

Write-Host ""

# 3. 检�?App Service 配额
Write-Host "━━�?3. 检�?App Service 配额 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
try {
    Write-Host "检�?Microsoft.Web 资源提供程序..." -ForegroundColor White
    $webProvider = az provider show --namespace Microsoft.Web --query "registrationState" --output tsv
    Write-Host "Microsoft.Web 状�? $webProvider" -ForegroundColor Cyan
    
    if ($webProvider -ne "Registered") {
        Write-Host "�?Microsoft.Web 未注册，正在注册..." -ForegroundColor Yellow
        az provider register --namespace Microsoft.Web
        Write-Host "�?已触发注册，可能需要几分钟" -ForegroundColor Green
    }
    
    # 检查当前使用情�?
    Write-Host "检�?App Service 使用情况..." -ForegroundColor White
    $usage = az vm list-usage --location $Location --query "[?localName=='Basic A VMs' || localName=='Standard A VMs' || localName=='Total Regional vCPUs'].{Name:localName, Current:currentValue, Limit:limit}" --output json 2>$null | ConvertFrom-Json
    
    if ($usage) {
        Write-Host "配额使用情况:" -ForegroundColor Cyan
        foreach ($u in $usage) {
            $percent = if ($u.limit -gt 0) { [math]::Round(($u.current / $u.limit) * 100, 2) } else { 0 }
            Write-Host "  $($u.Name): $($u.current)/$($u.limit) (${percent}%)" -ForegroundColor White
            
            if ($percent -gt 80) {
                Write-Host "  ⚠️  接近配额限制" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠️  无法获取详细配额信息" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  配额检查失�? $_" -ForegroundColor Yellow
}

Write-Host ""

# 4. 检查现有资�?
Write-Host "━━�?4. 检查现�?App Service 资源 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�? -ForegroundColor Yellow
try {
    # 检�?App Service Plans
    Write-Host "检查现�?App Service Plans..." -ForegroundColor White
    $plans = az appservice plan list --query "[].{Name:name, ResourceGroup:resourceGroup, Sku:sku.name, Location:location}" --output json | ConvertFrom-Json
    
    if ($plans.Count -gt 0) {
        Write-Host "现有 App Service Plans:" -ForegroundColor Cyan
        foreach ($plan in $plans) {
            Write-Host "  📋 $($plan.Name) - $($plan.Sku) ($($plan.Location))" -ForegroundColor White
            Write-Host "      资源�? $($plan.ResourceGroup)" -ForegroundColor Gray
        }
        
        # 检查是否有相同区域�?Basic 计划
        $basicPlans = $plans | Where-Object { $_.Sku -like "B*" -and $_.Location -eq $Location }
        if ($basicPlans.Count -gt 0) {
            Write-Host "�?�?$Location 已有 Basic SKU 计划，可以复�? -ForegroundColor Green
        }
    } else {
        Write-Host "没有现有�?App Service Plans" -ForegroundColor Gray
    }
    
    # 检�?Web Apps
    Write-Host "检查现�?Web Apps..." -ForegroundColor White
    $webapps = az webapp list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output json | ConvertFrom-Json
    
    if ($webapps.Count -gt 0) {
        Write-Host "现有 Web Apps:" -ForegroundColor Cyan
        foreach ($app in $webapps) {
            Write-Host "  🌐 $($app.Name) ($($app.Location))" -ForegroundColor White
        }
    } else {
        Write-Host "没有现有�?Web Apps" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "⚠️  资源检查失�? $_" -ForegroundColor Yellow
}

Write-Host ""

# 5. 检测订阅类型限�?
Write-Host "━━�?5. 检测订阅类型和限制 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
try {
    $subscriptionId = (az account show --query id --output tsv)
    
    # 检查订阅类�?
    Write-Host "订阅ID: $subscriptionId" -ForegroundColor Cyan
    
    if ($subscriptionId -like "*-0000-*" -or $subscriptionId -like "*free*") {
        Write-Host "⚠️  检测到免费订阅特征" -ForegroundColor Yellow
        Write-Host "   免费订阅通常有严格的配额限制" -ForegroundColor Gray
    }
    
    # 检�?Resource Manager 模板部署历史
    Write-Host "检查最近的部署..." -ForegroundColor White
    $deployments = az deployment sub list --query "[?properties.provisioningState=='Failed'].{Name:name, Error:properties.error.message}" --output json 2>$null | ConvertFrom-Json
    
    if ($deployments -and $deployments.Count -gt 0) {
        Write-Host "最近失败的部署:" -ForegroundColor Yellow
        foreach ($dep in $deployments | Select-Object -First 3) {
            Write-Host "  �?$($dep.Name)" -ForegroundColor Red
            if ($dep.Error) {
                Write-Host "     错误: $($dep.Error)" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "⚠️  订阅类型检测失�? $_" -ForegroundColor Yellow
}

Write-Host ""

# 6. 建议解决方案
Write-Host "━━�?6. 解决方案建议 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 解决方案 A: 使用不同�?SKU" -ForegroundColor Green
Write-Host "   修改部署脚本，使�?F1 (免费) �?S1 (标准) 替代 B1" -ForegroundColor White
Write-Host "   F1: 免费但功能有�? -ForegroundColor Gray
Write-Host "   S1: 标准层，通常配额更充�? -ForegroundColor Gray
Write-Host ""

Write-Host "🔧 解决方案 B: 更换区域" -ForegroundColor Green
Write-Host "   尝试其他区域�? West US, West US 2, Central US" -ForegroundColor White
Write-Host "   某些区域的配额可能更充足" -ForegroundColor Gray
Write-Host ""

Write-Host "🔧 解决方案 C: 复用现有计划" -ForegroundColor Green
if ($basicPlans.Count -gt 0) {
    Write-Host "   复用现有�?Basic 计划: $($basicPlans[0].Name)" -ForegroundColor White
} else {
    Write-Host "   如果有其他资源组�?App Service Plan，可以复�? -ForegroundColor White
}
Write-Host ""

Write-Host "🔧 解决方案 D: 请求配额增加" -ForegroundColor Green
Write-Host "   Azure Portal > 订阅 > 使用情况+配额 > 请求增加" -ForegroundColor White
Write-Host "   通常需�?24-48 小时审批" -ForegroundColor Gray
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "💡 快速解�? 我将为你创建使用 F1/S1 SKU 的修复版部署脚本" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray