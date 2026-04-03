# Script para aplicar el botón de configuración de WhatsApp al servidor
$servidor = "root@72.61.58.240"
$rutaLocal = "deploy/dashboard.html"
$rutaServidor = "/root/checkin24hs/deploy/dashboard.html"

Write-Host ""
Write-Host "=== APLICANDO BOTON DE CONFIGURACION AL SERVIDOR ===" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $rutaLocal)) {
    Write-Host "❌ Error: No se encuentra el archivo $rutaLocal" -ForegroundColor Red
    exit 1
}

Write-Host "📤 Subiendo dashboard.html al servidor..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no $rutaLocal "${servidor}:${rutaServidor}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔄 Aplicando cambios a los contenedores..." -ForegroundColor Yellow
    
    # Crear script bash temporal
    $bashContent = @'
#!/bin/bash
echo "Buscando contenedores de dashboard..."
containers=$(docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.ID}}")

if [ -z "$containers" ]; then
    echo "⚠️ No se encontraron contenedores de dashboard"
    exit 1
fi

echo "Contenedores encontrados: $(echo $containers | wc -w)"

for container in $containers; do
    echo "📦 Procesando contenedor: $container"
    docker stop $container 2>/dev/null
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/usr/share/nginx/html/dashboard.html 2>/dev/null || docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker start $container 2>/dev/null
    echo "✅ Contenedor $container actualizado"
done

echo ""
echo "✅ Todos los contenedores actualizados"
'@
    
    $bashContent | Out-File -FilePath "APLICAR_BOTON_TEMP.sh" -Encoding UTF8 -NoNewline
    scp -o StrictHostKeyChecking=no APLICAR_BOTON_TEMP.sh "${servidor}:/tmp/APLICAR_BOTON_TEMP.sh"
    ssh -o StrictHostKeyChecking=no $servidor "chmod +x /tmp/APLICAR_BOTON_TEMP.sh && bash /tmp/APLICAR_BOTON_TEMP.sh"
    
    Remove-Item "APLICAR_BOTON_TEMP.sh" -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=== ✅ COMPLETADO ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "El botón de configuración está ahora en el servidor." -ForegroundColor Green
        Write-Host ""
        Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
        Write-Host "  1. Cierra y abre el navegador O presiona Ctrl+F5" -ForegroundColor White
        Write-Host "  2. Ve a: Flor IA -> Pestaña WhatsApp" -ForegroundColor White
        Write-Host "  3. Busca el botón NARANJA arriba a la derecha" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "❌ Error aplicando cambios a los contenedores" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Error subiendo archivo al servidor" -ForegroundColor Red
    exit 1
}
