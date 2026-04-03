@echo off
cd /d "%~dp0"
echo.
echo  Levantando dashboard LOCAL (tu dashboard.html) en http://localhost:3000
echo  Para exponerlo online: en otra terminal ejecuta: npx ngrok http 3000
echo.
node servir_dashboard_local.js
pause
