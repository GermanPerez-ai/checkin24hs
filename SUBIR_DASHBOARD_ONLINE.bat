@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SUBIR_DASHBOARD_ONLINE.ps1"
pause
