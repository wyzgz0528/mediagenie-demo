# Azure Cloud Shell Deployment Guide

This guide provides step-by-step instructions for deploying MediaGenie to Azure using Cloud Shell (Bash).

## Prerequisites

- Active Azure subscription
- Azure OpenAI service deployed (GPT-4 model)
- Azure Speech Service created
- Your API keys ready

## Deployment Steps

### 1. Build Deployment Packages Locally

On your local machine (Windows), run:

```powershell
.\build-deployment-packages.ps1
```

This generates:
- `deploy/marketplace-portal.zip` (3.24 MB)
- `deploy/backend-api.zip` (44.96 MB)
- `deploy/frontend-build.zip` (0.38 MB)
- `deploy/azuredeploy-optimized.json`
- `deploy/deploy-to-azure.sh`

### 2. Upload to Azure Cloud Shell

#### Option A: Using Cloud Shell Upload Feature

1. Open Azure Cloud Shell: https://shell.azure.com
2. Select **Bash** environment
3. Click the **Upload/Download files** button (ðŸ“¤ icon)
4. Upload the entire `deploy` folder

#### Option B: Using Azure Storage

1. Compress the deploy folder:
   ```powershell
   Compress-Archive -Path deploy -DestinationPath MediaGenie-Deploy.zip
   ```

2. Upload to Cloud Shell:
   - In Cloud Shell, click **Upload files**
   - Select `MediaGenie-Deploy.zip`
   - Extract: `unzip MediaGenie-Deploy.zip`

#### Option C: Using Git

```bash
# In Cloud Shell
git clone <your-repo-url>
cd MediaGenie1001
```

### 3. Prepare Deployment Script

```bash
# Navigate to deploy directory
cd deploy

# Make script executable
chmod +x deploy-to-azure.sh

# Verify files are present
ls -lh
```

Expected output:
```
-rw-r--r-- 1 user user  3.2M Oct 24 10:00 marketplace-portal.zip
-rw-r--r-- 1 user user   45M Oct 24 10:00 backend-api.zip
-rw-r--r-- 1 user user  380K Oct 24 10:00 frontend-build.zip
-rw-r--r-- 1 user user  7.1K Oct 24 10:00 azuredeploy-optimized.json
-rwxr-xr-x 1 user user  6.5K Oct 24 10:00 deploy-to-azure.sh
```

### 4. Run Deployment Script

```bash
./deploy-to-azure.sh
```

The script will prompt for:

1. **Resource Group name** (default: MediaGenie-RG)
2. **Location** (default: eastus)
3. **App prefix** (default: mediagenie) - lowercase, no spaces
4. **Azure OpenAI API Key** (required)
5. **Azure OpenAI Endpoint** (required, e.g., https://your-openai.openai.azure.com)
6. **Azure Speech Service Key** (required)
7. **Azure Speech Region** (default: eastus)

### 5. Monitor Deployment

The script will:
- âœ?Create resource group
- âœ?Deploy infrastructure (App Services, Storage)
- âœ?Upload marketplace portal
- âœ?Upload backend API with dependencies
- âœ?Upload frontend to blob storage
- âœ?Verify endpoints

**Deployment time**: 5-10 minutes

### 6. Verification

After deployment completes, you'll see:

```
==========================================
  MediaGenie Deployment Complete!
==========================================

Application URLs:
  Marketplace Portal: https://mediagenie-marketplace.azurewebsites.net
  Backend API:        https://mediagenie-backend.azurewebsites.net
  Frontend:           https://mediageniestorage.z1.web.core.windows.net

Next Steps:
  1. Visit the marketplace portal to complete setup
  2. Test API endpoints at /docs
  3. Monitor application logs
==========================================
```

## Troubleshooting

### Upload Timeout in Cloud Shell

If upload fails due to size:

1. **Split large files**:
   ```powershell
   # On Windows
   Compress-Archive -Path deploy/marketplace-portal -DestinationPath deploy/portal-small.zip
   Compress-Archive -Path deploy/backend -DestinationPath deploy/backend-small.zip
   ```

2. **Use Azure Storage**:
   ```bash
   # Upload to storage account
   az storage blob upload \
     --account-name mystorageaccount \
     --container-name deploy \
     --file backend-api.zip \
     --name backend-api.zip
   
   # Download in Cloud Shell
   az storage blob download \
     --account-name mystorageaccount \
     --container-name deploy \
     --name backend-api.zip \
     --file backend-api.zip
   ```

### Deployment Fails with "Package too large"

Use the **async** deployment flag:

```bash
az webapp deploy \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --src-path backend-api.zip \
  --type zip \
  --async true  # Deploy in background
```

Monitor deployment:
```bash
az webapp deployment list \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend
```

### "Module not found" Errors

The packages include `.python_packages/lib/site-packages` with all dependencies pre-installed.

If issues persist:

1. **Check app settings**:
   ```bash
   az webapp config appsettings list \
     --resource-group MediaGenie-RG \
     --name mediagenie-backend
   ```

2. **Verify Python version**:
   ```bash
   az webapp config show \
     --resource-group MediaGenie-RG \
     --name mediagenie-backend \
     --query linuxFxVersion
   ```

3. **View logs**:
   ```bash
   az webapp log tail \
     --resource-group MediaGenie-RG \
     --name mediagenie-backend
   ```

### Backend API Returns 500 Error

Check environment variables are set:

```bash
az webapp config appsettings set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --settings \
    AZURE_OPENAI_KEY="your-key" \
    AZURE_OPENAI_ENDPOINT="https://your-endpoint" \
    AZURE_SPEECH_KEY="your-speech-key" \
    AZURE_SPEECH_REGION="eastus"
```

## Advanced: Manual Deployment

If the script fails, deploy manually:

### Deploy Infrastructure
```bash
az deployment group create \
  --resource-group MediaGenie-RG \
  --template-file azuredeploy-optimized.json \
  --parameters appNamePrefix=mediagenie
```

### Deploy Marketplace Portal
```bash
az webapp deploy \
  --resource-group MediaGenie-RG \
  --name mediagenie-marketplace \
  --src-path marketplace-portal.zip \
  --type zip
```

### Deploy Backend API
```bash
az webapp config appsettings set \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --settings \
    AZURE_OPENAI_KEY="your-key" \
    AZURE_OPENAI_ENDPOINT="https://your-endpoint"

az webapp deploy \
  --resource-group MediaGenie-RG \
  --name mediagenie-backend \
  --src-path backend-api.zip \
  --type zip \
  --timeout 600
```

### Deploy Frontend
```bash
# Get storage account name
STORAGE_ACCOUNT=$(az storage account list \
  --resource-group MediaGenie-RG \
  --query "[0].name" -o tsv)

# Extract and upload
unzip frontend-build.zip -d frontend
az storage blob upload-batch \
  --account-name $STORAGE_ACCOUNT \
  --destination '$web' \
  --source frontend
```

## Cleanup

To remove all resources:

```bash
az group delete \
  --name MediaGenie-RG \
  --yes \
  --no-wait
```

## Support

- Check logs: `az webapp log tail -g MediaGenie-RG -n mediagenie-backend`
- View metrics: Azure Portal > App Service > Metrics
- Kudu console: `https://mediagenie-backend.scm.azurewebsites.net`

## Next Steps

1. Configure custom domain
2. Enable HTTPS/SSL certificates
3. Set up monitoring and alerts
4. Configure auto-scaling
5. Set up CI/CD pipeline
