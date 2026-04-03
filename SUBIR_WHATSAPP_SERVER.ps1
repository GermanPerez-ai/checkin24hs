# Script para subir whatsapp-server.js al servidor
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📤 SUBIENDO whatsapp-server.js AL SERVIDOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path "whatsapp-server/whatsapp-server.js")) {
    Write-Host "❌ Error: No se encuentra whatsapp-server/whatsapp-server.js" -ForegroundColor Red
    Write-Host "   Asegúrate de estar en el directorio del proyecto" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Archivo encontrado: whatsapp-server/whatsapp-server.js" -ForegroundColor Green
Write-Host ""
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow
Write-Host "   Servidor: root@72.61.58.240" -ForegroundColor Gray
Write-Host "   Destino: /root/checkin24hs/whatsapp-server/" -ForegroundColor Gray
Write-Host ""

# Subir archivo
scp whatsapp-server/whatsapp-server.js root@72.61.58.240:/root/checkin24hs/whatsapp-server/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Archivo subido exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Conecta al servidor:" -ForegroundColor Yellow
    Write-Host "   ssh root@72.61.58.240" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Reinicia los contenedores:" -ForegroundColor Yellow
    Write-Host "   docker ps --filter `"name=whatsapp`" --format `"{{.Names}}`" | xargs docker restart" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Monitorea los logs:" -ForegroundColor Yellow
    Write-Host "   CONTAINER=`$(docker ps --filter `"name=whatsapp.1`" --format `"{{.Names}}`" | head -1)" -ForegroundColor White
    Write-Host "   docker logs `"`$CONTAINER`" --tail 50 -f" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    Write-Host "   Verifica tu conexión SSH y credenciales" -ForegroundColor Yellow
}



