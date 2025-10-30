#!/bin/bash
# ======================================
# Switch to Correct Subscription
# ======================================

echo "Current subscription:"
az account show --query "{Name:name, ID:id, User:user.name}" -o table

echo ""
echo "Switching to WYZ subscription..."
az account set --subscription "3628daff-52ae-4f64-a310-28ad4b2158ca"

echo ""
echo "Verifying switch:"
az account show --query "{Name:name, ID:id, User:user.name}" -o table

echo ""
echo "âœ?Ready to deploy!"
echo ""
echo "Run deployment now:"
echo "  cd ~/deploy && bash scripts/deploy.sh"
