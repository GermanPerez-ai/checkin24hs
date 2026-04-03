# Script final para subir y aplicar dashboard.html con todas las correcciones

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Aplicar Dashboard con Correcciones Finales" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar archivo
if (-not (Test-Path "dashboard.html")) {
    Write-Host "❌ Error: dashboard.html no existe" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item "dashboard.html"
Write-Host "✅ Archivo encontrado: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Green
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

# Aplicar al contenedor
Write-Host "Aplicando al contenedor..." -ForegroundColor Yellow
Write-Host ""

$commands = @"
cd $REMOTE_DIR
echo "=== PASO 1: Buscar contenedor ==="
CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
if [ -z "`$CONTAINER_ID" ]; then
    echo "Esperando 5 segundos..."
    sleep 5
    CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
fi

if [ -z "`$CONTAINER_ID" ]; then
    echo "❌ No se encontro contenedor"
    docker service ls | grep dashboard
    exit 1
fi

echo "✅ Contenedor: `$CONTAINER_ID"
echo ""

echo "=== PASO 2: Copiar archivo ==="
docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html
if [ `$? -ne 0 ]; then
    echo "❌ Error al copiar"
    exit 1
fi
echo "✅ Archivo copiado"
echo ""

echo "=== PASO 3: Verificar archivo copiado ==="
docker exec `$CONTAINER_ID ls -lh /app/dashboard.html
echo ""

echo "=== PASO 4: Verificar linea 5150 ==="
docker exec `$CONTAINER_ID sed -n '5150p' /app/dashboard.html
echo ""

echo "=== PASO 5: Verificar showSection en HEAD ==="
docker exec `$CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
echo ""

echo "=== PASO 6: Reiniciar servicio ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

echo "Esperando 25 segundos..."
sleep 25

echo ""
echo "=== PASO 7: Verificar nuevo contenedor ==="
NEW_CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
if [ ! -z "`$NEW_CONTAINER_ID" ] && [ "`$NEW_CONTAINER_ID" != "`$CONTAINER_ID" ]; then
    echo "⚠️  Nuevo contenedor creado: `$NEW_CONTAINER_ID"
    echo "Copiando archivo al nuevo contenedor..."
    docker cp dashboard.html `$NEW_CONTAINER_ID:/app/dashboard.html
    echo "✅ Archivo copiado al nuevo contenedor"
    echo ""
    echo "Verificando showSection en nuevo contenedor:"
    docker exec `$NEW_CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
fi

echo ""
echo "=== PASO 8: Probar acceso ==="
curl -I http://localhost:3000 | head -3
echo ""
"@

ssh $SERVER $commands

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Proceso completado" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "1. Recarga la pagina con Ctrl+F5 (recarga forzada)" -ForegroundColor White
Write-Host "2. Abre DevTools (F12) y verifica:" -ForegroundColor White
Write-Host "   - Si desaparecio el SyntaxError" -ForegroundColor White
Write-Host "   - Si desaparecio window.showSection is not a function" -ForegroundColor White
Write-Host ""
Write-Host "Si los errores persisten, verifica en DevTools > Sources" -ForegroundColor Yellow
Write-Host "la linea 5150 exacta que marca el error." -ForegroundColor Yellow
Write-Host ""





