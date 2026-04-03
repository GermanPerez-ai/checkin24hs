# Script para subir dashboard.html con correccion de QRCode
Write-Host "=== SUBIR DASHBOARD CON CORRECCION DE QRCODE ===" -ForegroundColor Green
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path "deploy\dashboard.html")) {
    Write-Host "ERROR: No se encuentra deploy\dashboard.html" -ForegroundColor Red
    exit 1
}

Write-Host "Archivo encontrado" -ForegroundColor Green
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow

# Subir archivo
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host "ARCHIVO SUBIDO EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conecta por SSH y aplica el archivo a los contenedores:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ssh root@72.61.58.240" -ForegroundColor Cyan
    Write-Host "cd /root/checkin24hs" -ForegroundColor Cyan
    Write-Host "docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | while read container; do" -ForegroundColor Cyan
    Write-Host "  docker cp deploy/dashboard.html `$container:/app/dashboard.html" -ForegroundColor Cyan
    Write-Host "  docker restart `$container" -ForegroundColor Cyan
    Write-Host "done" -ForegroundColor Cyan
} else {
    Write-Host "ERROR al subir el archivo" -ForegroundColor Red
}

