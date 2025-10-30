param(
    [string]$ResourceGroup = "MediaGenie-RG",
    [string]$WebAppName = "mediagenie-marketplace",
    [string]$PythonExecutable = "python",
    [string]$OutputZip = "portal-build.zip",
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Message,
        [ScriptBlock]$Action
    )

    Write-Host "[+] $Message" -ForegroundColor Cyan
    & $Action
}

function Resolve-PortalPath {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $portalPath = Join-Path $scriptDir "marketplace-portal"
    if (-not (Test-Path $portalPath)) {
        throw "Cannot locate marketplace-portal directory at $portalPath"
    }
    return $portalPath
}

$originalLocation = Get-Location
$portalRoot = Resolve-PortalPath

Invoke-Step "Locating marketplace-portal" {
    Push-Location $portalRoot
}

Invoke-Step "Preparing clean local build folders" {
    if (Test-Path ".python_packages") {
        Remove-Item ".python_packages" -Recurse -Force
    }
    if (Test-Path ".venv") {
        Remove-Item ".venv" -Recurse -Force
    }

    & $PythonExecutable -m venv ".venv"
}

$venvPython = Join-Path ".venv" "Scripts/python.exe"
if (-not (Test-Path $venvPython)) {
    throw "Virtual environment was not created successfully. Expected path: $venvPython"
}

Invoke-Step "Installing requirements into .python_packages" {
    New-Item -ItemType Directory -Path ".python_packages/lib/site-packages" -Force | Out-Null
    & $venvPython -m pip install --upgrade pip
    & $venvPython -m pip install -r "requirements.txt" --target ".python_packages/lib/site-packages"
}

Invoke-Step "Creating deployment archive" {
    $zipPath = if ([System.IO.Path]::IsPathRooted($OutputZip)) { 
        $OutputZip 
    } else { 
        Join-Path (Split-Path -Parent $portalRoot) $OutputZip 
    }
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    $exclude = @('.venv', '.git', '.github', '__pycache__', 'logs')
    
    # 直接从当前目录打包，确保文件�?ZIP 根目�?
    $filesToZip = Get-ChildItem -Force | Where-Object {
        $name = $_.Name
        $exclude -notcontains $name
    }
    
    Compress-Archive -Path $filesToZip.FullName -DestinationPath $zipPath -Force
    Write-Host "Archive created at $zipPath" -ForegroundColor Green
    $global:ZipToDeploy = $zipPath
}

Invoke-Step "Cleaning temp artifacts" {
    if (Test-Path ".venv") {
        Remove-Item ".venv" -Recurse -Force
    }
    Pop-Location
    Set-Location $originalLocation
}

if (-not $SkipDeploy) {
    Invoke-Step "Deploying archive to $WebAppName" {
        az webapp deploy `
            --resource-group $ResourceGroup `
            --name $WebAppName `
            --src-path $ZipToDeploy `
            --type zip `
            --restart true | Out-Host

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "az webapp deploy not available or failed. Falling back to config-zip"
            az webapp deployment source config-zip `
                --resource-group $ResourceGroup `
                --name $WebAppName `
                --src $ZipToDeploy | Out-Host

            if ($LASTEXITCODE -ne 0) {
                throw "Deployment failed using both deploy and config-zip commands."
            }
        }
    }
}
else {
    Write-Host "Deployment skipped. Package ready at $ZipToDeploy" -ForegroundColor Yellow
}

Write-Host "Deployment automation finished" -ForegroundColor Green
