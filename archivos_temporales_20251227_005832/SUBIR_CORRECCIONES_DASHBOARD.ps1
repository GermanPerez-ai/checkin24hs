# Script para subir correcciones del Dashboard
$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$LOCAL_FILE = "deploy\dashboard.html"

Write-Host "=== Subir correcciones del Dashboard ===" -ForegroundColor Cyan

if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "❌ Error: No se encuentra el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Subiendo dashboard.html..." -ForegroundColor Yellow
scp $LOCAL_FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Yellow
    Write-Host "  CONTAINER_ID=`$(docker ps --filter 'name=dashboard' --format '{{.ID}}' | head -1)" -ForegroundColor White
    Write-Host "  docker cp /root/checkin24hs/deploy/dashboard.html `$CONTAINER_ID:/app/dashboard.html" -ForegroundColor White
    Write-Host "  docker exec `$CONTAINER_ID grep -n 'const todayStr = year' /app/dashboard.html | head -1" -ForegroundColor White
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}






