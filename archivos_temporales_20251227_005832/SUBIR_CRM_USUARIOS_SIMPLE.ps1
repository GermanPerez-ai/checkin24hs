# Script para subir correcciones de Usuarios en CRM

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"

Write-Host "=== Subir Correcciones: Usuarios CRM ===" -ForegroundColor Cyan
Write-Host ""

$FILES = @(
    "deploy\crm.html",
    "deploy\crm.js"
)

foreach ($FILE in $FILES) {
    if (-not (Test-Path $FILE)) {
        Write-Host "Advertencia: No se encuentra $FILE" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Subiendo $FILE..." -ForegroundColor Yellow
    
    if ($FILE -like "*crm.html") {
        scp $FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/crm.html"
    } elseif ($FILE -like "*crm.js") {
        scp $FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/crm.js"
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
Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=crm' --format '{{.ID}}' | head -1)" -ForegroundColor Cyan
Write-Host "  docker cp /root/checkin24hs/deploy/crm.html `$CONTAINER_ID:/app/crm.html" -ForegroundColor Cyan
Write-Host "  docker cp /root/checkin24hs/deploy/crm.js `$CONTAINER_ID:/app/crm.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "Despues de aplicar, recarga el CRM con Ctrl+F5" -ForegroundColor Yellow






