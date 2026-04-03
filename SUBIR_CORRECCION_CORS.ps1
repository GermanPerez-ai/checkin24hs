# Script para subir corrección de CORS al servidor
$server = "root@72.61.58.240"
$remotePath = "/root/checkin24hs/whatsapp-server/whatsapp-server.js"
$localFile = "whatsapp-server/whatsapp-server.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📤 SUBIENDO CORRECCIÓN DE CORS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encontró el archivo $localFile" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Archivo local: $localFile" -ForegroundColor Yellow
Write-Host "📋 Servidor: $server" -ForegroundColor Yellow
Write-Host "📋 Ruta remota: $remotePath" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔄 Subiendo archivo..." -ForegroundColor Yellow
scp $localFile "${server}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Archivo subido exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔄 Reiniciando contenedores de WhatsApp..." -ForegroundColor Yellow
    
    # Reiniciar contenedores
    ssh $server "docker ps --filter 'name=whatsapp' --format '{{.Names}}' | xargs -r docker restart"
    
    Write-Host ""
    Write-Host "✅ Corrección de CORS aplicada" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Espera unos segundos a que los contenedores se reinicien" -ForegroundColor White
    Write-Host "2. Prueba hacer clic en los botones de WhatsApp en el dashboard" -ForegroundColor White
    Write-Host "3. El error de CORS debería estar resuelto" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}




