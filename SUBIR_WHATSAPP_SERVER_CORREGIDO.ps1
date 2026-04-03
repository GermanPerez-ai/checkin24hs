# Script para subir whatsapp-server.js corregido al servidor
# Ejecutar desde PowerShell en: C:\Users\German\Downloads\Checkin24hs

Write-Host "=== SUBIR WHATSAPP-SERVER.JS CORREGIDO ===" -ForegroundColor Green
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "whatsapp-server\whatsapp-server.js")) {
    Write-Host "ERROR: No se encuentra whatsapp-server\whatsapp-server.js" -ForegroundColor Red
    Write-Host "Asegúrate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Archivo encontrado" -ForegroundColor Green
Write-Host ""
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow

scp whatsapp-server\whatsapp-server.js root@72.61.58.240:/root/checkin24hs/whatsapp-server/whatsapp-server.js

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅✅✅ ARCHIVO SUBIDO EXITOSAMENTE ✅✅✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conecta por SSH y copia el archivo a los contenedores:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ssh root@72.61.58.240" -ForegroundColor White
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host "docker ps --filter 'name=whatsapp' --format '{{.Names}}' | ForEach-Object { docker cp whatsapp-server/whatsapp-server.js `$_:/app/whatsapp-server.js }" -ForegroundColor White
    Write-Host "docker ps --filter 'name=whatsapp' --format '{{.Names}}' | ForEach-Object { docker restart `$_ }" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
}

Write-Host ""








