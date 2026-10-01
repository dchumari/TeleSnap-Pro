@echo off
title Restart TeleSnap Support Service
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% == 0 (
    nssm restart TeleSnapSupportService
    nssm status TeleSnapSupportService
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c nssm restart TeleSnapSupportService & nssm status TeleSnapSupportService & pause' -Verb RunAs"
)
