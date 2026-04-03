# Script para subir dashboard.html con corrección de URL de WhatsApp

Write-Host "📤 Subiendo dashboard.html al servidor..." -ForegroundColor Cyan

$serverIP = "72.61.58.240"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"

# Verificar que el archivo existe
if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encuentra el archivo $localFile" -ForegroundColor Red
    exit 1
}

# Subir archivo
Write-Host "📋 Subiendo archivo..." -ForegroundColor Yellow
scp $localFile "root@${serverIP}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Conecta por SSH al servidor:" -ForegroundColor White
    Write-Host "   ssh root@${serverIP}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Ejecuta el script de aplicación:" -ForegroundColor White
    Write-Host "   cd /root/checkin24hs" -ForegroundColor Gray
    Write-Host "   bash APLICAR_DASHBOARD_URL_FIX.sh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Recarga el dashboard con Ctrl+Shift+R (hard reload)" -ForegroundColor White
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}








