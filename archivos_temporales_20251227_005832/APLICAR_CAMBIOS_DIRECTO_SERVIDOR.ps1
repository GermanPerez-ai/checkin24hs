# Script para aplicar cambios directamente en el servidor usando volumen montado

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Aplicar Cambios Directamente en Servidor" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar archivo local
if (-not (Test-Path "dashboard.html")) {
    Write-Host "❌ Error: dashboard.html no existe" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item "dashboard.html"
Write-Host "✅ Archivo local encontrado: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Green
Write-Host ""

# Subir archivo
Write-Host "Subiendo dashboard.html..." -ForegroundColor Yellow
scp dashboard.html "${SERVER}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido" -ForegroundColor Green
Write-Host ""

# Aplicar usando volumen montado
Write-Host "Aplicando cambios usando volumen montado..." -ForegroundColor Yellow
Write-Host ""

$commands = @"
cd $REMOTE_DIR

# Crear directorio para volumen si no existe
mkdir -p /root/dashboard-volume

# Copiar archivo al volumen
cp dashboard.html /root/dashboard-volume/

# Verificar que se copió
ls -lh /root/dashboard-volume/dashboard.html

# Buscar contenedor actual
CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
echo "Contenedor actual: `$CONTAINER_ID"

# Actualizar servicio para montar volumen
echo "Actualizando servicio para montar volumen..."
docker service update \
  --mount-add type=bind,source=/root/dashboard-volume,target=/app,readonly=false \
  checkin24hs_dashboard

echo ""
echo "Esperando 30 segundos..."
sleep 30

# Verificar nuevo contenedor
NEW_CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
echo "Nuevo contenedor: `$NEW_CONTAINER_ID"

# Copiar archivo al nuevo contenedor también
if [ ! -z "`$NEW_CONTAINER_ID" ]; then
    docker cp /root/dashboard-volume/dashboard.html `$NEW_CONTAINER_ID:/app/dashboard.html
    echo "✅ Archivo copiado al contenedor"
    
    # Verificar
    echo ""
    echo "Verificando archivo en contenedor:"
    docker exec `$NEW_CONTAINER_ID ls -lh /app/dashboard.html
    echo ""
    echo "Verificando showSection:"
    docker exec `$NEW_CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
fi

echo ""
echo "✅ Proceso completado"
"@

ssh $SERVER $commands

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Cambios aplicados" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "1. Recarga la pagina con Ctrl+F5" -ForegroundColor White
Write-Host "2. Abre DevTools (F12) y verifica los errores" -ForegroundColor White
Write-Host ""




