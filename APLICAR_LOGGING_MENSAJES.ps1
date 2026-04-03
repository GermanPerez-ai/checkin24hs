# Script para aplicar logging mejorado de mensajes recibidos
# Esto ayudará a detectar si los mensajes se están recibiendo

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR LOGGING MEJORADO DE MENSAJES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Subir archivo al servidor
Write-Host "1. Subiendo archivo al servidor..." -ForegroundColor Yellow
scp $ARCHIVO_LOCAL "${SERVER_USER}@${SERVER_IP}:${ARCHIVO_SERVIDOR}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error subiendo archivo" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

Write-Host "2. Conecta al servidor y ejecuta:" -ForegroundColor Yellow
Write-Host "   ssh ${SERVER_USER}@${SERVER_IP}" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Luego en el servidor ejecuta:" -ForegroundColor Yellow
Write-Host "   CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1)" -ForegroundColor Gray
Write-Host "   docker cp /tmp/whatsapp-server-baileys.js `$CONTAINER_ID:/app/whatsapp-server-baileys.js" -ForegroundColor Gray
Write-Host "   docker restart `$CONTAINER_ID" -ForegroundColor Gray
Write-Host ""
