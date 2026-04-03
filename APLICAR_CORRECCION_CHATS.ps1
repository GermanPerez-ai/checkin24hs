# Script PowerShell para aplicar corrección de chats al servidor

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_TEMP = "/tmp/whatsapp-server-baileys.js"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "APLICAR CORRECCIÓN DE CHATS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $ARCHIVO_LOCAL)) {
    Write-Host "ERROR: No se encontro el archivo: $ARCHIVO_LOCAL" -ForegroundColor Red
    Write-Host "Asegurate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "Paso 1: Subiendo archivo corregido al servidor..." -ForegroundColor Yellow
Write-Host "(Se te pedira la contraseña SSH)" -ForegroundColor Gray
Write-Host ""

scp $ARCHIVO_LOCAL "${SERVER_USER}@${SERVER_IP}:${ARCHIVO_TEMP}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Paso 2: Aplicando archivo en el contenedor..." -ForegroundColor Yellow
Write-Host "(Se te pedira la contraseña SSH nuevamente)" -ForegroundColor Gray
Write-Host ""

# Comando para aplicar el archivo (usar comillas simples para evitar interpretación de PowerShell)
$applyCommand = 'CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk ''{print $1}'' | head -1); if [ -z "$CONTAINER_ID" ]; then echo "ERROR: No se encontro contenedor"; exit 1; fi; echo "Contenedor encontrado: $CONTAINER_ID"; echo "Haciendo backup..."; docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S); echo "Copiando archivo corregido..."; docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js; echo "Reiniciando contenedor..."; docker restart $CONTAINER_ID; echo "OK: Archivo aplicado y contenedor reiniciado"'

$result = ssh "${SERVER_USER}@${SERVER_IP}" $applyCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: No se pudo aplicar el archivo" -ForegroundColor Red
    Write-Host "Resultado:" -ForegroundColor Yellow
    Write-Host $result -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Resultado:" -ForegroundColor Gray
Write-Host $result -ForegroundColor White

Write-Host ""
Write-Host "Paso 3: Esperando reinicio del contenedor..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Paso 4: Verificando logs..." -ForegroundColor Yellow
Write-Host "(Se te pedira la contraseña SSH una vez mas)" -ForegroundColor Gray

$logsCommand = 'CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk ''{print $1}'' | head -1); docker logs $CONTAINER_ID --tail 20 | grep -E "(Iniciando|chat|conversation|error)"'

$logs = ssh "${SERVER_USER}@${SERVER_IP}" $logsCommand
Write-Host $logs -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "CORRECCIÓN APLICADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora:" -ForegroundColor Cyan
Write-Host "  1. Envia un mensaje de prueba a Flor por WhatsApp" -ForegroundColor White
Write-Host "  2. Espera 5-10 segundos" -ForegroundColor White
Write-Host "  3. Abre el dashboard y ve a la seccion 'Chats'" -ForegroundColor White
Write-Host "  4. Haz clic en 'Actualizar'" -ForegroundColor White
Write-Host "  5. Debe aparecer el contacto y la conversacion" -ForegroundColor White
Write-Host ""
