# Script PowerShell para subir dashboard.html corregido y aplicarlo al servidor

Write-Host "=== APLICAR CORRECCION LINEA 5150 - FINAL ===" -ForegroundColor Green
Write-Host ""

# 1. Subir archivo al servidor
Write-Host "1. Subiendo dashboard.html al servidor..." -ForegroundColor Yellow
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

# 2. Crear script bash en el servidor
Write-Host "2. Creando script de aplicacion en el servidor..." -ForegroundColor Yellow

$bashScript = @"
#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO EN SERVIDOR ==="
echo "Linea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "Funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
echo ""

echo "=== APLICANDO A TODOS LOS CONTENEDORES ==="
for container in `$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Procesando: `$container"
    docker cp deploy/dashboard.html `$container:/app/dashboard.html
    docker restart `$container
    echo "✅ `$container actualizado"
    echo ""
done

echo "✅ PROCESO COMPLETADO"
"@

# Guardar script temporalmente
$bashScript | Out-File -FilePath "APLICAR_CORRECCION_TEMP.sh" -Encoding UTF8

# Subir script al servidor
scp APLICAR_CORRECCION_TEMP.sh root@72.61.58.240:/root/checkin24hs/APLICAR_CORRECCION_TEMP.sh

# Ejecutar script en el servidor
Write-Host "3. Ejecutando script en el servidor..." -ForegroundColor Yellow
ssh root@72.61.58.240 "cd /root/checkin24hs && chmod +x APLICAR_CORRECCION_TEMP.sh && bash APLICAR_CORRECCION_TEMP.sh"

# Limpiar archivo temporal
Remove-Item "APLICAR_CORRECCION_TEMP.sh" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Cyan
Write-Host "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)" -ForegroundColor White
Write-Host "2. Presiona Ctrl+Shift+R para hard refresh" -ForegroundColor White
Write-Host "3. Verifica que no haya errores en la consola" -ForegroundColor White

