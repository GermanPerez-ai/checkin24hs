# ============================================
# SUBIR CORRECCIÓN DE MENSAJES AL SERVIDOR
# ============================================

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$REMOTE_PATH = "/root/checkin24hs/whatsapp-server/"
$LOCAL_FILE = "whatsapp-server/whatsapp-server.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📤 SUBIENDO CORRECCIÓN DE MENSAJES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "❌ Error: No se encontró el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Archivo local: $LOCAL_FILE" -ForegroundColor Yellow
$destino = "${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}"
Write-Host "📁 Destino remoto: $destino" -ForegroundColor Yellow
Write-Host ""

# Subir archivo
Write-Host "⏳ Subiendo archivo..." -ForegroundColor Yellow
scp "$LOCAL_FILE" "${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ejecuta en el servidor:" -ForegroundColor Yellow
    Write-Host "   CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1)" -ForegroundColor White
    Write-Host "   docker restart `$CONTAINER" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Ejecuta el script SQL en Supabase:" -ForegroundColor Yellow
    Write-Host "   CORREGIR_TABLA_WHATSAPP_MESSAGES.sql" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Verifica los logs:" -ForegroundColor Yellow
    Write-Host "   docker logs `$CONTAINER -f | grep -i 'mensaje\|error'" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}
