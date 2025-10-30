# ‚ö†Ô∏è IMPORTANT: Upload Instructions
# ===================================

## Problem Identified
You're running an OLD deploy.sh that still has CRLF line endings!

The errors show:
```
scripts/deploy.sh: line 3: $'\r': command not found  ‚ù?OLD FILE!
```

## Solution: Upload the V2 Package First!

### Step 1: Upload ZIP to Cloud Shell
**File to upload:** `mediagenie-v2-20251024_012258.zip`

**How to upload:**
1. Click the **Upload/Download** icon in Cloud Shell toolbar (üì§)
2. Select **Upload**
3. Choose `mediagenie-v2-20251024_012258.zip` from your local machine
4. Wait for upload to complete

### Step 2: Verify Upload
```bash
# Check file exists
ls -lh mediagenie-v2-20251024_012258.zip

# Should show:
# -rw-r--r-- 1 user user 415K Oct 24 01:22 mediagenie-v2-20251024_012258.zip
```

### Step 3: Extract and Deploy
```bash
# Clean previous attempts
rm -rf deploy backend.zip

# Extract V2 package
unzip mediagenie-v2-20251024_012258.zip -d deploy

# Verify extraction
ls -la deploy/scripts/

# Should show deploy.sh with Unix line endings

# Deploy
cd deploy
chmod +x scripts/deploy.sh
bash scripts/deploy.sh
```

## How to Verify You Have the V2 Package

### Check for CRLF (should return nothing):
```bash
grep -r $'\r' deploy/scripts/deploy.sh
# If empty output = good (Unix LF)
# If shows lines = bad (Windows CRLF)
```

### Check for BOM (should show "ASCII"):
```bash
file deploy/backend/startup.txt
# Should show: ASCII text
# NOT: UTF-8 Unicode (with BOM)
```

## Current Issue Analysis

Your current errors:
```
1. unzip: cannot find mediagenie-v2-20251024_012258.zip
   ‚û?File not uploaded yet!

2. scripts/deploy.sh: line 3: $'\r': command not found
   ‚û?Running OLD deploy.sh with CRLF!

3. --name: command not found
   ‚û?Multi-line az commands broken by CRLF
```

**Root cause:** You're running the old deploy.sh from a previous package, NOT the V2 version.

## Action Required

üî¥ **STOP** - Don't run any commands yet!

1. ‚ú?Locate `mediagenie-v2-20251024_012258.zip` on your local machine
   - Location: `k:\project\MediaGenie1001\mediagenie-v2-20251024_012258.zip`
   
2. ‚ú?Upload it to Cloud Shell using the Upload button

3. ‚ú?Verify upload: `ls -lh mediagenie-v2-20251024_012258.zip`

4. ‚ú?Then extract and deploy using commands above

## Expected Success Output

After uploading and deploying V2 package:
```
‚ú?No $'\r' errors (Unix LF working)
‚ú?No ??? errors (No BOM working)
‚ú?az commands execute properly (multi-line syntax working)
‚ú?Health check returns 200 OK
‚ú?Container stays running
```

## File Location on Windows

The ZIP file is here on your local machine:
```
k:\project\MediaGenie1001\mediagenie-v2-20251024_012258.zip
```

Size: 414.25 KB (424,194 bytes)
