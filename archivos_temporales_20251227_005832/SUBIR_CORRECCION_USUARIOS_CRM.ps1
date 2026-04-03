# Script para subir corrección "Usuarios" en lugar de "Clientes" en el CRM

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$LOCAL_FILE = "deploy\crm.html"

Write-Host "=== Subir Correccion: Usuarios en CRM ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "Error: No se encuentra el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Subiendo crm.html corregido..." -ForegroundColor Yellow
Write-Host "   - Cambiado: Clientes -> Usuarios" -ForegroundColor Gray
Write-Host ""

# Subir archivo
scp $LOCAL_FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/crm.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  # Copiar al contenedor CRM" -ForegroundColor White
    Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=crm' --format '{{.ID}}' | head -1)" -ForegroundColor Cyan
    Write-Host "  docker cp /root/checkin24hs/deploy/crm.html `$CONTAINER_ID:/app/crm.html" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Verificar correccion" -ForegroundColor White
    Write-Host "  docker exec `$CONTAINER_ID grep -n 'Usuarios' /app/crm.html | grep 'menu-item' | head -1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Despues de aplicar, recarga el CRM con Ctrl+F5" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    exit 1
}






