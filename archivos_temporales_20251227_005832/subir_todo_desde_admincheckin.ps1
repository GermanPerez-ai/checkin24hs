# Script para subir todos los archivos desde admincheckin al servidor

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Subir Archivos desde admincheckin" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Lista de archivos a subir
$files = @(
    "dashboard.html",
    "supabase-client.js",
    "supabase-config.js"
)

# Verificar que los archivos existen
$missingFiles = @()
foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Error: Los siguientes archivos no existen:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Red
    }
    exit 1
}

# Mostrar información de los archivos
Write-Host "Archivos a subir:" -ForegroundColor Yellow
foreach ($file in $files) {
    $fileInfo = Get-Item $file
    Write-Host "   ✅ $file ($([math]::Round($fileInfo.Length / 1KB, 2)) KB)" -ForegroundColor Green
}
Write-Host ""

# Subir cada archivo
foreach ($file in $files) {
    Write-Host "Subiendo $file..." -ForegroundColor Yellow
    scp $file "${SERVER}:${REMOTE_DIR}/"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al subir $file" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "   ✅ $file subido exitosamente" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Aplicando archivos al contenedor..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Comandos para aplicar al contenedor
$commands = @"
cd $REMOTE_DIR
echo "Buscando contenedor..."
CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)

if [ -z "`$CONTAINER_ID" ]; then
    echo "⚠️  No se encontró contenedor corriendo. Esperando 5 segundos..."
    sleep 5
    CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)
fi

if [ ! -z "`$CONTAINER_ID" ]; then
    echo "✅ Contenedor encontrado: `$CONTAINER_ID"
    echo ""
    echo "Copiando archivos al contenedor..."
    
    # Copiar dashboard.html
    docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html
    echo "   ✅ dashboard.html copiado"
    
    # Copiar supabase-client.js
    docker cp supabase-client.js `$CONTAINER_ID:/app/supabase-client.js
    echo "   ✅ supabase-client.js copiado"
    
    # Copiar supabase-config.js
    docker cp supabase-config.js `$CONTAINER_ID:/app/supabase-config.js
    echo "   ✅ supabase-config.js copiado"
    
    echo ""
    echo "Verificando archivos en el contenedor:"
    docker exec `$CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null || echo "   ⚠️  Algunos archivos no se encontraron"
    
    echo ""
    echo "Reiniciando servicio..."
    docker service update --force checkin24hs_dashboard
    
    echo ""
    echo "Esperando 15 segundos para que el servicio se inicie..."
    sleep 15
    
    echo ""
    echo "Verificando estado del servicio:"
    docker service ps checkin24hs_dashboard --no-trunc | head -3
    
    echo ""
    echo "Probando acceso:"
    curl -s -I http://localhost:3000 | head -3
    
else
    echo "❌ No se encontró contenedor después de esperar"
    echo "Verifica que el servicio esté corriendo:"
    docker service ls | grep dashboard
fi
"@

ssh $SERVER $commands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "✅ Proceso completado" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Todos los archivos han sido subidos y aplicados." -ForegroundColor White
    Write-Host "Abre en tu navegador:" -ForegroundColor Yellow
    Write-Host "  - http://72.61.58.240:3000" -ForegroundColor Green
    Write-Host "  - http://dashboard.checkin24hs.com" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠️  Hubo algún problema durante la aplicación." -ForegroundColor Yellow
    Write-Host "Puedes ejecutar manualmente en el servidor:" -ForegroundColor White
    Write-Host ""
    Write-Host "  cd $REMOTE_DIR" -ForegroundColor Gray
    Write-Host "  CONTAINER_ID=`$(docker ps | grep checkin24hs_dashboard | awk '{print `$1}' | head -1)" -ForegroundColor Gray
    Write-Host "  docker cp dashboard.html `$CONTAINER_ID:/app/dashboard.html" -ForegroundColor Gray
    Write-Host "  docker cp supabase-client.js `$CONTAINER_ID:/app/supabase-client.js" -ForegroundColor Gray
    Write-Host "  docker cp supabase-config.js `$CONTAINER_ID:/app/supabase-config.js" -ForegroundColor Gray
    Write-Host "  docker service update --force checkin24hs_dashboard" -ForegroundColor Gray
    Write-Host ""
}

