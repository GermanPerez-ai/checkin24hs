# Script completo para subir dashboard.html corregido y aplicarlo correctamente
# Ejecutar desde PowerShell en tu computadora Windows

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "🚀 Subiendo dashboard.html corregido al servidor..." -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe y tiene las correcciones
$archivo = "$rutaLocal\deploy\dashboard.html"
if (-not (Test-Path $archivo)) {
    Write-Host "❌ Error: No se encontró deploy\dashboard.html" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Verificando correcciones en archivo local..." -ForegroundColor Yellow

# Verificar funciones globales
$contenido = Get-Content $archivo -Raw
if ($contenido -match "window\.showSection = function") {
    Write-Host "   ✅ Funciones globales encontradas" -ForegroundColor Green
} else {
    Write-Host "   ❌ Funciones globales NO encontradas" -ForegroundColor Red
    exit 1
}

# Verificar línea 5150 (var date = null)
$lineas = Get-Content $archivo
if ($lineas[5149] -match "var date = null") {
    Write-Host "   ✅ Línea 5150 corregida (var date = null)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ Línea 5150 puede no estar corregida" -ForegroundColor Yellow
    Write-Host "      Línea 5150: $($lineas[5149])" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📤 Subiendo archivo al servidor..." -ForegroundColor Yellow
scp $archivo "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Archivo subido correctamente" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📤 Subiendo script de aplicación..." -ForegroundColor Yellow
    scp "$rutaLocal\APLICAR_DASHBOARD_CORREGIDO.sh" "${servidor}:${rutaServidor}/APLICAR_DASHBOARD_CORREGIDO.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Script subido correctamente" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🔄 Aplicando cambios en contenedores..." -ForegroundColor Cyan
        $comando = "chmod +x $rutaServidor/APLICAR_DASHBOARD_CORREGIDO.sh; bash $rutaServidor/APLICAR_DASHBOARD_CORREGIDO.sh"
        ssh $servidor $comando
    } else {
        Write-Host "   ⚠️ Error subiendo script" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "   ❌ Error subiendo archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Verifica los cambios en:" -ForegroundColor Cyan
Write-Host "   - https://dashboard.checkin24hs.com/" -ForegroundColor White
Write-Host ""
Write-Host "💡 IMPORTANTE: Limpia la caché del navegador:" -ForegroundColor Yellow
Write-Host "   1. Presiona Ctrl + Shift + Delete" -ForegroundColor White
Write-Host "   2. Selecciona Cached images and files" -ForegroundColor White
Write-Host "   3. Selecciona All time" -ForegroundColor White
Write-Host "   4. Haz clic en Clear data" -ForegroundColor White
Write-Host "   5. O abre en modo incógnito (Ctrl + Shift + N)" -ForegroundColor White
Write-Host ""

