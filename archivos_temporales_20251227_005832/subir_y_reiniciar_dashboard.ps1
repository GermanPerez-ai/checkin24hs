# Script completo para subir dashboard.html (muleto.html) y reiniciar el servicio
# Ejecutar desde PowerShell: .\subir_y_reiniciar_dashboard.ps1

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "🚀 Subiendo dashboard.html (muleto.html) al servidor..." -ForegroundColor Cyan
Write-Host ""

# Subir dashboard.html
Write-Host "📤 Subiendo dashboard.html..." -ForegroundColor Yellow
scp "$rutaLocal\dashboard.html" "${servidor}:${rutaServidor}/dashboard.html"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ dashboard.html subido correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error subiendo dashboard.html" -ForegroundColor Red
    exit 1
}

# Subir serve-dashboard.js
if (Test-Path "$rutaLocal\serve-dashboard.js") {
    Write-Host "📤 Subiendo serve-dashboard.js..." -ForegroundColor Yellow
    scp "$rutaLocal\serve-dashboard.js" "${servidor}:${rutaServidor}/serve-dashboard.js"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ serve-dashboard.js subido correctamente" -ForegroundColor Green
    }
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
Write-Host "🔄 Reiniciando servicio en el servidor..." -ForegroundColor Cyan

# Conectar y reiniciar el servicio
$comando = @"
cd $rutaServidor
pm2 restart dashboard
sleep 2
pm2 logs dashboard --lines 10 --nostream
"@

ssh $servidor $comando

Write-Host ""
Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host "🌐 Accede a: http://72.61.58.240:3000/" -ForegroundColor Cyan


