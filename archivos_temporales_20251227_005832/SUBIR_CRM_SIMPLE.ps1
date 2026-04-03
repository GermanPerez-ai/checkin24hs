# Script simple para subir crm.js al servidor
$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$LOCAL_FILE = "deploy\crm.js"

Write-Host "=== Subir crm.js al servidor ===" -ForegroundColor Cyan

# Verificar que el archivo existe
if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "❌ Error: No se encuentra el archivo $LOCAL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Subiendo archivo..." -ForegroundColor Yellow
scp $LOCAL_FILE "${SERVER_USER}@${SERVER_IP}:/root/checkin24hs/deploy/crm.js"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Yellow
    Write-Host "  cd /root/checkin24hs/deploy" -ForegroundColor White
    Write-Host "  chmod +x APLICAR_CAMBIOS_CRM_SERVIDOR.sh" -ForegroundColor White
    Write-Host "  ./APLICAR_CAMBIOS_CRM_SERVIDOR.sh" -ForegroundColor White
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}






