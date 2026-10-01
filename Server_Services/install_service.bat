@echo off
title TeleSnap NSSM Windows Service Installer
cd /d "%~dp0"

echo ======================================================
echo ⚡ TeleSnap Support Service - NSSM Service Installer
echo ======================================================
echo.
echo Installing TeleSnapSupportService as an always-on Windows Service...
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrator privileges.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_nssm_service.ps1"
) else (
    echo [UAC] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%~dp0install_nssm_service.ps1\"\"' -Verb RunAs"
)

echo.
pause
