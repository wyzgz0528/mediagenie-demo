# Quick Start: Deploy MediaGenie with .env Configuration

## 📋 Overview

Now you can deploy MediaGenie without manually entering credentials - all configuration is read from a `.env` file!

## 🚀 Quick Deployment Steps

### Step 1: Configure Your Credentials

In the `deploy` folder, rename `.env.template` to `.env` and fill in your Azure credentials:

```bash
# .env file
AZURE_OPENAI_KEY=sk-your-actual-openai-key-here
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview

AZURE_SPEECH_KEY=your-actual-speech-key-here
AZURE_SPEECH_REGION=eastus

# Optional: Computer Vision
AZURE_VISION_KEY=YOUR_AZURE_VISION_KEY_HERE-here
AZURE_VISION_ENDPOINT=https://your-vision.cognitiveservices.azure.com/

# Deployment settings
RESOURCE_GROUP=MediaGenie-RG
APP_NAME_PREFIX=mediagenie
LOCATION=eastus
```

### Step 2: Package Everything

#### Option A: Keep .env Separate (Recommended for Security)

```powershell
# On Windows
# 1. Edit deploy/.env with your credentials
# 2. Create deployment package
Compress-Archive -Path deploy -DestinationPath MediaGenie-Deploy.zip

# In Azure Cloud Shell:
# Upload MediaGenie-Deploy.zip
unzip MediaGenie-Deploy.zip
cd deploy
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
```

#### Option B: .env at Root (Easier for Upload)

```powershell
# On Windows
# 1. Copy .env.template to .env at project root
Copy-Item deploy\.env.template .env
# 2. Edit .env with your credentials
# 3. Create package
Compress-Archive -Path deploy,.env -DestinationPath MediaGenie-Deploy.zip

# In Azure Cloud Shell:
# Upload MediaGenie-Deploy.zip
unzip MediaGenie-Deploy.zip
# .env will be in current directory
cd deploy
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
# Script will find ../.env automatically
```

### Step 3: Deploy to Azure

The script will:
- �?Automatically load configuration from `.env`
- �?Skip prompts for any values already in `.env`
- �?Only ask for missing required values
- �?Deploy everything in one command

```bash
cd deploy
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
```

## 📁 File Structure Options

### Structure 1: .env in deploy folder
```
MediaGenie-Deploy.zip
├── deploy/
�?  ├── .env                        �?Your credentials here
�?  ├── deploy-to-azure.sh
�?  ├── marketplace-portal.zip
�?  ├── backend-api.zip
�?  └── ...
```

### Structure 2: .env at root
```
MediaGenie-Deploy.zip
├── .env                            �?Your credentials here
└── deploy/
    ├── deploy-to-azure.sh
    ├── marketplace-portal.zip
    ├── backend-api.zip
    └── ...
```

Both work! Script checks both locations.

## 🔒 Security Best Practices

### ⚠️ Important: Never commit .env to Git!

```bash
# Add to .gitignore
echo ".env" >> .gitignore
```

### Option 1: Use Azure Key Vault (Production)

Store secrets in Key Vault and reference them:

```bash
# Get secrets from Key Vault during deployment
AZURE_OPENAI_KEY=$(az keyvault secret show \
  --vault-name MyKeyVault \
  --name openai-key \
  --query value -o tsv)
```

### Option 2: Use Cloud Shell Storage (Convenient)

Upload .env to Cloud Shell once, reuse for multiple deployments:

```bash
# First time: upload .env to Cloud Shell home
# Subsequent deployments:
cd ~/deploy
./deploy-to-azure.sh  # Uses ~/. env
```

### Option 3: Environment Variables (CI/CD)

Set variables in your terminal before running:

```bash
export AZURE_OPENAI_KEY="sk-..."
export AZURE_OPENAI_ENDPOINT="https://..."
./deploy-to-azure.sh  # Uses exported variables
```

## 🎯 What Gets Configured Automatically

When using `.env`, the script automatically sets:

### Backend App Service Settings:
- �?`AZURE_OPENAI_KEY`
- �?`AZURE_OPENAI_ENDPOINT`
- �?`AZURE_OPENAI_DEPLOYMENT`
- �?`AZURE_OPENAI_API_VERSION`
- �?`AZURE_SPEECH_KEY`
- �?`AZURE_SPEECH_REGION`
- �?`AZURE_VISION_KEY` (if provided)
- �?`AZURE_VISION_ENDPOINT` (if provided)

### Deployment Configuration:
- �?Resource Group name
- �?Azure region
- �?App name prefix
- �?SKU tier

## 🔄 Interactive Mode

If `.env` is missing or incomplete, the script falls back to interactive prompts:

```bash
./deploy-to-azure.sh

# Output:
# [INFO] No .env file found, will prompt for configuration
# Enter Azure Resource Group name [MediaGenie-RG]: 
# Enter Azure OpenAI API Key: ****
# ...
```

## 📝 Complete .env Example

```bash
# Azure OpenAI
AZURE_OPENAI_KEY=YOUR_AZURE_OPENAI_KEY_HERE
AZURE_OPENAI_ENDPOINT=https://my-openai-east.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4-turbo
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Azure Speech
AZURE_SPEECH_KEY=YOUR_AZURE_SPEECH_KEY_HERE
AZURE_SPEECH_REGION=eastus

# Azure Vision (Optional)
AZURE_VISION_KEY=def456ghi789jkl012mno345pqr678stu
AZURE_VISION_ENDPOINT=https://my-vision-east.cognitiveservices.azure.com/

# Deployment Config
RESOURCE_GROUP=MediaGenie-Production-RG
APP_NAME_PREFIX=mymediagenie
LOCATION=eastus
SKU=B2
```

## 🚦 Quick Deployment Checklist

- [ ] Fill in `.env` with your Azure credentials
- [ ] Verify all required keys are present
- [ ] Compress deploy folder (with .env)
- [ ] Upload to Azure Cloud Shell
- [ ] Extract and navigate to deploy folder
- [ ] Run `chmod +x deploy-to-azure.sh`
- [ ] Run `./deploy-to-azure.sh`
- [ ] Wait 5-10 minutes
- [ ] Access your deployed applications!

## 🎉 That's It!

No more manually entering credentials during deployment. Configure once, deploy anytime!

---

**Pro Tip**: Keep multiple `.env` files for different environments:
- `.env.dev` - Development
- `.env.staging` - Staging
- `.env.prod` - Production

```bash
# Deploy to production
cp .env.prod .env
./deploy-to-azure.sh
```
