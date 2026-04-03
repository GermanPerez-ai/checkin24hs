# Script para subir y ejecutar CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh

Write-Host "=== Subiendo CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh al servidor ===" -ForegroundColor Cyan

# Subir archivo
Write-Host "`n1. Subiendo archivo..." -ForegroundColor Yellow
scp CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh root@72.61.58.240:/root/checkin24hs/

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Archivo subido correctamente" -ForegroundColor Green
    
    # Dar permisos de ejecución
    Write-Host "`n2. Dando permisos de ejecución..." -ForegroundColor Yellow
    ssh root@72.61.58.240 "chmod +x /root/checkin24hs/CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Permisos configurados" -ForegroundColor Green
        
        # Verificar que existe
        Write-Host "`n3. Verificando archivo..." -ForegroundColor Yellow
        ssh root@72.61.58.240 "ls -lh /root/checkin24hs/CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"
        
        Write-Host "`n=== COMPLETADO ===" -ForegroundColor Green
        Write-Host "`nAhora puedes ejecutar en el servidor:" -ForegroundColor Cyan
        Write-Host "  cd /root/checkin24hs" -ForegroundColor White
        Write-Host "  bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh" -ForegroundColor White
    } else {
        Write-Host "   ❌ Error al dar permisos" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Error al subir archivo" -ForegroundColor Red
    Write-Host "`nIntenta ejecutar manualmente:" -ForegroundColor Yellow
    Write-Host "  scp CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh root@72.61.58.240:/root/checkin24hs/" -ForegroundColor White
}






