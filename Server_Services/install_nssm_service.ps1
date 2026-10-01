# TeleSnap Support Service - NSSM Windows Service Installer
# Requires Administrator Privileges

$ServiceName = "TeleSnapSupportService"
$DisplayName = "TeleSnap Pro Customer Support Bot Service"
$Description = "24/7 Always-on Telegram customer support, license inquiry, and lead dispatcher daemon for @telesnap_pro_bot."

$PythonExe = "C:\Users\user\AppData\Local\Programs\Python\Python314\python.exe"
$ScriptPath = "D:\Projects\TeleSnap-Pro\Server_Services\telesnap_support_service.py"
$WorkingDir = "D:\Projects\TeleSnap-Pro"
$StdoutLog  = "D:\Projects\TeleSnap-Pro\Server_Services\service_stdout.log"
$StderrLog  = "D:\Projects\TeleSnap-Pro\Server_Services\service_stderr.log"

$NssmExe = "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\NSSM.NSSM_Microsoft.Winget.Source_8wekyb3d8bbwe\nssm-2.24-101-g897c7ad\win64\nssm.exe"

# Elevate if not admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges to install Windows Service..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "⚡ Installing $DisplayName as Windows Service via NSSM" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Stop and remove existing service if present
& $NssmExe stop $ServiceName 2>$null
& $NssmExe remove $ServiceName confirm 2>$null

# Install service with unbuffered python output for real-time logging
& $NssmExe install $ServiceName "$PythonExe" "-u `"$ScriptPath`""
& $NssmExe set $ServiceName AppDirectory "$WorkingDir"
& $NssmExe set $ServiceName DisplayName "$DisplayName"
& $NssmExe set $ServiceName Description "$Description"
& $NssmExe set $ServiceName Start SERVICE_AUTO_START

# Logging and Rotation
& $NssmExe set $ServiceName AppStdout "$StdoutLog"
& $NssmExe set $ServiceName AppStderr "$StderrLog"
& $NssmExe set $ServiceName AppRotateFiles 1
& $NssmExe set $ServiceName AppRotateOnline 1
& $NssmExe set $ServiceName AppRotateBytes 10485760

# Auto-recovery: 1 second restart delay for fast seamless auto-reload
& $NssmExe set $ServiceName AppRestartDelay 1000

# Start Service
Write-Host "Starting $ServiceName..." -ForegroundColor Green
& $NssmExe start $ServiceName

# Check status
$status = (& $NssmExe status $ServiceName)
Write-Host "Service Status: $status" -ForegroundColor Green
Write-Host "Installation Complete! TeleSnap Support Service will now run 24/7 on boot." -ForegroundColor Green
Start-Sleep -Seconds 3
