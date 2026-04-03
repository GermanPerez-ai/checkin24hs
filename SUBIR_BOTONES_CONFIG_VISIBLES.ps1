# Script para subir dashboard.html con botones de configuracion siempre visibles

Write-Host "Subiendo dashboard.html al servidor..." -ForegroundColor Cyan

scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Conectate al servidor SSH:" -ForegroundColor White
    Write-Host "   ssh root@72.61.58.240" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Ejecuta el script de aplicacion:" -ForegroundColor White
    Write-Host "   cd /root/checkin24hs" -ForegroundColor Gray
    Write-Host "   bash APLICAR_BOTONES_CONFIG_VISIBLES.sh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Recarga la pagina del dashboard (Ctrl+F5)" -ForegroundColor White
    Write-Host "4. Ve a la pestana 'WhatsApp' en Flor IA" -ForegroundColor White
    Write-Host "5. Deberias ver el boton de configuracion siempre visible" -ForegroundColor White
} else {
    Write-Host "Error al subir el archivo" -ForegroundColor Red
}

