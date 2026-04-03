# Script para subir dashboard.html (muleto.html) y aplicarlo al contenedor

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Subir dashboard.html (muleto) y Aplicar" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que el archivo existe
if (-not (Test-Path "dashboard.html")) {
    Write-Host "❌ Error: dashboard.html no existe en el directorio actual" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo dashboard.html encontrado" -ForegroundColor Green
$fileInfo = Get-Item "dashboard.html"
Write-Host "   Tamaño: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "   Última modificación: $($fileInfo.LastWriteTime)" -ForegroundColor White
Write-Host ""

# 2. Subir dashboard.html al servidor
Write-Host "2. Subiendo dashboard.html al servidor..." -ForegroundColor Yellow
scp dashboard.html "${SERVER}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido exitosamente" -ForegroundColor Green
Write-Host ""

# 3. Subir el script de aplicación si existe
if (Test-Path "aplicar_dashboard_persistente.sh") {
    Write-Host "3. Subiendo script de aplicación..." -ForegroundColor Yellow
    scp aplicar_dashboard_persistente.sh "${SERVER}:${REMOTE_DIR}/"
    Write-Host ""
}

# 4. Ejecutar comandos en el servidor para aplicar el archivo
Write-Host "4. Aplicando dashboard.html al contenedor..." -ForegroundColor Yellow
Write-Host ""

$commands = @"
cd $REMOTE_DIR
CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
if [ ! -z "`$CONTAINER_ID" ]; then
    echo "Copiando dashboard.html al contenedor `$CONTAINER_ID..."
    docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html
    echo "✅ Archivo copiado"
    echo "Reiniciando servicio..."
    docker service update --force checkin24hs_dashboard
    echo "✅ Servicio reiniciado"
    echo ""
    echo "Esperando 15 segundos..."
    sleep 15
    echo ""
    echo "Verificando estado:"
    docker service ps checkin24hs_dashboard --no-trunc | head -3
    echo ""
    echo "Probando acceso:"
    curl -s -I http://localhost:3000 | head -3
else
    echo "❌ No se encontró contenedor"
fi
"@

ssh $SERVER $commands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "✅ Proceso completado" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "El dashboard debería estar actualizado ahora." -ForegroundColor White
    Write-Host "Abre en tu navegador:" -ForegroundColor Yellow
    Write-Host "  - http://72.61.58.240:3000" -ForegroundColor Green
    Write-Host "  - http://dashboard.checkin24hs.com" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠️  Hubo algún problema. Puedes ejecutar manualmente:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "En el servidor:" -ForegroundColor White
    Write-Host "  cd $REMOTE_DIR" -ForegroundColor Gray
    Write-Host "  CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)" -ForegroundColor Gray
    Write-Host "  docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html" -ForegroundColor Gray
    Write-Host "  docker service update --force checkin24hs_dashboard" -ForegroundColor Gray
    Write-Host ""
}

