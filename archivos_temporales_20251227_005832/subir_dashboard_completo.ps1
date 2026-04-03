# Script para subir dashboard.html actualizado y archivos relacionados
# Ejecutar desde PowerShell en tu computadora Windows

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "🚀 Subiendo dashboard.html actualizado al servidor..." -ForegroundColor Cyan
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

# Subir supabase-client.js si existe
if (Test-Path "$rutaLocal\supabase-client.js") {
    Write-Host "📤 Subiendo supabase-client.js..." -ForegroundColor Yellow
    scp "$rutaLocal\supabase-client.js" "${servidor}:${rutaServidor}/supabase-client.js"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ supabase-client.js subido correctamente" -ForegroundColor Green
    }
}

# Subir supabase-config.js si existe
if (Test-Path "$rutaLocal\supabase-config.js") {
    Write-Host "📤 Subiendo supabase-config.js..." -ForegroundColor Yellow
    scp "$rutaLocal\supabase-config.js" "${servidor}:${rutaServidor}/supabase-config.js"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ supabase-config.js subido correctamente" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🔄 Reiniciando servicio en el servidor..." -ForegroundColor Cyan

# Conectar y reiniciar el servicio
$comando = @"
cd $rutaServidor
pm2 restart dashboard
sleep 3
pm2 logs dashboard --lines 15 --nostream
"@

ssh $servidor $comando

Write-Host ""
Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host "🌐 Accede a: http://72.61.58.240:3000/" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Si aún ves el login:" -ForegroundColor Yellow
Write-Host "   1. Abre en modo incógnito (Ctrl + Shift + N)" -ForegroundColor White
Write-Host "   2. O haz hard refresh (Ctrl + Shift + R)" -ForegroundColor White
Write-Host "   3. O limpia la caché del navegador" -ForegroundColor White
