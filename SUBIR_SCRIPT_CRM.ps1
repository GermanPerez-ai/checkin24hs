# Script PowerShell para subir ELIMINAR_SERVICIO_CRM.sh al servidor

$servidorIP = "72.61.58.240"  # IP del servidor (según DNS de crm.checkin24hs.com)
$usuario = "root"
$archivo = "ELIMINAR_SERVICIO_CRM.sh"
$destino = "~/checkin24hs/"

Write-Host "Subiendo $archivo al servidor..." -ForegroundColor Cyan

# Intentar con la IP
scp $archivo "${usuario}@${servidorIP}:${destino}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host "`nAhora ejecuta en el servidor:" -ForegroundColor Yellow
    Write-Host "  cd ~/checkin24hs" -ForegroundColor White
    Write-Host "  chmod +x ELIMINAR_SERVICIO_CRM.sh" -ForegroundColor White
    Write-Host "  ./ELIMINAR_SERVICIO_CRM.sh" -ForegroundColor White
} else {
    Write-Host "`n❌ Error al subir el archivo" -ForegroundColor Red
    Write-Host "`nAlternativa: Ejecuta los comandos manualmente en el servidor" -ForegroundColor Yellow
}
