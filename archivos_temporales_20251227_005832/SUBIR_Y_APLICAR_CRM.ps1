# Script para subir y aplicar serve-crm.js al servidor
# Uso: .\SUBIR_Y_APLICAR_CRM.ps1

$SERVER = "root@72.61.58.240"
$REMOTE_PATH = "/root/checkin24hs"

Write-Host "=== Subiendo archivos al servidor ===" -ForegroundColor Cyan

# Verificar que los archivos existen localmente
if (-not (Test-Path "serve-crm.js")) {
    Write-Host "ERROR: serve-crm.js no existe localmente" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "Dockerfile.crm")) {
    Write-Host "ERROR: Dockerfile.crm no existe localmente" -ForegroundColor Red
    exit 1
}

# Subir archivos
Write-Host "Subiendo serve-crm.js..." -ForegroundColor Yellow
scp serve-crm.js "${SERVER}:${REMOTE_PATH}/"

Write-Host "Subiendo Dockerfile.crm..." -ForegroundColor Yellow
scp Dockerfile.crm "${SERVER}:${REMOTE_PATH}/"

Write-Host "Subiendo APLICAR_SERVE_CRM_SERVIDOR.sh..." -ForegroundColor Yellow
if (Test-Path "APLICAR_SERVE_CRM_SERVIDOR.sh") {
    scp APLICAR_SERVE_CRM_SERVIDOR.sh "${SERVER}:${REMOTE_PATH}/"
}

Write-Host ""
Write-Host "=== Archivos subidos correctamente ===" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Cyan
Write-Host "  cd /root/checkin24hs" -ForegroundColor White
Write-Host "  chmod +x APLICAR_SERVE_CRM_SERVIDOR.sh" -ForegroundColor White
Write-Host "  ./APLICAR_SERVE_CRM_SERVIDOR.sh" -ForegroundColor White
Write-Host ""
Write-Host "O ejecuta manualmente:" -ForegroundColor Cyan
Write-Host "  CONTAINER_ID=`$(docker ps | grep checkin24hs_crm | awk '{print `$1}' | head -1)" -ForegroundColor White
Write-Host "  docker cp /root/checkin24hs/serve-crm.js `$CONTAINER_ID:/app/serve-crm.js" -ForegroundColor White
Write-Host "  docker service update --force checkin24hs_crm" -ForegroundColor White

