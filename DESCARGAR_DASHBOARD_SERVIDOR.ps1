# Script para descargar dashboard.html completo del servidor
# Reemplaza el archivo local con el del servidor

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

Write-Host "Paso 1: Conectando al servidor..." -ForegroundColor Yellow
Write-Host "Servidor: $SERVER_IP" -ForegroundColor Gray
Write-Host ""

# Crear script temporal en el servidor para extraer el archivo
$scriptContent = @'
#!/bin/bash
# Buscar contenedor del dashboard
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $NF}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor del dashboard"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# Buscar el archivo dashboard.html en el contenedor
DASHBOARD_PATH=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    echo "ERROR: No se encontro dashboard.html en el contenedor"
    exit 1
fi

echo "Archivo encontrado en: $DASHBOARD_PATH"

# Copiar el archivo a /tmp para descargarlo
docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html

if [ $? -eq 0 ]; then
    echo "OK: Archivo copiado a /tmp/dashboard_servidor.html"
    echo "RUTA_ARCHIVO=/tmp/dashboard_servidor.html"
else
    echo "ERROR: No se pudo copiar el archivo"
    exit 1
fi
'@

# Guardar script temporal sin BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$PWD\temp_extract.sh", $scriptContent, $utf8NoBom)

Write-Host "Paso 2: Subiendo script temporal al servidor..." -ForegroundColor Yellow
scp temp_extract.sh "${SERVER_USER}@${SERVER_IP}:/tmp/extract_dashboard.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el script al servidor" -ForegroundColor Red
    Remove-Item "temp_extract.sh" -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Paso 3: Ejecutando script en el servidor..." -ForegroundColor Yellow
# Ejecutar comandos directamente en lugar de usar el script
$result = ssh "${SERVER_USER}@${SERVER_IP}" @"
chmod +x /tmp/extract_dashboard.sh
sed -i 's/\r$//' /tmp/extract_dashboard.sh
/tmp/extract_dashboard.sh
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo ejecutar el script en el servidor" -ForegroundColor Red
    Write-Host "Resultado: $result" -ForegroundColor Gray
    Remove-Item "temp_extract.sh" -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Paso 4: Descargando archivo del servidor..." -ForegroundColor Yellow
scp "${SERVER_USER}@${SERVER_IP}:/tmp/dashboard_servidor.html" $TEMP_FILE

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo descargar el archivo del servidor" -ForegroundColor Red
    Remove-Item "temp_extract.sh" -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Paso 5: Verificando archivo descargado..." -ForegroundColor Yellow

# Verificar que el archivo tiene contenido
$fileSize = (Get-Item $TEMP_FILE).Length
if ($fileSize -lt 1000) {
    Write-Host "ERROR: El archivo descargado parece estar vacio o corrupto (tamano: $fileSize bytes)" -ForegroundColor Red
    Remove-Item $TEMP_FILE -ErrorAction SilentlyContinue
    Remove-Item "temp_extract.sh" -ErrorAction SilentlyContinue
    exit 1
}

# Verificar que tiene el build number correcto
$buildNumber = Select-String -Path $TEMP_FILE -Pattern "DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($buildNumber) {
    Write-Host "Build Number encontrado: #$buildNumber" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: No se encontro DASHBOARD_BUILD_NUMBER en el archivo" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Paso 6: Haciendo backup del archivo local..." -ForegroundColor Yellow
$backupName = "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $LOCAL_FILE $backupName
Write-Host "Backup creado: $backupName" -ForegroundColor Gray

Write-Host ""
Write-Host "Paso 7: Reemplazando archivo local..." -ForegroundColor Yellow
Copy-Item $TEMP_FILE $LOCAL_FILE -Force

# Limpiar archivos temporales
Remove-Item $TEMP_FILE -ErrorAction SilentlyContinue
Remove-Item "temp_extract.sh" -ErrorAction SilentlyContinue
ssh "${SERVER_USER}@${SERVER_IP}" "rm -f /tmp/extract_dashboard.sh /tmp/dashboard_servidor.html" 2>$null

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
