# Script para aplicar muleto.html limpio a todos los contenedores
Write-Host "=== APLICAR MULETO.HTML LIMPIO ===" -ForegroundColor Green
Write-Host ""

# 1. Subir archivo al servidor
Write-Host "1. Subiendo dashboard.html corregido al servidor..." -ForegroundColor Yellow
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

# 2. Ejecutar script en el servidor para aplicar a todos los contenedores
Write-Host "2. Aplicando a todos los contenedores..." -ForegroundColor Yellow

$bashScript = @"
#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO ==="
echo "Tamaño del archivo:"
ls -lh deploy/dashboard.html
echo ""
echo "Funciones globales en head:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
grep -n "window.handleLogin = function" deploy/dashboard.html | head -1
echo ""

echo "=== APLICANDO A TODOS LOS CONTENEDORES ==="
CONTAINERS=`$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard")
COUNT=`$(echo "`$CONTAINERS" | wc -l)
echo "Contenedores encontrados: `$COUNT"
echo ""

for container in `$CONTAINERS; do
    echo "📦 Procesando: `$container"
    docker cp deploy/dashboard.html `$container:/app/dashboard.html
    if [ `$? -eq 0 ]; then
        echo "  ✅ Archivo copiado"
        docker restart `$container > /dev/null 2>&1
        echo "  ✅ Contenedor reiniciado"
    else
        echo "  ❌ Error copiando archivo"
    fi
    echo ""
done

echo "✅ PROCESO COMPLETADO"
"@

# Guardar script temporalmente
$bashScript | Out-File -FilePath "APLICAR_TEMP.sh" -Encoding UTF8 -NoNewline

# Subir y ejecutar
scp APLICAR_TEMP.sh root@72.61.58.240:/root/checkin24hs/APLICAR_TEMP.sh
ssh root@72.61.58.240 "cd /root/checkin24hs && chmod +x APLICAR_TEMP.sh && bash APLICAR_TEMP.sh"

# Limpiar
Remove-Item "APLICAR_TEMP.sh" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Cyan
Write-Host "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)" -ForegroundColor White
Write-Host "2. Presiona Ctrl+Shift+R para hard refresh" -ForegroundColor White
Write-Host "3. Verifica que no haya errores en la consola" -ForegroundColor White

