# Script para subir el segundo archivo: deploy/flor-ai-service.js
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "PASO 2: SUBIR deploy/flor-ai-service.js" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivo a subir: deploy/flor-ai-service.js" -ForegroundColor Yellow
Write-Host "Destino: root@72.61.58.240:/root/checkin24hs/deploy/flor-ai-service.js" -ForegroundColor Yellow
Write-Host ""
Write-Host "Cuando te pida la contraseña, ingresala (no veras los caracteres)" -ForegroundColor Green
Write-Host ""
Write-Host "Presiona Enter para continuar..." -ForegroundColor White
Read-Host

scp deploy/flor-ai-service.js root@72.61.58.240:/root/checkin24hs/deploy/flor-ai-service.js

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Segundo archivo subido exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "ARCHIVOS SUBIDOS CORRECTAMENTE" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Reinicia el servicio de WhatsApp" -ForegroundColor White
    Write-Host "2. Configura la API Key de Gemini en el dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "Para reiniciar el servicio, ejecuta:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File REINICIAR_WHATSAPP.ps1" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    Write-Host "Verifica:" -ForegroundColor Yellow
    Write-Host "  - Que tengas conexion a internet" -ForegroundColor Gray
    Write-Host "  - Que la contraseña sea correcta" -ForegroundColor Gray
    Write-Host "  - Que el servidor este accesible" -ForegroundColor Gray
}


