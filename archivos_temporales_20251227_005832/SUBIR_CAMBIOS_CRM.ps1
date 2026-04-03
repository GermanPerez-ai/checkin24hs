# Script para subir cambios del CRM al servidor
# Ejecutar desde PowerShell en Windows

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$SERVER_PATH = "/root/checkin24hs/deploy"
$LOCAL_FILE = "deploy\crm.js"

Write-Host "=== Subir cambios del CRM al servidor ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "❌ Error: No se encuentra el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "1. Subiendo archivo crm.js al servidor..." -ForegroundColor Yellow
scp $LOCAL_FILE "${SERVER_USER}@${SERVER_IP}:${SERVER_PATH}/crm.js"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Ejecutando script en el servidor para aplicar cambios..." -ForegroundColor Yellow

# Crear comando SSH para aplicar cambios
$sshCommand = "cd $SERVER_PATH; echo 'Archivo recibido, verificando...'; ls -lh crm.js; echo ''; echo 'Copiando al contenedor del CRM...'; CONTAINER_ID=`$(docker ps --filter 'name=crm' --format '{{.ID}}' | head -1); if [ ! -z `"`$CONTAINER_ID`" ]; then docker cp crm.js `$CONTAINER_ID:/app/crm.js; echo 'Archivo copiado al contenedor: '`$CONTAINER_ID; echo ''; echo 'Verificando que se copió correctamente...'; docker exec `$CONTAINER_ID ls -lh /app/crm.js; echo ''; echo 'Cambios aplicados. Recarga la página del CRM para ver los cambios.'; else echo 'No se encontró contenedor del CRM corriendo'; echo 'Los cambios se aplicarán cuando se reinicie el servicio'; fi"

ssh "${SERVER_USER}@${SERVER_IP}" $sshCommand

Write-Host ""
Write-Host "=== Proceso completado ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora puedes:" -ForegroundColor Yellow
Write-Host "1. Abrir https://crm.checkin24hs.com" -ForegroundColor White
Write-Host "2. Recargar la página (Ctrl+F5 para forzar recarga sin caché)" -ForegroundColor White
Write-Host "3. Verificar en la consola del navegador que aparezcan los mensajes:" -ForegroundColor White
Write-Host "   - '[CRM] 🔄 Inicializando suscripciones en tiempo real...'" -ForegroundColor Gray
Write-Host "   - '[CRM] ✅ Suscrito a chats de WhatsApp'" -ForegroundColor Gray
Write-Host "   - '[CRM] ✅ Suscrito a mensajes de WhatsApp'" -ForegroundColor Gray
Write-Host "   - '[CRM] ✅ Suscrito a interacciones de Flor'" -ForegroundColor Gray

