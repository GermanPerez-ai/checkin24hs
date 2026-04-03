# Script para subir dashboard.html y aplicar correccion de buildServerURL

Write-Host "Subiendo dashboard.html al servidor..." -ForegroundColor Cyan

$serverIP = "72.61.58.240"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"

# Verificar que el archivo existe
if (-not (Test-Path $localFile)) {
    Write-Host "Error: No se encuentra el archivo $localFile" -ForegroundColor Red
    exit 1
}

# Verificar que buildServerURL esta en el archivo
$content = Get-Content $localFile -Raw
if ($content -notmatch "window\.buildServerURL") {
    Write-Host "Advertencia: window.buildServerURL no encontrado en el archivo" -ForegroundColor Yellow
    Write-Host "   El archivo puede no tener la correccion aplicada" -ForegroundColor Yellow
}

# Subir archivo
Write-Host "Subiendo archivo..." -ForegroundColor Yellow
scp $localFile "root@${serverIP}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Conecta por SSH al servidor:" -ForegroundColor White
    Write-Host "   ssh root@${serverIP}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Ejecuta el script de aplicacion:" -ForegroundColor White
    Write-Host "   cd /root/checkin24hs" -ForegroundColor Gray
    Write-Host "   chmod +x APLICAR_BUILDSERVERURL_COMPLETO.sh" -ForegroundColor Gray
    Write-Host "   bash APLICAR_BUILDSERVERURL_COMPLETO.sh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. O ejecuta manualmente:" -ForegroundColor White
    Write-Host "   docker stop `$(docker ps -q --filter 'name=checkin24hs_dashboard')" -ForegroundColor Gray
    Write-Host "   for container in `$(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do" -ForegroundColor Gray
    Write-Host "     docker cp deploy/dashboard.html `$container:/app/dashboard.html" -ForegroundColor Gray
    Write-Host "   done" -ForegroundColor Gray
    Write-Host "   docker start `$(docker ps -aq --filter 'name=checkin24hs_dashboard')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Recarga el dashboard con Ctrl+Shift+R (hard reload)" -ForegroundColor White
} else {
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    exit 1
}

