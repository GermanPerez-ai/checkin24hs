# Subir dashboard.html correcto al servidor
Write-Host "=== SUBIR DASHBOARD CORRECTO ===" -ForegroundColor Green
Write-Host ""

# Verificar archivo local
if (-not (Test-Path "deploy/dashboard.html")) {
    Write-Host "ERROR: No se encuentra deploy/dashboard.html" -ForegroundColor Red
    exit 1
}

# Verificar contenido
$containsButtons = Select-String -Path "deploy/dashboard.html" -Pattern "whatsapp-config-button-main" -Quiet
if ($containsButtons) {
    Write-Host "Archivo local contiene botones de WhatsApp" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: Archivo local NO contiene botones de WhatsApp" -ForegroundColor Yellow
}

$fileSize = (Get-Item "deploy/dashboard.html").Length
Write-Host "Tamaño del archivo: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Cyan
Write-Host ""

Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow
scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "ARCHIVO SUBIDO EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta estos comandos en SSH:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host "CONTAINER=$(docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | head -1)" -ForegroundColor White
    Write-Host "docker cp deploy/dashboard.html `$CONTAINER:/app/dashboard.html" -ForegroundColor White
    Write-Host "docker service update --force checkin24hs_dashboard" -ForegroundColor White
    Write-Host "sleep 25" -ForegroundColor White
    Write-Host "curl -s https://dashboard.checkin24hs.com | grep -q 'whatsapp-config-button-main' && echo 'OK' || echo 'ERROR'" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
}
