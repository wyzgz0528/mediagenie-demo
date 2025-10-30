# MediaGenie V2 - Final Deployment Guide
# ======================================

## Problems Fixed âœ?

### Issue 1: startup.txt BOM encoding
```
/tmp/.../startup.txt: 1: ???gunicorn: not found
```
**Fix**: Created startup.txt with UTF-8 no BOM encoding

### Issue 2: deploy.sh Windows line endings
```
scripts/deploy.sh: line 3: $'\r': command not found
sleep: invalid time interval '90\r'
```
**Fix**: Created deploy.sh with Unix LF line endings

## Deployment Commands

### Step 1: Clean and Extract
```bash
# Remove previous attempts
rm -rf deploy
rm -f backend.zip

# Extract V2 package
unzip mediagenie-v2-20251024_012258.zip -d deploy
```

### Step 2: Deploy
```bash
# Enter directory
cd deploy

# Make script executable
chmod +x scripts/deploy.sh

# Execute deployment (5-10 minutes)
bash scripts/deploy.sh
```

### Step 3: Verify Success

**Expected output:**
```
==================================
Deployment Complete!
==================================

Backend URL: https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net
API Docs: https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/docs
Health Check: https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/health

Waiting 90 seconds for app to start...

Testing health endpoint...
{"status":"healthy","timestamp":"2025-10-24T..."}
SUCCESS!
```

## Post-Deployment Testing

```bash
# Replace XXXXXXXX with actual timestamp from deployment

# Test health
curl https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/health

# View API docs
curl https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/docs

# Test TTS
curl -X POST https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello", "voice": "en-US-JennyNeural"}' \
  --output test.mp3

# Test marketplace landing page
curl https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/marketplace/landing
```

## Troubleshooting

### If deployment fails, check logs:
```bash
az webapp log tail --name mediagenie-api-v2-XXXXXXXX --resource-group mediagenie-rg-v2-XXXXXXXX
```

### If health check fails after 90 seconds:
```bash
# Wait additional time (first startup can take 2-3 minutes)
sleep 120
curl https://mediagenie-api-v2-XXXXXXXX.azurewebsites.net/health

# If still failing, restart
az webapp restart --name mediagenie-api-v2-XXXXXXXX --resource-group mediagenie-rg-v2-XXXXXXXX
```

## What This Package Contains

âœ?backend/main.py (61KB) - FastAPI application
âœ?backend/marketplace.py (20KB) - Marketplace integration
âœ?backend/requirements.txt (14 packages, Unix LF)
âœ?backend/.env (all Azure service keys)
âœ?backend/startup.txt (UTF-8 no BOM, Unix LF)
âœ?frontend/* (React build, 13 files, 1.26MB)
âœ?scripts/deploy.sh (Unix LF)

## Technical Details

**Startup command:**
```bash
gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 --timeout 600 main:app
```

**Python packages:**
- fastapi, uvicorn, gunicorn
- azure-cognitiveservices-speech
- azure-cognitiveservices-vision-computervision
- azure-storage-blob, azure-identity
- openai, pydantic, python-dotenv
- requests, pillow, numpy

**Azure resources created:**
- Resource group: mediagenie-rg-v2-XXXXXXXX
- App Service Plan: B1 (Linux)
- Web App: Python 3.10
- Build: Oryx (automatic dependency installation)

## Expected Timeline
- Extract: 10 seconds
- Resource creation: 2 minutes
- Code deployment: 5-7 minutes
- First startup: 1-2 minutes
- **Total: ~10 minutes**

## Success Indicators
âœ?No `$'\r': command not found` errors
âœ?No `???gunicorn: not found` errors
âœ?Health endpoint returns 200 OK
âœ?Container doesn't exit/restart
âœ?Logs show "Uvicorn running on http://0.0.0.0:8000"
