Write-Host "=== APLICANDO BOTON AL SERVIDOR ===" -ForegroundColor Green
Write-Host ""
Write-Host "Subiendo archivo..." -ForegroundColor Yellow
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido" -ForegroundColor Green
    Write-Host ""
    Write-Host "Aplicando a contenedores..." -ForegroundColor Yellow
    
    $scriptBash = 'cd /root/checkin24hs && for c in $(docker ps --format "{{.Names}}" | grep checkin24hs_dashboard); do echo "Procesando $c"; docker stop $c 2>/dev/null; docker cp deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null || docker cp deploy/dashboard.html $c:/usr/share/nginx/html/dashboard.html 2>/dev/null; docker start $c 2>/dev/null; echo "✅ $c actualizado"; done'
    
    ssh root@72.61.58.240 $scriptBash
    
    Write-Host ""
    Write-Host "=== COMPLETADO ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "AHORA:" -ForegroundColor Yellow
    Write-Host "  1. Cierra y abre el navegador" -ForegroundColor White
    Write-Host "  2. Ve a: Flor IA -> WhatsApp" -ForegroundColor White
    Write-Host "  3. Busca el boton NARANJA arriba a la derecha" -ForegroundColor Green
} else {
    Write-Host "❌ Error" -ForegroundColor Red
}










