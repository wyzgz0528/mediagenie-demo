# MediaGenie Deployment Guide - START HERE

## Quick Start

Follow these steps to deploy MediaGenie to Azure:

### Step 1: Run the Quick Deploy Script

Open PowerShell in this directory and run:

```powershell
.\quick-deploy.ps1
```

This script will:
1. Check if Azure CLI is installed
2. Log in to Azure (if not already logged in)
3. Create Azure Container Registry (ACR)
4. Configure Web Apps to use Docker containers
5. Get publish profiles
6. Display GitHub Secrets configuration

### Step 2: Configure GitHub Secrets

After the script completes, it will display 5 secrets you need to add to GitHub:

1. Go to: https://github.com/wyzgz0528/mediagenie-demo/settings/secrets/actions
2. Click "New repository secret"
3. Add each of the following secrets:

   - **ACR_LOGIN_SERVER**: `mediageniecr.azurecr.io`
   - **ACR_USERNAME**: (from script output)
   - **ACR_PASSWORD**: (from script output)
   - **AZURE_WEBAPP_BACKEND_PUBLISH_PROFILE**: (copy content from `backend-publish-profile.xml`)
   - **AZURE_WEBAPP_FRONTEND_PUBLISH_PROFILE**: (copy content from `frontend-publish-profile.xml`)

### Step 3: Trigger GitHub Actions Deployment

**Option A: Update workflow to use master branch**

```powershell
# Edit .github/workflows/azure-deploy.yml
# Change line 4 from:
#   branches: - main
# To:
#   branches: - master

git add .github/workflows/azure-deploy.yml
git commit -m "Update workflow to trigger on master branch"
git push origin master
```

**Option B: Manually trigger the workflow**

1. Go to: https://github.com/wyzgz0528/mediagenie-demo/actions
2. Click on "Deploy to Azure Web App" workflow
3. Click "Run workflow" button
4. Select `master` branch
5. Click "Run workflow"

### Step 4: Wait for Deployment

The deployment will take about 5-10 minutes. You can monitor progress at:
https://github.com/wyzgz0528/mediagenie-demo/actions

### Step 5: Verify Deployment

Once deployment is complete, visit:

- **Backend Health**: https://mediagenie-backend.azurewebsites.net/health
- **Backend API Docs**: https://mediagenie-backend.azurewebsites.net/docs
- **Frontend App**: https://mediagenie-frontend.azurewebsites.net

---

## Troubleshooting

### Script fails with "Azure CLI not installed"

Install Azure CLI from: https://docs.microsoft.com/cli/azure/install-azure-cli

### Script fails with "ACR creation failed"

Check if you have permission to create resources in the subscription. You may need to:
1. Contact your Azure administrator
2. Or use a different subscription

### GitHub Actions fails

Check the following:
1. All 5 secrets are correctly configured
2. The publish profile XML files are complete (no truncation)
3. The workflow file is configured for the correct branch

### Application doesn't load

1. Check the deployment logs in GitHub Actions
2. Check the application logs in Azure Portal:
   - Go to Web App > Monitoring > Log stream
3. Verify environment variables are set correctly in Azure Portal:
   - Go to Web App > Configuration > Application settings

---

## Additional Resources

- **Full Deployment Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Next Steps**: [NEXT_STEPS.md](NEXT_STEPS.md)
- **Quick Commands**: [QUICK_COMMANDS.md](QUICK_COMMANDS.md)
- **Project Summary**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

## Need Help?

If you encounter any issues:

1. Check the troubleshooting section above
2. Review the detailed guides in the documentation
3. Check GitHub Actions logs for error messages
4. Check Azure Portal logs for runtime errors

---

**Ready to start? Run `.\quick-deploy.ps1` now!**

