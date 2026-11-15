@echo off
setlocal
title MyHome - Stop demo sharing
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_myhome.ps1" -Stop
set "myhome_exit=%ERRORLEVEL%"
echo.
pause
exit /b %myhome_exit%
