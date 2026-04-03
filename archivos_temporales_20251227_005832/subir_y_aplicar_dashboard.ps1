# Script para subir dashboard.html y aplicarlo directamente al contenedor Docker

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Subir y Aplicar dashboard.html" -ForegroundColor Cyan
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

# 3. Subir el script de aplicación
Write-Host "3. Subiendo script de aplicación..." -ForegroundColor Yellow
scp copiar_dashboard_al_contenedor.sh "${SERVER}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Advertencia: No se pudo subir el script, pero continuando..." -ForegroundColor Yellow
}

Write-Host ""

# 4. Ejecutar el script en el servidor
Write-Host "4. Ejecutando script en el servidor..." -ForegroundColor Yellow
Write-Host ""

ssh $SERVER "cd $REMOTE_DIR && chmod +x copiar_dashboard_al_contenedor.sh && ./copiar_dashboard_al_contenedor.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "✅ Proceso completado exitosamente" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "El dashboard debería estar actualizado ahora." -ForegroundColor White
    Write-Host "Abre en tu navegador:" -ForegroundColor Yellow
    Write-Host "  - http://72.61.58.240:3000" -ForegroundColor Green
    Write-Host "  - http://dashboard.checkin24hs.com" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al ejecutar el script en el servidor" -ForegroundColor Red
    Write-Host ""
    Write-Host "Puedes ejecutar manualmente en el servidor:" -ForegroundColor Yellow
    Write-Host "  cd $REMOTE_DIR" -ForegroundColor White
    Write-Host "  chmod +x copiar_dashboard_al_contenedor.sh" -ForegroundColor White
    Write-Host "  ./copiar_dashboard_al_contenedor.sh" -ForegroundColor White
    Write-Host ""
}

