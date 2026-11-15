@echo off
setlocal
title MyHome - Publish Cloudflare Worker
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_myhome.ps1" -Cloudflare %*
set "myhome_exit=%ERRORLEVEL%"
echo.
if not "%myhome_exit%"=="0" echo Cloudflare publishing failed. See artifacts\launcher.log and artifacts\cloudflare-deploy.log.
pause
exit /b %myhome_exit%
