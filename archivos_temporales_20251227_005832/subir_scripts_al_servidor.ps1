# Script PowerShell para subir los scripts al servidor
# Ejecuta este script desde PowerShell en tu computadora

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$REMOTE_PATH = "/root"

Write-Host "Subiendo scripts al servidor..." -ForegroundColor Cyan
Write-Host ""

# Verificar que los archivos existen
$webmailScript = "actualizar_webmail_traefik.sh"
$dashboardScript = "actualizar_dashboard_traefik.sh"

if (-not (Test-Path $webmailScript)) {
    Write-Host "Error: No se encuentra $webmailScript" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $dashboardScript)) {
    Write-Host "Error: No se encuentra $dashboardScript" -ForegroundColor Red
    exit 1
}

# Subir webmail script
Write-Host "Subiendo $webmailScript..." -ForegroundColor Yellow
scp $webmailScript "${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$webmailScript subido correctamente" -ForegroundColor Green
} else {
    Write-Host "Error al subir $webmailScript" -ForegroundColor Red
    Write-Host "Asegurate de tener acceso SSH configurado" -ForegroundColor Yellow
    exit 1
}

# Subir dashboard script
Write-Host "Subiendo $dashboardScript..." -ForegroundColor Yellow
scp $dashboardScript "${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "$dashboardScript subido correctamente" -ForegroundColor Green
} else {
    Write-Host "Error al subir $dashboardScript" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Scripts subidos correctamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta estos comandos en el servidor (SSH):" -ForegroundColor Cyan
Write-Host "chmod +x /root/actualizar_webmail_traefik.sh" -ForegroundColor White
Write-Host "chmod +x /root/actualizar_dashboard_traefik.sh" -ForegroundColor White
Write-Host ""
Write-Host "Para probar:" -ForegroundColor Cyan
Write-Host "/root/actualizar_webmail_traefik.sh" -ForegroundColor White
