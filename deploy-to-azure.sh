#!/bin/bash
# MediaGenie One-Click Deployment Script for Azure Cloud Shell
# This script deploys all components to Azure using pre-built packages

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${CYAN}========== $1 ==========${NC}\n"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# ====================================
# Load Configuration from .env
# ====================================
print_step "Loading Configuration"

# Check for .env file
if [ -f ".env" ]; then
    print_info "Found .env file, loading configuration..."
    # Export variables from .env file
    set -a
    source .env
    set +a
    print_success "Configuration loaded from .env"
elif [ -f "../.env" ]; then
    print_info "Found .env file in parent directory, loading..."
    set -a
    source ../.env
    set +a
    print_success "Configuration loaded from ../.env"
else
    print_info "No .env file found, will prompt for configuration"
fi

# ====================================
# Configuration
# ====================================
print_step "Configuration"

# Prompt for required parameters if not set from .env
if [ -z "$RESOURCE_GROUP" ]; then
    read -p "Enter Azure Resource Group name [MediaGenie-RG]: " RESOURCE_GROUP
    RESOURCE_GROUP=${RESOURCE_GROUP:-MediaGenie-RG}
fi

if [ -z "$LOCATION" ]; then
    read -p "Enter deployment location [eastus]: " LOCATION
    LOCATION=${LOCATION:-eastus}
fi

if [ -z "$APP_NAME_PREFIX" ]; then
    read -p "Enter app name prefix (lowercase, no spaces) [mediagenie]: " APP_PREFIX
    APP_PREFIX=${APP_PREFIX:-mediagenie}
else
    APP_PREFIX=$APP_NAME_PREFIX
fi

if [ -z "$AZURE_OPENAI_KEY" ]; then
    read -p "Enter Azure OpenAI API Key: " AZURE_OPENAI_KEY
    if [ -z "$AZURE_OPENAI_KEY" ]; then
        print_error "Azure OpenAI API Key is required"
        exit 1
    fi
fi

if [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
    read -p "Enter Azure OpenAI Endpoint: " AZURE_OPENAI_ENDPOINT
    if [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
        print_error "Azure OpenAI Endpoint is required"
        exit 1
    fi
fi

if [ -z "$AZURE_OPENAI_DEPLOYMENT" ]; then
    read -p "Enter Azure OpenAI Deployment Name [gpt-4]: " AZURE_OPENAI_DEPLOYMENT
    AZURE_OPENAI_DEPLOYMENT=${AZURE_OPENAI_DEPLOYMENT:-gpt-4}
fi

if [ -z "$AZURE_OPENAI_API_VERSION" ]; then
    AZURE_OPENAI_API_VERSION="2024-02-15-preview"
fi

if [ -z "$AZURE_SPEECH_KEY" ]; then
    read -p "Enter Azure Speech Service Key: " AZURE_SPEECH_KEY
    if [ -z "$AZURE_SPEECH_KEY" ]; then
        print_error "Azure Speech Service Key is required"
        exit 1
    fi
fi

if [ -z "$AZURE_SPEECH_REGION" ]; then
    read -p "Enter Azure Speech Region [eastus]: " AZURE_SPEECH_REGION
    AZURE_SPEECH_REGION=${AZURE_SPEECH_REGION:-eastus}
fi

# Derived names
MARKETPLACE_APP="${APP_PREFIX}-marketplace"
BACKEND_APP="${APP_PREFIX}-backend"
STORAGE_ACCOUNT="${APP_PREFIX}storage"

print_info "Resource Group: $RESOURCE_GROUP"
print_info "Location: $LOCATION"
print_info "Marketplace App: $MARKETPLACE_APP"
print_info "Backend App: $BACKEND_APP"
print_info "Storage Account: $STORAGE_ACCOUNT"

read -p "Continue with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    print_info "Deployment cancelled"
    exit 0
fi

# ====================================
# 1. Create Resource Group
# ====================================
print_step "Creating Resource Group"

az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

print_success "Resource group created"

# ====================================
# 2. Deploy ARM Template
# ====================================
print_step "Deploying Azure Infrastructure"

if [ ! -f "deploy/azuredeploy-optimized.json" ]; then
    print_error "ARM template not found at deploy/azuredeploy-optimized.json"
    print_info "Please ensure deployment packages are in the deploy/ directory"
    exit 1
fi

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file deploy/azuredeploy-optimized.json \
    --parameters appNamePrefix="$APP_PREFIX" \
    --parameters location="$LOCATION" \
    --output table

print_success "Infrastructure deployed"

# ====================================
# 3. Deploy Marketplace Portal
# ====================================
print_step "Deploying Marketplace Portal"

if [ ! -f "deploy/marketplace-portal.zip" ]; then
    print_error "Marketplace portal package not found"
    exit 1
fi

# Configure app settings
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$MARKETPLACE_APP" \
    --settings \
        SCM_DO_BUILD_DURING_DEPLOYMENT=false \
        ENABLE_ORYX_BUILD=false \
    --output none

# Deploy ZIP package
print_info "Uploading marketplace portal..."
az webapp deploy \
    --resource-group "$RESOURCE_GROUP" \
    --name "$MARKETPLACE_APP" \
    --src-path deploy/marketplace-portal.zip \
    --type zip \
    --async false \
    --timeout 600

print_success "Marketplace portal deployed"

# ====================================
# 4. Deploy Backend API
# ====================================
print_step "Deploying Backend API"

if [ ! -f "deploy/backend-api.zip" ]; then
    print_error "Backend API package not found"
    exit 1
fi

# Configure app settings
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKEND_APP" \
    --settings \
        SCM_DO_BUILD_DURING_DEPLOYMENT=false \
        ENABLE_ORYX_BUILD=false \
        AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
        AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
        AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
        AZURE_SPEECH_REGION="$AZURE_SPEECH_REGION" \
    --output none

# Add optional Vision settings if provided
if [ -n "$AZURE_VISION_KEY" ]; then
    az webapp config appsettings set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BACKEND_APP" \
        --settings \
            AZURE_VISION_KEY="$AZURE_VISION_KEY" \
            AZURE_VISION_ENDPOINT="$AZURE_VISION_ENDPOINT" \
        --output none
    print_info "Azure Vision settings configured"
fi

# Deploy ZIP package
print_info "Uploading backend API (this may take a few minutes)..."
az webapp deploy \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BACKEND_APP" \
    --src-path deploy/backend-api.zip \
    --type zip \
    --async false \
    --timeout 600

print_success "Backend API deployed"

# ====================================
# 5. Deploy Frontend (if exists)
# ====================================
print_step "Deploying Frontend"

if [ -f "deploy/frontend-build.zip" ]; then
    # Get storage account name
    STORAGE_ACCOUNT_NAME=$(az storage account list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?contains(name, '$APP_PREFIX')].name" \
        -o tsv | head -1)
    
    if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
        print_error "Storage account not found"
    else
        print_info "Storage account: $STORAGE_ACCOUNT_NAME"
        
        # Extract frontend build
        mkdir -p /tmp/frontend-build
        unzip -q -o deploy/frontend-build.zip -d /tmp/frontend-build
        
        # Upload to blob storage
        print_info "Uploading frontend files..."
        az storage blob upload-batch \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --destination '$web' \
            --source /tmp/frontend-build \
            --overwrite true \
            --output none
        
        # Cleanup
        rm -rf /tmp/frontend-build
        
        print_success "Frontend deployed"
    fi
else
    print_info "No frontend package found, skipping"
fi

# ====================================
# 6. Verify Deployment
# ====================================
print_step "Verifying Deployment"

# Get URLs
MARKETPLACE_URL="https://${MARKETPLACE_APP}.azurewebsites.net"
BACKEND_URL="https://${BACKEND_APP}.azurewebsites.net"

print_info "Waiting for apps to start (30 seconds)..."
sleep 30

# Test marketplace portal
print_info "Testing marketplace portal..."
MARKETPLACE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$MARKETPLACE_URL" || echo "000")
if [ "$MARKETPLACE_STATUS" = "200" ] || [ "$MARKETPLACE_STATUS" = "302" ]; then
    print_success "Marketplace portal is responding"
else
    print_error "Marketplace portal returned status: $MARKETPLACE_STATUS"
fi

# Test backend API
print_info "Testing backend API..."
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health" || echo "000")
if [ "$BACKEND_STATUS" = "200" ]; then
    print_success "Backend API is healthy"
else
    print_error "Backend API returned status: $BACKEND_STATUS"
fi

# Get frontend URL if storage exists
if [ -n "$STORAGE_ACCOUNT_NAME" ]; then
    FRONTEND_URL=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "primaryEndpoints.web" -o tsv)
fi

# ====================================
# 7. Summary
# ====================================
print_step "Deployment Summary"

echo ""
echo "=========================================="
echo "  MediaGenie Deployment Complete!"
echo "=========================================="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""
echo "Application URLs:"
echo "  Marketplace Portal: $MARKETPLACE_URL"
echo "  Backend API:        $BACKEND_URL"
if [ -n "$FRONTEND_URL" ]; then
echo "  Frontend:           $FRONTEND_URL"
fi
echo ""
echo "Next Steps:"
echo "  1. Visit the marketplace portal to complete setup"
echo "  2. Test API endpoints at ${BACKEND_URL}/docs"
echo "  3. Monitor application logs:"
echo "     az webapp log tail -g $RESOURCE_GROUP -n $BACKEND_APP"
echo ""
echo "=========================================="

print_success "Deployment script completed!"
