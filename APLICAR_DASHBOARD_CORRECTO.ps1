# Script PowerShell para subir y aplicar dashboard.html correctamente

$server = "root@72.61.58.240"
$localFile = "deploy\dashboard.html"
$remoteDir = "/root/checkin24hs"

Write-Host ""
Write-Host "=== APLICAR DASHBOARD CORRECTO ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que existe el archivo local
if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encontró $localFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo local encontrado: $localFile" -ForegroundColor Green
Write-Host ""

# Crear directorio remoto si no existe
Write-Host "📁 Creando directorio remoto..." -ForegroundColor Yellow
ssh $server "mkdir -p $remoteDir/deploy" 2>$null
Write-Host "✅ Directorio creado" -ForegroundColor Green
Write-Host ""

# Subir archivo
Write-Host "📤 Subiendo archivo al servidor..." -ForegroundColor Yellow
scp $localFile "${server}:${remoteDir}/deploy/dashboard.html"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir archivo" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Archivo subido" -ForegroundColor Green
Write-Host ""

# Aplicar script en servidor
Write-Host "🚀 Aplicando cambios en contenedores..." -ForegroundColor Yellow
ssh $server "cd $remoteDir && bash -c 'chmod +x APLICAR_DASHBOARD_CORRECTO.sh 2>/dev/null; bash APLICAR_DASHBOARD_CORRECTO.sh'"
Write-Host ""

Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica el dashboard en: https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host "Presiona Ctrl+F5 para refrescar sin caché" -ForegroundColor Yellow










