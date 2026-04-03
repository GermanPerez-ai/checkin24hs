# Script para subir archivos corregidos (sin referencias WhatsApp) al servidor
# Ejecutar desde PowerShell en tu computadora Windows

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "🚀 Subiendo archivos corregidos (sin WhatsApp) al servidor..." -ForegroundColor Cyan
Write-Host ""

# Verificar que los archivos existen localmente
$archivos = @(
    "deploy\crm.html",
    "deploy\crm.js",
    "deploy\dashboard.html"
)

foreach ($archivo in $archivos) {
    $rutaCompleta = Join-Path $rutaLocal $archivo
    if (-not (Test-Path $rutaCompleta)) {
        Write-Host "❌ Error: No se encontró $archivo" -ForegroundColor Red
        exit 1
    }
}

# 1. Subir crm.html
Write-Host "📤 Subiendo deploy/crm.html..." -ForegroundColor Yellow
scp "$rutaLocal\deploy\crm.html" "${servidor}:${rutaServidor}/deploy/crm.html"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ crm.html subido correctamente" -ForegroundColor Green
} else {
    Write-Host "   ❌ Error subiendo crm.html" -ForegroundColor Red
}

# 2. Subir crm.js
Write-Host "📤 Subiendo deploy/crm.js..." -ForegroundColor Yellow
scp "$rutaLocal\deploy\crm.js" "${servidor}:${rutaServidor}/deploy/crm.js"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ crm.js subido correctamente" -ForegroundColor Green
} else {
    Write-Host "   ❌ Error subiendo crm.js" -ForegroundColor Red
}

# 3. Subir dashboard.html (archivo corregido con funciones globales)
Write-Host "📤 Subiendo deploy/dashboard.html (corregido)..." -ForegroundColor Yellow
scp "$rutaLocal\deploy\dashboard.html" "${servidor}:${rutaServidor}/deploy/dashboard.html"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ dashboard.html subido correctamente" -ForegroundColor Green
} else {
    Write-Host "   ❌ Error subiendo dashboard.html" -ForegroundColor Red
}

# 4. Subir scripts bash para aplicar cambios
Write-Host "📤 Subiendo scripts de aplicación..." -ForegroundColor Yellow
scp "$rutaLocal\APLICAR_CORRECCIONES_WHATSAPP.sh" "${servidor}:${rutaServidor}/APLICAR_CORRECCIONES_WHATSAPP.sh"
scp "$rutaLocal\APLICAR_A_TODOS_CONTENEDORES.sh" "${servidor}:${rutaServidor}/APLICAR_A_TODOS_CONTENEDORES.sh"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Scripts subidos correctamente" -ForegroundColor Green
    
    # Dar permisos de ejecución y ejecutar
    Write-Host ""
    Write-Host "🔄 Aplicando cambios en todos los contenedores..." -ForegroundColor Cyan
    ssh $servidor "chmod +x $rutaServidor/APLICAR_A_TODOS_CONTENEDORES.sh && bash $rutaServidor/APLICAR_A_TODOS_CONTENEDORES.sh"
} else {
    Write-Host "   ❌ Error subiendo scripts" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Verifica los cambios en:" -ForegroundColor Cyan
Write-Host "   - https://crm.checkin24hs.com/" -ForegroundColor White
Write-Host "   - https://dashboard.checkin24hs.com/" -ForegroundColor White
Write-Host ""
Write-Host "💡 Para limpiar caché del navegador:" -ForegroundColor Yellow
Write-Host "   - Presiona Ctrl + Shift + R (hard refresh)" -ForegroundColor White
Write-Host "   - O abre en modo incógnito (Ctrl + Shift + N)" -ForegroundColor White
Write-Host ""

