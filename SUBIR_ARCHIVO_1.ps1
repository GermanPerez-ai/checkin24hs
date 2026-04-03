# Script para subir el primer archivo: flor-ai-service.js
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "PASO 1: SUBIR flor-ai-service.js" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivo a subir: flor-ai-service.js" -ForegroundColor Yellow
Write-Host "Destino: root@72.61.58.240:/root/checkin24hs/flor-ai-service.js" -ForegroundColor Yellow
Write-Host ""
Write-Host "Cuando te pida la contraseña, ingresala (no veras los caracteres)" -ForegroundColor Green
Write-Host ""
Write-Host "Presiona Enter para continuar..." -ForegroundColor White
Read-Host

scp flor-ai-service.js root@72.61.58.240:/root/checkin24hs/flor-ai-service.js

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Primer archivo subido exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta: powershell -ExecutionPolicy Bypass -File SUBIR_ARCHIVO_2.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    Write-Host "Verifica:" -ForegroundColor Yellow
    Write-Host "  - Que tengas conexion a internet" -ForegroundColor Gray
    Write-Host "  - Que la contraseña sea correcta" -ForegroundColor Gray
    Write-Host "  - Que el servidor este accesible" -ForegroundColor Gray
}


