@echo off
setlocal
title MyHome - Start demo and share link
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_myhome.ps1" %*
set "myhome_exit=%ERRORLEVEL%"
echo.
if not "%myhome_exit%"=="0" echo Startup failed. See the message above and artifacts\launcher.log.
pause
exit /b %myhome_exit%
