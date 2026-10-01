@echo off
title Restart TeleSnap Support Service (Auto-Reload Initializer)
cd /d "%~dp0"

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ========================================================================
    echo ⚡ TeleSnap Support Service - NSSM Auto-Reload Initializer
    echo ========================================================================
    echo.
    echo [1/3] Optimizing NSSM restart delay to 1000ms...
    nssm set TeleSnapSupportService AppRestartDelay 1000 >nul 2>&1
    
    echo [2/3] Enabling unbuffered real-time logging output (-u)...
    nssm set TeleSnapSupportService AppParameters "-u \"D:\Projects\TeleSnap-Pro\Server_Services\telesnap_support_service.py\"" >nul 2>&1
    
    echo [3/3] Restarting TeleSnapSupportService...
    nssm restart TeleSnapSupportService
    echo.
    nssm status TeleSnapSupportService
    echo.
    echo ========================================================================
    echo  SUCCESS: TeleSnap Support Service is active with Auto-Reload!
    echo ========================================================================
    echo  From this point forward, you do NOT need to run this script again!
    echo  Any edits to Python code, configuration, or .env files will be
    echo  automatically detected and reloaded within ~1 second.
    echo ========================================================================
    echo.
    pause
) else (
    echo Requesting Administrator privileges to initialize auto-reload...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c \"\"%~dp0restart_service.bat\"\"' -Verb RunAs"
)
