# Script PowerShell para subir y aplicar el fix de SSL
Write-Host "=== SUBIENDO Y APLICANDO FIX DE SSL ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo local existe
$archivoLocal = "deploy\dashboard.html"
if (-not (Test-Path $archivoLocal)) {
    Write-Host "❌ Error: No se encuentra el archivo $archivoLocal" -ForegroundColor Red
    exit 1
}

# Verificar que el archivo local tiene los cambios
Write-Host "📋 Verificando archivo local..." -ForegroundColor Yellow
$contenido = Get-Content $archivoLocal -Raw
if ($contenido -match "🔍 lastWhatsAppError:") {
    Write-Host "✅ Archivo local tiene los cambios de detección SSL" -ForegroundColor Green
} else {
    Write-Host "❌ Archivo local NO tiene los cambios" -ForegroundColor Red
    exit 1
}

# Subir archivo al servidor
Write-Host ""
Write-Host "📤 Subiendo archivo al servidor..." -ForegroundColor Yellow
$servidor = "root@72.61.58.240"
$rutaRemota = "/root/checkin24hs/deploy/dashboard.html"

try {
    scp $archivoLocal "${servidor}:${rutaRemota}"
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al subir archivo: $_" -ForegroundColor Red
    exit 1
}

# Instrucciones para aplicar en el servidor
Write-Host ""
Write-Host "=== SIGUIENTE PASO: Aplicar en el servidor ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Conéctate al servidor SSH y ejecuta:" -ForegroundColor Yellow
Write-Host ""
Write-Host "cd /root/checkin24hs" -ForegroundColor White
Write-Host "grep -q '🔍 lastWhatsAppError:' deploy/dashboard.html && echo '✅ Tiene cambios' || echo '❌ NO tiene cambios'" -ForegroundColor White
Write-Host ""
Write-Host "docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | xargs -r docker stop" -ForegroundColor White
Write-Host "sleep 3" -ForegroundColor White
Write-Host "docker ps -a --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | while read c; do" -ForegroundColor White
Write-Host "    docker cp /root/checkin24hs/deploy/dashboard.html `$c:/app/dashboard.html && echo '✅ `$c' || echo '❌ `$c'" -ForegroundColor White
Write-Host "done" -ForegroundColor White
Write-Host "docker ps -a --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | xargs -r docker start" -ForegroundColor White
Write-Host "sleep 5" -ForegroundColor White
Write-Host ""
Write-Host "docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | head -n 1 | xargs -I {} docker exec {} grep -q '🔍 lastWhatsAppError:' /app/dashboard.html && echo '✅ Cambios aplicados' || echo '❌ Cambios NO aplicados'" -ForegroundColor White
Write-Host ""






