# Script para verificar que Flor IA está configurada correctamente
$server = "root@72.61.58.240"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICANDO CONFIGURACION DE FLOR IA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Verificando archivos en el servidor..." -ForegroundColor Yellow
ssh $server "if [ -f /root/checkin24hs/flor-ai-service.js ]; then echo 'OK: flor-ai-service.js existe'; grep -n 'TU MISIÓN PRINCIPAL' /root/checkin24hs/flor-ai-service.js | head -1; else echo 'ERROR: Archivo no encontrado'; fi"

Write-Host ""
Write-Host "2. Verificando estado del servicio..." -ForegroundColor Yellow
ssh $server "CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1); if [ -n \"`$CONTAINER\" ]; then echo 'OK: Contenedor activo:' `$CONTAINER; docker ps --filter 'name=whatsapp.1' --format '{{.Status}}'; else echo 'ERROR: Contenedor no encontrado'; fi"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "1. Ve al dashboard: https://dashboard.checkin24hs.com" -ForegroundColor White
Write-Host "2. Flor IA -> Pestaña 'IA'" -ForegroundColor White
Write-Host "3. Configura la API Key de Gemini" -ForegroundColor White
Write-Host "4. Prueba con un mensaje de WhatsApp" -ForegroundColor White
Write-Host ""


