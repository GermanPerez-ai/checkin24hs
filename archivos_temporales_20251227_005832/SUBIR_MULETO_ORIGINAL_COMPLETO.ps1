# Script para subir muleto.html original (sin modificaciones) y aplicarlo

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Subir muleto.html ORIGINAL (sin modificaciones)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path "dashboard.html")) {
    Write-Host "❌ Error: dashboard.html no existe" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item "dashboard.html"
Write-Host "✅ Archivo encontrado:" -ForegroundColor Green
Write-Host "   Tamaño: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "   Última modificación: $($fileInfo.LastWriteTime)" -ForegroundColor White
Write-Host ""

# Subir archivo
Write-Host "Subiendo dashboard.html al servidor..." -ForegroundColor Yellow
scp dashboard.html "${SERVER}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido exitosamente" -ForegroundColor Green
Write-Host ""

# Comandos para aplicar al contenedor
Write-Host "Aplicando al contenedor Docker..." -ForegroundColor Yellow
Write-Host ""

$commands = @"
cd $REMOTE_DIR
echo "Buscando contenedor..."
CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)

if [ -z "`$CONTAINER_ID" ]; then
    echo "⚠️  Esperando 5 segundos..."
    sleep 5
    CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
fi

if [ ! -z "`$CONTAINER_ID" ]; then
    echo "✅ Contenedor encontrado: `$CONTAINER_ID"
    echo ""
    echo "Copiando dashboard.html..."
    docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html
    
    if [ `$? -eq 0 ]; then
        echo "✅ dashboard.html copiado"
        echo ""
        echo "Verificando archivo en el contenedor:"
        docker exec `$CONTAINER_ID ls -lh /app/dashboard.html
        echo ""
        echo "Reiniciando servicio..."
        docker service update --force checkin24hs_dashboard
        echo ""
        echo "Esperando 20 segundos..."
        sleep 20
        echo ""
        echo "Verificando nuevo contenedor:"
        NEW_CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
        if [ ! -z "`$NEW_CONTAINER_ID" ] && [ "`$NEW_CONTAINER_ID" != "`$CONTAINER_ID" ]; then
            echo "⚠️  Nuevo contenedor creado: `$NEW_CONTAINER_ID"
            echo "Copiando archivo al nuevo contenedor..."
            docker cp dashboard.html `$NEW_CONTAINER_ID:/app/dashboard.html
            echo "✅ Archivo copiado al nuevo contenedor"
        fi
        echo ""
        echo "Probando acceso:"
        curl -I http://localhost:3000 | head -3
    else
        echo "❌ Error al copiar archivo"
    fi
else
    echo "❌ No se encontró contenedor"
    docker service ls | grep dashboard
fi
"@

ssh $SERVER $commands

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Proceso completado" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Recarga la página en tu navegador con Ctrl+F5" -ForegroundColor Yellow
Write-Host "Los botones deberían funcionar ahora." -ForegroundColor Yellow
Write-Host ""

