# Script simplificado para descargar dashboard.html del servidor
# Ejecuta comandos directamente sin crear scripts temporales

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$LOCAL_FILE = "dashboard.html"
$TEMP_FILE = "dashboard_servidor.html"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DESCARGAR DASHBOARD DEL SERVIDOR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "dashboard.html")) {
    Write-Host "ERROR: No se encontro dashboard.html en el directorio actual" -ForegroundColor Red
    Write-Host "Asegurate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "Paso 1: Buscando contenedor y extrayendo archivo en el servidor..." -ForegroundColor Yellow
Write-Host "(Esto puede tomar unos segundos)" -ForegroundColor Gray
Write-Host ""

# Ejecutar comandos directamente en el servidor
$commands = @"
CONTAINER_ID=`$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "`$CONTAINER_ID" ]; then
    CONTAINER_ID=`$(docker ps | grep dashboard | grep -v nginx | awk '{print `$NF}' | head -1)
fi
if [ -z "`$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor"
    exit 1
fi
echo "Contenedor: `$CONTAINER_ID"
DASHBOARD_PATH=`$(docker exec `$CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
if [ -z "`$DASHBOARD_PATH" ]; then
    echo "ERROR: No se encontro dashboard.html"
    exit 1
fi
echo "Ruta: `$DASHBOARD_PATH"
docker cp `$CONTAINER_ID:`$DASHBOARD_PATH /tmp/dashboard_servidor.html
if [ `$? -eq 0 ]; then
    echo "OK: Archivo copiado"
    ls -lh /tmp/dashboard_servidor.html
else
    echo "ERROR: No se pudo copiar"
    exit 1
fi
"@

# Ejecutar comandos en el servidor
$result = ssh "${SERVER_USER}@${SERVER_IP}" $commands

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo extraer el archivo del servidor" -ForegroundColor Red
    Write-Host "Resultado: $result" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Paso 2: Descargando archivo del servidor..." -ForegroundColor Yellow
scp "${SERVER_USER}@${SERVER_IP}:/tmp/dashboard_servidor.html" $TEMP_FILE

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo descargar el archivo del servidor" -ForegroundColor Red
    exit 1
}

Write-Host "Paso 3: Verificando archivo descargado..." -ForegroundColor Yellow

# Verificar que el archivo tiene contenido
$fileSize = (Get-Item $TEMP_FILE).Length
if ($fileSize -lt 1000) {
    Write-Host "ERROR: El archivo descargado parece estar vacio (tamano: $fileSize bytes)" -ForegroundColor Red
    Remove-Item $TEMP_FILE -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Tamano del archivo: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Green

# Verificar que tiene el build number
$buildNumber = Select-String -Path $TEMP_FILE -Pattern "DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($buildNumber) {
    Write-Host "Build Number encontrado: #$buildNumber" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: No se encontro DASHBOARD_BUILD_NUMBER" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Paso 4: Haciendo backup del archivo local..." -ForegroundColor Yellow
$backupName = "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $LOCAL_FILE $backupName
Write-Host "Backup creado: $backupName" -ForegroundColor Gray

Write-Host ""
Write-Host "Paso 5: Reemplazando archivo local..." -ForegroundColor Yellow
Copy-Item $TEMP_FILE $LOCAL_FILE -Force

# Limpiar archivo temporal
Remove-Item $TEMP_FILE -ErrorAction SilentlyContinue
ssh "${SERVER_USER}@${SERVER_IP}" "rm -f /tmp/dashboard_servidor.html" 2>$null

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DESCARGA COMPLETADA EXITOSAMENTE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo actualizado: $LOCAL_FILE" -ForegroundColor Green
Write-Host "Backup guardado: $backupName" -ForegroundColor Gray
Write-Host ""
Write-Host "Ahora puedes:" -ForegroundColor Cyan
Write-Host "  1. Abrir dashboard.html en tu navegador" -ForegroundColor White
Write-Host "  2. Verificar que tiene Build #75" -ForegroundColor White
Write-Host "  3. Probar el login con: ?username=German&password=123456" -ForegroundColor White
Write-Host ""
