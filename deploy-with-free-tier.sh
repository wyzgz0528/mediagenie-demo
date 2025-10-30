#!/bin/bash

# MediaGenie Azure Deployment Script - Free Tier (F1)
# This script deploys MediaGenie using the FREE tier to avoid quota issues

set -e

echo "===================================================================="
echo "        MediaGenie Azure Deployment - Free Tier (F1)               "
echo "===================================================================="
echo ""

# Configuration
RESOURCE_GROUP="MediaGenie-RG"
LOCATION="eastus"
APP_NAME="mediagenie-$(date +%s)"
SKU="F1"  # Free tier - no quota issues!

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed"
    exit 1
fi

# Check if logged in
echo "[1/6] Checking Azure login..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

# Prompt for API keys
echo "[2/6] Please provide your Azure service credentials:"
echo ""
read -p "Azure OpenAI API Key: " AZURE_OPENAI_KEY
read -p "Azure OpenAI Endpoint (e.g., https://your-openai.openai.azure.com/): " AZURE_OPENAI_ENDPOINT
read -p "Azure Speech Key: " AZURE_SPEECH_KEY
read -p "Azure Speech Region [eastus]: " AZURE_SPEECH_REGION
AZURE_SPEECH_REGION=${AZURE_SPEECH_REGION:-eastus}

echo ""
echo "[3/6] Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output none

echo "[4/6] Deploying with ARM template (SKU: $SKU - Free Tier)..."
echo "This will avoid quota issues!"
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters \
    siteName=$APP_NAME \
    sku=$SKU \
    azureOpenAIKey="$AZURE_OPENAI_KEY" \
    azureOpenAIEndpoint="$AZURE_OPENAI_ENDPOINT" \
    azureSpeechKey="$AZURE_SPEECH_KEY" \
    azureSpeechRegion="$AZURE_SPEECH_REGION" \
  --query 'properties.outputs' \
  --output json)

echo ""
echo "[5/6] Deploying application code..."

# Create a temporary deployment package
TEMP_DIR=$(mktemp -d)
cp -r backend "$TEMP_DIR/"
cp -r frontend/build "$TEMP_DIR/frontend/"

# Create zip
cd "$TEMP_DIR"
zip -r deploy.zip backend frontend > /dev/null
cd -

# Deploy to Web App
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --src "$TEMP_DIR/deploy.zip" \
  --output none

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "[6/6] Waiting for application to start..."
sleep 30

# Get URLs
WEBSITE_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.websiteUrl.value')
API_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.apiUrl.value')

echo ""
echo "===================================================================="
echo "                    🎉 Deployment Complete!                        "
echo "===================================================================="
echo ""
echo "Application Info:"
echo "  Name:          $APP_NAME"
echo "  SKU:           $SKU (Free Tier - No quota issues!)"
echo "  Resource Group: $RESOURCE_GROUP"
echo ""
echo "Access URLs:"
echo "  🌐 Website:     $WEBSITE_URL"
echo "  📚 API Docs:    $WEBSITE_URL/docs"
echo "  ❤️  Health:      $WEBSITE_URL/health"
echo ""
echo "Note: Free tier (F1) limitations:"
echo "  - 60 minutes/day compute time"
echo "  - App sleeps after 20 minutes of inactivity"
echo "  - 1 GB storage"
echo ""
echo "To upgrade to a paid tier (no limitations):"
echo "  az appservice plan update \\"
echo "    --name $APP_NAME-plan \\"
echo "    --resource-group $RESOURCE_GROUP \\"
echo "    --sku B1"
echo ""
echo "===================================================================="
echo ""

