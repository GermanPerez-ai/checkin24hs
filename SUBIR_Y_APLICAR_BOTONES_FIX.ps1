# Script para subir dashboard.html corregido y aplicar a todos los contenedores

$serverIP = "72.61.58.240"
$serverUser = "root"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"
$scriptPath = "/root/checkin24hs/APLICAR_DASHBOARD_BOTONES_FIX.sh"

Write-Host "=== SUBIENDO DASHBOARD CORREGIDO ===" -ForegroundColor Cyan
Write-Host ""

# Subir dashboard.html
Write-Host "Subiendo dashboard.html..." -ForegroundColor Yellow
scp $localFile "${serverUser}@${serverIP}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== APLICANDO CAMBIOS EN EL SERVIDOR ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ejecuta estos comandos en SSH:" -ForegroundColor Yellow
Write-Host ""
Write-Host "cd /root/checkin24hs" -ForegroundColor White
Write-Host "chmod +x APLICAR_DASHBOARD_BOTONES_FIX.sh" -ForegroundColor White
Write-Host "bash APLICAR_DASHBOARD_BOTONES_FIX.sh" -ForegroundColor White
Write-Host ""







