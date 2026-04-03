# Script para reiniciar el servicio de WhatsApp
$server = "root@72.61.58.240"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "REINICIANDO SERVICIO DE WHATSAPP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Conectando al servidor..." -ForegroundColor Yellow
Write-Host "Cuando te pida la contraseña, ingresala" -ForegroundColor Green
Write-Host ""

ssh $server "CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1); if [ -n \"`$CONTAINER\" ]; then echo 'Reiniciando contenedor: '`$CONTAINER; docker restart `$CONTAINER; sleep 5; echo ''; echo 'Verificando estado...'; docker logs `$CONTAINER --tail 10; else echo 'ERROR: No se encontro contenedor de WhatsApp'; fi"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Servicio reiniciado" -ForegroundColor Green
    Write-Host ""
    Write-Host "Espera 30 segundos y luego prueba enviar un mensaje de WhatsApp" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Error al reiniciar el servicio" -ForegroundColor Red
}


