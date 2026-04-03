# Script para subir dashboard.html actualizado al servidor

$server = "root@72.61.58.240"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"
$localFile = "deploy\dashboard.html"

Write-Host "Subiendo dashboard actualizado..." -ForegroundColor Cyan

# Verificar que el archivo local existe
if (-not (Test-Path $localFile)) {
    Write-Host "ERROR: No se encontro: $localFile" -ForegroundColor Red
    exit 1
}

# Obtener tamaño del archivo local
$localSize = (Get-Item $localFile).Length
Write-Host "Tamanio del archivo local: $localSize bytes" -ForegroundColor Yellow

# Subir archivo
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no $localFile "${server}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
} else {
    Write-Host "Error al subir archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "1. Conectarse al servidor: ssh root@72.61.58.240" -ForegroundColor White
Write-Host "2. Ejecutar: cd /root/checkin24hs" -ForegroundColor White
Write-Host "3. Ejecutar: bash ACTUALIZAR_DASHBOARD_CONTENEDOR.sh" -ForegroundColor White
Write-Host "4. Limpiar cache del navegador (Ctrl+Shift+R)" -ForegroundColor White
