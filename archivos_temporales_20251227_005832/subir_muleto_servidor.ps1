# Script para subir muleto.html (ahora dashboard.html) al servidor
# Ejecutar desde PowerShell: .\subir_muleto_servidor.ps1

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "🚀 Subiendo dashboard.html (muleto.html) al servidor..." -ForegroundColor Cyan

# Subir dashboard.html
Write-Host "📤 Subiendo dashboard.html..." -ForegroundColor Yellow
scp "$rutaLocal\dashboard.html" "${servidor}:${rutaServidor}/dashboard.html"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ dashboard.html subido correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error subiendo dashboard.html" -ForegroundColor Red
    exit 1
}

# Subir archivos relacionados si existen
if (Test-Path "$rutaLocal\supabase-client.js") {
    Write-Host "📤 Subiendo supabase-client.js..." -ForegroundColor Yellow
    scp "$rutaLocal\supabase-client.js" "${servidor}:${rutaServidor}/supabase-client.js"
}

if (Test-Path "$rutaLocal\supabase-config.js") {
    Write-Host "📤 Subiendo supabase-config.js..." -ForegroundColor Yellow
    scp "$rutaLocal\supabase-config.js" "${servidor}:${rutaServidor}/supabase-config.js"
}

Write-Host ""
Write-Host "📋 Comandos para ejecutar en el servidor:" -ForegroundColor Cyan
Write-Host "ssh $servidor" -ForegroundColor White
Write-Host "cd $rutaServidor" -ForegroundColor White
Write-Host "pm2 restart dashboard" -ForegroundColor White
Write-Host "pm2 logs dashboard --lines 10 --nostream" -ForegroundColor White
Write-Host ""
Write-Host "✅ Archivos subidos. Ahora ejecuta los comandos arriba en el servidor." -ForegroundColor Green


