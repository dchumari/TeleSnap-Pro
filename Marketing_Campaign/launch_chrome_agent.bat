@echo off
title TeleSnap - Launch Chrome with Agent Debugging (Profile 1)
echo ========================================================================
echo 🌐 Launching Google Chrome (Profile 1) with Remote Debugging (Port 9222)
echo ========================================================================
echo.
echo If Chrome is currently open, please close standard Chrome windows first
echo so the agent can attach to your Profile 1 session.
echo.

start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --profile-directory="Profile 1" "https://x.com"

echo Chrome is now active with Agent Bridge on port 9222!
echo You can now run twitter_agent_poster.py to post tweets automatically.
pause
