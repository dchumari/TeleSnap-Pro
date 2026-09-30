@echo off
setlocal enabledelayedexpansion

echo ======================================================================
echo             ⚡ TeleSnap Pro - MetaTrader 5 Deployer
echo ======================================================================
echo.

set SCRIPT_DIR=%~dp0..
set SOURCE_EXPERTS=%SCRIPT_DIR%\MQL5\Experts
set SOURCE_INCLUDE=%SCRIPT_DIR%\MQL5\Include\TeleSnap

if not exist "%SOURCE_EXPERTS%\TeleSnap_Pro.mq5" (
    echo [ERROR] Could not find %SOURCE_EXPERTS%\TeleSnap_Pro.mq5
    pause
    exit /b 1
)

set MT5_BASE=%APPDATA%\MetaQuotes\Terminal
if not exist "%MT5_BASE%" (
    echo [ERROR] MetaTrader 5 AppData directory not found at:
    echo %MT5_BASE%
    echo Please manually copy the MQL5 folder to your terminal's Data Directory.
    pause
    exit /b 1
)

echo Searching for active MetaTrader 5 instances in:
echo %MT5_BASE%
echo.

set FOUND=0
for /d %%D in ("%MT5_BASE%\*") do (
    if exist "%%D\MQL5\Experts" (
        set /a FOUND+=1
        echo [OK] Found MT5 Terminal: %%~nxD
        
        echo   - Deploying TeleSnap_Pro.mq5 to %%D\MQL5\Experts\
        copy /Y "%SOURCE_EXPERTS%\TeleSnap_Pro.mq5" "%%D\MQL5\Experts\" >nul
        
        echo   - Deploying Include\TeleSnap to %%D\MQL5\Include\TeleSnap\
        if not exist "%%D\MQL5\Include\TeleSnap" mkdir "%%D\MQL5\Include\TeleSnap"
        xcopy /Y /E /I "%SOURCE_INCLUDE%" "%%D\MQL5\Include\TeleSnap\" >nul
        
        echo   [+] Deployed successfully!
        echo.
    )
)

if %FOUND% equ 0 (
    echo [WARNING] No MT5 Terminal data folders found with an MQL5 directory.
    echo In MT5, click File -^> Open Data Folder to locate your MQL5 path.
) else (
    echo ======================================================================
    echo Deployment completed to %FOUND% terminal(s)!
    echo Next Steps:
    echo 1. Open MetaEditor (F4 in MT5).
    echo 2. Open Experts\TeleSnap_Pro.mq5 and press F7 to compile.
    echo 3. Ensure https://api.telegram.org is added in Tools -^> Options -^> Expert Advisors.
    echo 4. Drag TeleSnap_Pro onto your chart!
    echo ======================================================================
)

echo.
pause
