# Script para subir archivos mejorados de Flor IA al servidor
$server = "root@72.61.58.240"
$remotePath = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SUBIENDO FLOR IA MEJORADA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Archivos a subir
$files = @(
    @{
        local = "flor-ai-service.js"
        remote = "$remotePath/flor-ai-service.js"
        description = "Servicio de IA mejorado (desarrollo)"
    },
    @{
        local = "deploy/flor-ai-service.js"
        remote = "$remotePath/deploy/flor-ai-service.js"
        description = "Servicio de IA mejorado (produccion)"
    }
)

$uploaded = 0
$failed = 0

foreach ($file in $files) {
    if (-not (Test-Path $file.local)) {
        Write-Host "ADVERTENCIA: No se encontro $($file.local)" -ForegroundColor Yellow
        Write-Host "  Saltando este archivo..." -ForegroundColor Gray
        $failed++
        continue
    }

    Write-Host "Subiendo: $($file.description)" -ForegroundColor Yellow
    Write-Host "  Archivo: $($file.local)" -ForegroundColor Gray
    Write-Host "  Destino: $($file.remote)" -ForegroundColor Gray
    
    scp $file.local "${server}:$($file.remote)"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: Archivo subido exitosamente" -ForegroundColor Green
        $uploaded++
    } else {
        Write-Host "  ERROR: Fallo al subir archivo" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Archivos subidos: $uploaded" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Archivos fallidos: $failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "1. Reinicia el servicio de WhatsApp en el servidor" -ForegroundColor White
Write-Host "2. Configura la API Key de Gemini en el dashboard" -ForegroundColor White
Write-Host "3. Prueba con un mensaje de ejemplo" -ForegroundColor White
Write-Host ""
Write-Host "Para reiniciar el servicio:" -ForegroundColor Yellow
Write-Host "  CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1)" -ForegroundColor Gray
Write-Host "  docker restart `$CONTAINER" -ForegroundColor Gray


