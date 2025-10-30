@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script for Python Flask
:: ----------------------

:: Prerequisites
:: -------------

:: Verify python.exe installed
where python 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing python.exe executable, please install python, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling Python Flask deployment.

:: 1. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 2. Create virtual environment
IF NOT EXIST "%DEPLOYMENT_TARGET%\antenv" (
  echo Creating virtual environment...
  call :ExecuteCmd python -m venv "%DEPLOYMENT_TARGET%\antenv"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 3. Activate virtual environment
echo Activating virtual environment...
call "%DEPLOYMENT_TARGET%\antenv\Scripts\activate.bat"

:: 4. Install packages
echo Installing Python packages...
IF EXIST "%DEPLOYMENT_TARGET%\requirements.txt" (
  call :ExecuteCmd pip install --upgrade pip
  call :ExecuteCmd pip install -r "%DEPLOYMENT_TARGET%\requirements.txt"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 5. Copy startup command
IF EXIST "%DEPLOYMENT_TARGET%\startup.txt" (
  echo Copying startup command...
  copy "%DEPLOYMENT_TARGET%\startup.txt" "%DEPLOYMENT_TARGET%\..\startup.txt"
)

echo Flask deployment completed successfully.

goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
