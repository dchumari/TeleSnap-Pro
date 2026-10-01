@echo off
title Uninstall TeleSnap Support Service
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% == 0 (
    nssm stop TeleSnapSupportService
    nssm remove TeleSnapSupportService confirm
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c nssm stop TeleSnapSupportService & nssm remove TeleSnapSupportService confirm & echo Service removed. & pause' -Verb RunAs"
)
