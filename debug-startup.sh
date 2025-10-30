#!/bin/bash
# ======================================
# Debug Container Startup Issue
# ======================================

BACKEND_NAME="mediagenie-api-v2-20251023173416"
RG_NAME="mediagenie-rg-v2-20251023173253"

echo "=========================================="
echo "Checking Container Logs"
echo "=========================================="
echo ""

# Get Docker logs (actual container output)
echo "Fetching Docker logs..."
curl -s "https://${BACKEND_NAME}.scm.azurewebsites.net/api/logs/docker" | tail -100

echo ""
echo ""
echo "=========================================="
echo "Checking App Logs"
echo "=========================================="
echo ""

# Get application logs
az webapp log tail --name "$BACKEND_NAME" --resource-group "$RG_NAME" --lines 50

echo ""
echo ""
echo "=========================================="
echo "Checking Container Status"
echo "=========================================="
echo ""

# Check if container is running
az webapp show --name "$BACKEND_NAME" --resource-group "$RG_NAME" \
  --query "{state:state, availabilityState:availabilityState, outboundIpAddresses:outboundIpAddresses}" \
  -o table

echo ""
echo ""
echo "=========================================="
echo "Manual Health Check"
echo "=========================================="
echo ""

# Try to access health endpoint
echo "Testing: https://${BACKEND_NAME}.azurewebsites.net/health"
curl -v "https://${BACKEND_NAME}.azurewebsites.net/health" 2>&1 | head -20

echo ""
echo ""
echo "=========================================="
echo "Checking Startup Command"
echo "=========================================="
echo ""

# Check what startup command is being used
az webapp config show --name "$BACKEND_NAME" --resource-group "$RG_NAME" \
  --query "{appCommandLine:appCommandLine, linuxFxVersion:linuxFxVersion}" \
  -o json

echo ""
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "If you see errors above, we'll fix them."
echo "If no errors, the app might just need more time to start."
echo ""
echo "To restart the app:"
echo "  az webapp restart --name $BACKEND_NAME --resource-group $RG_NAME"
