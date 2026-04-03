# Script PowerShell para subir y aplicar solución definitiva

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "=== SUBIENDO ARCHIVO CORREGIDO ===" -ForegroundColor Cyan
Write-Host ""

# Subir archivo
Write-Host "Subiendo dashboard.html..." -ForegroundColor Yellow
scp "$rutaLocal\deploy\dashboard.html" "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== APLICANDO EN SERVIDOR ===" -ForegroundColor Cyan
    
    # Ejecutar comandos en el servidor
    Write-Host "Ejecutando comandos en el servidor..." -ForegroundColor Yellow
    
    # Crear script bash temporal en el servidor
    $scriptBash = @'
cd /root/checkin24hs
echo "Verificando línea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "Aplicando a todos los contenedores..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container
    echo "✅ $container actualizado"
done
echo ""
echo "✅ PROCESO COMPLETADO"
'@
    
    # Guardar script temporalmente
    $scriptBash | ssh $servidor "cat > /tmp/aplicar_dashboard.sh && chmod +x /tmp/aplicar_dashboard.sh && bash /tmp/aplicar_dashboard.sh && rm /tmp/aplicar_dashboard.sh"
} else {
    Write-Host "❌ Error subiendo archivo" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FINALIZADO ===" -ForegroundColor Green
Write-Host "Abre https://dashboard.checkin24hs.com/ en modo incognito y verifica"

