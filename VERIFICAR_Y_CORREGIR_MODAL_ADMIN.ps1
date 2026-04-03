# Script PowerShell para verificar y corregir el modal de administradores

$server = "root@72.61.58.240"
$localFile = "deploy\dashboard.html"
$remoteDir = "/root/checkin24hs"

Write-Host ""
Write-Host "=== VERIFICAR Y CORREGIR MODAL ADMINISTRADORES ===" -ForegroundColor Cyan
Write-Host ""

# Verificar archivo local
if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encontró $localFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo local encontrado: $localFile" -ForegroundColor Green

# Verificar que el modal existe en el archivo local
$localContent = Get-Content $localFile -Raw
if ($localContent -match "adminModal") {
    Write-Host "✅ Modal adminModal encontrado en archivo local" -ForegroundColor Green
} else {
    Write-Host "❌ ERROR: Modal adminModal NO encontrado en archivo local" -ForegroundColor Red
    exit 1
}

if ($localContent -match "function showNewAdminModal") {
    Write-Host "✅ Función showNewAdminModal encontrada en archivo local" -ForegroundColor Green
} else {
    Write-Host "❌ ERROR: Función showNewAdminModal NO encontrada en archivo local" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Subir archivo al servidor
Write-Host "📤 Subiendo archivo al servidor..." -ForegroundColor Yellow
ssh $server "mkdir -p $remoteDir/deploy" | Out-Null
scp $localFile "${server}:${remoteDir}/deploy/dashboard.html"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir archivo" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Archivo subido" -ForegroundColor Green
Write-Host ""

# Subir y ejecutar script de verificación
Write-Host "📤 Subiendo script de verificación..." -ForegroundColor Yellow
scp VERIFICAR_Y_CORREGIR_MODAL_ADMIN.sh "${server}:${remoteDir}/VERIFICAR_Y_CORREGIR_MODAL_ADMIN.sh"
Write-Host "✅ Script subido" -ForegroundColor Green
Write-Host ""

# Ejecutar script en servidor
Write-Host "🚀 Ejecutando verificación y corrección..." -ForegroundColor Yellow
ssh $server "cd $remoteDir && chmod +x VERIFICAR_Y_CORREGIR_MODAL_ADMIN.sh && bash VERIFICAR_Y_CORREGIR_MODAL_ADMIN.sh"
Write-Host ""

Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica el dashboard en: https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host "Presiona Ctrl+F5 para refrescar sin caché" -ForegroundColor Yellow

