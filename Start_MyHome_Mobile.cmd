@echo off
setlocal
title MyHome - Mobile API and database
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_myhome.ps1" -Mobile -NoBrowser %*
set "myhome_exit=%ERRORLEVEL%"
echo.
if not "%myhome_exit%"=="0" echo Startup failed. See artifacts\launcher.log.
pause
exit /b %myhome_exit%
