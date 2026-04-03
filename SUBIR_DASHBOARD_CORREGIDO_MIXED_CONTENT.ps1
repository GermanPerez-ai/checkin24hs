# Script para subir dashboard.html corregido (solucion Mixed Content)
# Ejecutar desde PowerShell en: C:\Users\German\Downloads\Checkin24hs

Write-Host "=== SUBIR DASHBOARD CORREGIDO (SOLUCION MIXED CONTENT) ===" -ForegroundColor Green
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "deploy\dashboard.html")) {
    Write-Host "ERROR: No se encuentra deploy\dashboard.html" -ForegroundColor Red
    Write-Host "Asegurate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "Archivo encontrado" -ForegroundColor Green
Write-Host ""
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow

scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "ARCHIVO SUBIDO EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conecta por SSH y copia el archivo a los contenedores:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ssh root@72.61.58.240" -ForegroundColor White
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host 'docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do docker cp deploy/dashboard.html $container:/app/dashboard.html; echo "Copiado a $container"; done' -ForegroundColor White
    Write-Host 'docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do docker restart $container; echo "Reiniciado $container"; done' -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANTE: Asegurate de que los subdominios HTTPS esten configurados:" -ForegroundColor Yellow
    Write-Host "- https://api1.checkin24hs.com -> puerto 3001" -ForegroundColor White
    Write-Host "- https://api2.checkin24hs.com -> puerto 3002" -ForegroundColor White
    Write-Host "- https://api3.checkin24hs.com -> puerto 3003" -ForegroundColor White
    Write-Host "- https://api4.checkin24hs.com -> puerto 3004" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
}

Write-Host ""

