# Transferir script de verificacion al servidor
scp -o StrictHostKeyChecking=no verificar_dashboard_servidor.sh root@72.61.58.240:/root/checkin24hs/verificar_dashboard_servidor.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host "Script de verificacion transferido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conectate por SSH y ejecuta:" -ForegroundColor Cyan
    Write-Host "  ssh root@72.61.58.240" -ForegroundColor White
    Write-Host "  cd /root/checkin24hs" -ForegroundColor White
    Write-Host "  chmod +x verificar_dashboard_servidor.sh" -ForegroundColor White
    Write-Host "  bash verificar_dashboard_servidor.sh" -ForegroundColor White
} else {
    Write-Host "Error al transferir el script" -ForegroundColor Red
}


