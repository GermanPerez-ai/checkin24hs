# Script para descargar dashboard.html del servidor
# Funciona completamente desde PowerShell sin necesidad de SSH manual

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

Write-Host "Paso 1: Buscando contenedor y extrayendo archivo..." -ForegroundColor Yellow
Write-Host "(Se te pedira la contraseña SSH)" -ForegroundColor Gray
Write-Host ""

# Comando único que busca, encuentra y copia el archivo
$extractCommand = 'CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk ''{print $1}'' | head -1); if [ -z "$CONTAINER_ID" ]; then CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.Names}}" | head -1); fi; if [ -z "$CONTAINER_ID" ]; then echo "ERROR: No se encontro contenedor"; exit 1; fi; echo "Contenedor: $CONTAINER_ID"; DASHBOARD_PATH=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1); if [ -z "$DASHBOARD_PATH" ]; then echo "ERROR: No se encontro dashboard.html"; exit 1; fi; echo "Ruta: $DASHBOARD_PATH"; docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html && echo "OK: Archivo copiado" || (echo "ERROR: No se pudo copiar"; exit 1); ls -lh /tmp/dashboard_servidor.html'

# Ejecutar comando en el servidor
Write-Host "Ejecutando comandos en el servidor..." -ForegroundColor Gray
$result = ssh "${SERVER_USER}@${SERVER_IP}" $extractCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: No se pudo extraer el archivo del servidor" -ForegroundColor Red
    Write-Host "Resultado:" -ForegroundColor Yellow
    Write-Host $result -ForegroundColor Gray
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  1. Contraseña SSH incorrecta" -ForegroundColor White
    Write-Host "  2. El contenedor del dashboard no esta corriendo" -ForegroundColor White
    Write-Host "  3. Problemas de conexion con el servidor" -ForegroundColor White
    exit 1
}

# Verificar que el resultado contiene "OK" o muestra el tamaño del archivo
if ($result -notmatch "OK: Archivo copiado" -and $result -notmatch "-rw-r--r--") {
    Write-Host ""
    Write-Host "ADVERTENCIA: No se confirmo que el archivo se copio correctamente" -ForegroundColor Yellow
    Write-Host "Resultado:" -ForegroundColor Gray
    Write-Host $result -ForegroundColor Gray
    Write-Host ""
    Write-Host "¿Deseas continuar de todos modos? (S/N)" -ForegroundColor Yellow
    $continue = Read-Host
    if ($continue -ne "S" -and $continue -ne "s") {
        exit 1
    }
} else {
    Write-Host "Archivo copiado correctamente en el servidor" -ForegroundColor Green
}

Write-Host ""
Write-Host "Paso 2: Descargando archivo del servidor..." -ForegroundColor Yellow
Write-Host "(Se te pedira la contraseña SSH nuevamente)" -ForegroundColor Gray

scp "${SERVER_USER}@${SERVER_IP}:/tmp/dashboard_servidor.html" $TEMP_FILE

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: No se pudo descargar el archivo del servidor" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  1. Contraseña SSH incorrecta" -ForegroundColor White
    Write-Host "  2. El archivo no existe en /tmp/dashboard_servidor.html" -ForegroundColor White
    Write-Host "  3. Problemas de conexion" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Paso 3: Verificando archivo descargado..." -ForegroundColor Yellow

# Verificar que el archivo existe y tiene contenido
if (-not (Test-Path $TEMP_FILE)) {
    Write-Host "ERROR: El archivo descargado no existe" -ForegroundColor Red
    exit 1
}

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

# Limpiar archivo temporal en el servidor (sin mostrar errores si falla)
Write-Host "Limpiando archivo temporal en el servidor..." -ForegroundColor Gray
ssh "${SERVER_USER}@${SERVER_IP}" "rm -f /tmp/dashboard_servidor.html" 2>$null | Out-Null

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
