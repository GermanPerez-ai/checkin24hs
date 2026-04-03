# Script para Intercambiar muleto.html con dashboard.html en EasyPanel
# Autor: German Perez
# Fecha: 2025-01-28

Write-Host "🔄 Script de Intercambio: muleto.html -> dashboard.html" -ForegroundColor Cyan
Write-Host ""

$admincheckinPath = "C:\Users\German\Downloads\admincheckin"
$proyectoPath = "C:\Users\German\Downloads\Checkin24hs"
$muletoPath = Join-Path $admincheckinPath "muleto.html"

# Verificar que existe muleto.html
if (-not (Test-Path $muletoPath)) {
    Write-Host "❌ Error: No se encontró muleto.html en $admincheckinPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo encontrado: $muletoPath" -ForegroundColor Green
Write-Host ""

# Paso 1: Crear backup del dashboard.html actual
Write-Host "📦 Paso 1: Creando backup del dashboard.html actual..." -ForegroundColor Yellow

$dashboardPath = Join-Path $proyectoPath "dashboard.html"
$backupPath = Join-Path $proyectoPath "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if (Test-Path $dashboardPath) {
    Copy-Item -Path $dashboardPath -Destination $backupPath
    Write-Host "✅ Backup creado: $backupPath" -ForegroundColor Green
} else {
    Write-Host "⚠️  No existe dashboard.html actual, se creará uno nuevo" -ForegroundColor Yellow
}

# También hacer backup del deploy/dashboard.html si existe
$deployDashboardPath = Join-Path $proyectoPath "deploy\dashboard.html"
if (Test-Path $deployDashboardPath) {
    $deployBackupPath = Join-Path $proyectoPath "deploy\dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $deployDashboardPath -Destination $deployBackupPath
    Write-Host "✅ Backup de deploy/dashboard.html creado: $deployBackupPath" -ForegroundColor Green
}

Write-Host ""

# Paso 2: Copiar muleto.html como dashboard.html
Write-Host "📋 Paso 2: Copiando muleto.html como dashboard.html..." -ForegroundColor Yellow

Copy-Item -Path $muletoPath -Destination $dashboardPath -Force
Write-Host "✅ dashboard.html actualizado en la raíz del proyecto" -ForegroundColor Green

# También copiar a deploy/dashboard.html si existe la carpeta
if (Test-Path (Join-Path $proyectoPath "deploy")) {
    Copy-Item -Path $muletoPath -Destination $deployDashboardPath -Force
    Write-Host "✅ deploy/dashboard.html actualizado" -ForegroundColor Green
}

Write-Host ""

# Paso 3: Copiar archivos de configuración necesarios
Write-Host "📋 Paso 3: Copiando archivos de configuración..." -ForegroundColor Yellow

$archivosConfig = @(
    "supabase-config.js",
    "supabase-client.js",
    "logo.png"
)

foreach ($archivo in $archivosConfig) {
    $origen = Join-Path $admincheckinPath $archivo
    if (Test-Path $origen) {
        $destino = Join-Path $proyectoPath $archivo
        Copy-Item -Path $origen -Destination $destino -Force
        Write-Host "✅ Copiado: $archivo" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No encontrado: $archivo (puede no ser necesario)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Paso 4: Verificar cambios
Write-Host "📊 Paso 4: Resumen de cambios..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Archivos modificados/creados:" -ForegroundColor Cyan
Write-Host "  ✅ dashboard.html (reemplazado con muleto.html)" -ForegroundColor White
if (Test-Path (Join-Path $proyectoPath "deploy\dashboard.html")) {
    Write-Host "  ✅ deploy/dashboard.html (reemplazado con muleto.html)" -ForegroundColor White
}
foreach ($archivo in $archivosConfig) {
    if (Test-Path (Join-Path $proyectoPath $archivo)) {
        Write-Host "  ✅ $archivo (copiado)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Backups creados:" -ForegroundColor Cyan
if (Test-Path $backupPath) {
    Write-Host "  📦 $backupPath" -ForegroundColor White
}
if (Test-Path $deployBackupPath) {
    Write-Host "  📦 $deployBackupPath" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ Intercambio completado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Revisa los cambios:" -ForegroundColor White
Write-Host "   git status" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Agrega los archivos modificados:" -ForegroundColor White
Write-Host "   git add dashboard.html" -ForegroundColor Gray
if (Test-Path (Join-Path $proyectoPath "deploy\dashboard.html")) {
    Write-Host "   git add deploy/dashboard.html" -ForegroundColor Gray
}
foreach ($archivo in $archivosConfig) {
    if (Test-Path (Join-Path $proyectoPath $archivo)) {
        Write-Host "   git add $archivo" -ForegroundColor Gray
    }
}
Write-Host ""
Write-Host "3. Confirma los cambios:" -ForegroundColor White
Write-Host "   git commit -m 'Reemplazar dashboard.html con muleto.html funcional'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Sube a GitHub:" -ForegroundColor White
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Configura EasyPanel:" -ForegroundColor White
Write-Host "   - Ve a EasyPanel -> Proyecto checkin24hs -> Servicio dashboard" -ForegroundColor Gray
Write-Host "   - Cambia la configuración para servir archivos estáticos HTML" -ForegroundColor Gray
Write-Host "   - O configura Nginx/Node.js para servir dashboard.html" -ForegroundColor Gray
Write-Host "   - Implementa el servicio" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Lee el archivo GUIA_CONFIGURAR_EASYPANEL_DASHBOARD_HTML.md para mas detalles" -ForegroundColor Yellow
Write-Host ""

