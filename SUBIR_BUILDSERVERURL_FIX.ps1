# Script para subir dashboard.html con corrección de buildServerURL

Write-Host "📤 Subiendo archivos al servidor..." -ForegroundColor Cyan

$serverIP = "72.61.58.240"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"
$scriptFile = "APLICAR_BUILDSERVERURL_FIX.sh"
$scriptRemotePath = "/root/checkin24hs/APLICAR_BUILDSERVERURL_FIX.sh"

# Verificar que el archivo existe
if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encuentra el archivo $localFile" -ForegroundColor Red
    exit 1
}

# Verificar que buildServerURL está en el archivo
$content = Get-Content $localFile -Raw
if ($content -notmatch "window\.buildServerURL") {
    Write-Host "⚠️ Advertencia: window.buildServerURL no encontrado en el archivo" -ForegroundColor Yellow
    Write-Host "   El archivo puede no tener la corrección aplicada" -ForegroundColor Yellow
}

# Subir archivo dashboard.html
Write-Host "📋 Subiendo dashboard.html..." -ForegroundColor Yellow
scp $localFile "root@${serverIP}:${remotePath}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al subir dashboard.html" -ForegroundColor Red
    exit 1
}

Write-Host "✅ dashboard.html subido correctamente" -ForegroundColor Green

# Subir script bash si existe
if (Test-Path $scriptFile) {
    Write-Host "📋 Subiendo script de aplicación..." -ForegroundColor Yellow
    scp $scriptFile "root@${serverIP}:${scriptRemotePath}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Script subido correctamente" -ForegroundColor Green
    } else {
        Write-Host "⚠️ No se pudo subir el script (continuando...)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Archivos subidos correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Conecta por SSH al servidor:" -ForegroundColor White
Write-Host "   ssh root@${serverIP}" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Ejecuta el script de aplicación:" -ForegroundColor White
Write-Host "   cd /root/checkin24hs" -ForegroundColor Gray
Write-Host "   chmod +x APLICAR_BUILDSERVERURL_FIX.sh" -ForegroundColor Gray
Write-Host "   bash APLICAR_BUILDSERVERURL_FIX.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Recarga el dashboard con Ctrl+Shift+R (hard reload)" -ForegroundColor White
Write-Host ""
Write-Host "4. Verifica en la consola:" -ForegroundColor White
Write-Host "   console.log('buildServerURL:', typeof buildServerURL === 'function');" -ForegroundColor Gray








