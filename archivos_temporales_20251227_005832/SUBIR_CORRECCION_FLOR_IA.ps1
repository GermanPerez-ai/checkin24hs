# Script para subir corrección "Flor IA" en el menú

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"

Write-Host "=== Subir Correccion: Flor IA en Menu ===" -ForegroundColor Cyan
Write-Host ""

# Verificar archivos
$FILES = @(
    "deploy\dashboard.html",
    "deploy\crm.html"
)

foreach ($FILE in $FILES) {
    if (-not (Test-Path $FILE)) {
        Write-Host "Advertencia: No se encuentra $FILE" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Subiendo $FILE..." -ForegroundColor Yellow
    
    if ($FILE -like "*dashboard.html") {
        scp $FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/dashboard.html"
    } elseif ($FILE -like "*crm.html") {
        scp $FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/crm.html"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Archivo subido correctamente" -ForegroundColor Green
    } else {
        Write-Host "  Error al subir archivo" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Para Dashboard:" -ForegroundColor White
Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=dashboard' --format '{{.ID}}' | head -1)" -ForegroundColor Cyan
Write-Host "  docker cp /root/checkin24hs/deploy/dashboard.html `$CONTAINER_ID:/app/dashboard.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Para CRM:" -ForegroundColor White
Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=crm' --format '{{.ID}}' | head -1)" -ForegroundColor Cyan
Write-Host "  docker cp /root/checkin24hs/deploy/crm.html `$CONTAINER_ID:/app/crm.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "Despues de aplicar, recarga con Ctrl+F5" -ForegroundColor Yellow






