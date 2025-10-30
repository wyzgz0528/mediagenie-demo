@echo off
echo ========================================
echo   MediaGenie GitHub Auto Deploy
echo ========================================
echo.

echo Step 1: Configure Python Runtime...
az webapp config set --resource-group mediagenie-demo-rg --name mediagenie-demo --linux-fx-version "PYTHON|3.11" --startup-file "startup.sh"

echo.
echo Step 2: Enable Build Automation...
az webapp config appsettings set --resource-group mediagenie-demo-rg --name mediagenie-demo --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true ENABLE_ORYX_BUILD=true

echo.
echo Step 3: Deploy from Local (ZIP)...
echo Creating deployment package...

cd /d F:\project\MediaGenie1001
powershell -Command "Compress-Archive -Path backend,frontend,marketplace-portal,startup.sh,supervisord-demo.conf,package.json -DestinationPath deploy-temp.zip -Force"

echo Uploading to Azure...
az webapp deployment source config-zip --resource-group mediagenie-demo-rg --name mediagenie-demo --src deploy-temp.zip

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo App URL: https://mediagenie-demo-gzdvb5cbeceybwh4.eastus-01.azurewebsites.net
echo.
echo IMPORTANT: Configure environment variables in Azure Portal!
echo.

del deploy-temp.zip
pause
