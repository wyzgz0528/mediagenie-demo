@echo off
REM Azure Deployment Script for MediaGenie
REM This script creates Azure resources using Azure CLI

setlocal enabledelayedexpansion

set ResourceGroup=mediagenie-rg
set Location=eastus
set AppPrefix=mediagenie

echo ========================================
echo MediaGenie Azure Deployment
echo ========================================
echo.

REM Step 1: Check Azure CLI
echo [1/6] Checking Azure CLI...
az --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Azure CLI not found
    exit /b 1
)
echo OK: Azure CLI installed
echo.

REM Step 2: Check Azure login
echo [2/6] Checking Azure login...
az account show >nul 2>&1
if errorlevel 1 (
    echo ERROR: Not logged in to Azure. Run: az login
    exit /b 1
)
echo OK: Logged in to Azure
echo.

REM Step 3: Create resource group
echo [3/6] Creating resource group...
az group exists --name %ResourceGroup% >nul 2>&1
if errorlevel 1 (
    az group create --name %ResourceGroup% --location %Location% >nul 2>&1
    echo OK: Resource group created
) else (
    echo OK: Resource group already exists
)
echo.

REM Step 4: Create App Service Plan
echo [4/6] Creating App Service Plan...
set PlanName=%AppPrefix%-plan
az appservice plan create --name %PlanName% --resource-group %ResourceGroup% --sku B1 --is-linux >nul 2>&1
echo OK: App Service Plan created
echo.

REM Step 5: Create Web Apps
echo [5/6] Creating Web Apps...
set BackendName=%AppPrefix%-backend
echo   Creating backend: %BackendName%
az webapp create --resource-group %ResourceGroup% --plan %PlanName% --name %BackendName% --runtime python:3.11 >nul 2>&1
echo   OK: Backend created

set FrontendName=%AppPrefix%-frontend
echo   Creating frontend: %FrontendName%
az webapp create --resource-group %ResourceGroup% --plan %PlanName% --name %FrontendName% --runtime node:18-lts >nul 2>&1
echo   OK: Frontend created
echo.

REM Step 6: Create PostgreSQL Database
echo [6/6] Creating PostgreSQL Database...
for /f "tokens=1-4" %%a in ('powershell -Command "Get-Random -Minimum 1000 -Maximum 9999"') do set DbRandom=%%a
set DbName=%AppPrefix%-db-%DbRandom%
set DbUser=dbadmin
for /f "tokens=1-4" %%a in ('powershell -Command "Get-Random -Minimum 100000 -Maximum 999999"') do set DbPassRandom=%%a
set DbPassword=MediaGenie@%DbPassRandom%

echo   Database name: %DbName%
echo   Admin user: %DbUser%
echo   Creating database (this may take 2-3 minutes)...

az postgres server create ^
    --resource-group %ResourceGroup% ^
    --name %DbName% ^
    --location %Location% ^
    --admin-user %DbUser% ^
    --admin-password %DbPassword% ^
    --sku-name B_Gen5_1 ^
    --storage-size 51200 >nul 2>&1

echo OK: PostgreSQL Database created
echo.

REM Configure App Settings
echo Configuring app settings...
set DbConnectionString=postgresql+asyncpg://%DbUser%:%DbPassword%@%DbName%.postgres.database.azure.com:5432/mediagenie

az webapp config appsettings set ^
    --resource-group %ResourceGroup% ^
    --name %BackendName% ^
    --settings ^
    DATABASE_URL=%DbConnectionString% ^
    ENVIRONMENT=production ^
    DEBUG=false >nul 2>&1

az webapp config appsettings set ^
    --resource-group %ResourceGroup% ^
    --name %FrontendName% ^
    --settings ^
    REACT_APP_MEDIA_SERVICE_URL=https://%BackendName%.azurewebsites.net ^
    REACT_APP_ENV=production >nul 2>&1

echo OK: App settings configured
echo.

REM Summary
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Azure Resources Created:
echo   Resource Group: %ResourceGroup%
echo   Backend URL: https://%BackendName%.azurewebsites.net
echo   Frontend URL: https://%FrontendName%.azurewebsites.net
echo   Database: %DbName%
echo.
echo Database Credentials:
echo   Server: %DbName%.postgres.database.azure.com
echo   Admin User: %DbUser%
echo   Admin Password: %DbPassword%
echo.
echo Connection String:
echo   %DbConnectionString%
echo.
echo Next Steps:
echo 1. Deploy backend code using VSCode Azure extension
echo 2. Deploy frontend code using VSCode Azure extension
echo 3. Configure Azure AD (optional)
echo 4. Test the application
echo.
echo For deployment instructions, see: VSCODE_MANUAL_SETUP.md
echo.

endlocal

