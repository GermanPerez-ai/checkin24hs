# Script para subir correcciones finales del Dashboard
# Corrige: loadWhatsAppCards y Mixed Content (HTTP -> HTTPS)

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$LOCAL_FILE = "deploy\dashboard.html"

Write-Host "=== Subir Correcciones Finales del Dashboard ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "Error: No se encuentra el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Subiendo dashboard.html corregido..." -ForegroundColor Yellow
Write-Host "   - Corregido: loadWhatsAppCards (comentado)" -ForegroundColor Gray
Write-Host "   - Corregido: Mixed Content (HTTP -> HTTPS)" -ForegroundColor Gray
Write-Host ""

# Subir archivo
scp $LOCAL_FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta estos comandos en el servidor:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  # Copiar al contenedor" -ForegroundColor White
    Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=dashboard' --format '{{.ID}}' | head -1)" -ForegroundColor Cyan
    Write-Host "  docker cp /root/checkin24hs/deploy/dashboard.html `$CONTAINER_ID:/app/dashboard.html" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Verificar correcciones" -ForegroundColor White
    Write-Host "  docker exec `$CONTAINER_ID grep -n '// window.loadWhatsAppCards' /app/dashboard.html | head -1" -ForegroundColor Cyan
    Write-Host "  docker exec `$CONTAINER_ID grep -n 'whatsapp1.checkin24hs.com' /app/dashboard.html | head -1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Despues de aplicar, recarga el Dashboard con Ctrl+F5" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    Write-Host "   Verifica la conexion SSH y las credenciales" -ForegroundColor Gray
    exit 1
}
