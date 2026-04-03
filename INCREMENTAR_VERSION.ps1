# Script para incrementar el build number del dashboard

$DASHBOARD_PATH = "deploy\dashboard.html"
$BACKUP_FILE = "deploy\dashboard.html.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "INCREMENTAR VERSION DEL DASHBOARD" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Crear backup
Copy-Item $DASHBOARD_PATH -Destination $BACKUP_FILE -Force
Write-Host "OK: Backup creado: $BACKUP_FILE" -ForegroundColor Green
Write-Host ""

Write-Host "=== Incrementar build number ===" -ForegroundColor Yellow

# Leer archivo
$content = Get-Content $DASHBOARD_PATH -Raw -Encoding UTF8

# Obtener build number actual
if ($content -match "window\.DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)") {
    $currentBuild = [int]$matches[1]
    $newBuild = $currentBuild + 1
    Write-Host "Build actual: $currentBuild" -ForegroundColor Gray
    Write-Host "Nuevo build: $newBuild" -ForegroundColor Green
} else {
    $newBuild = 1
    Write-Host "Primer build: $newBuild" -ForegroundColor Green
}

# Generar timestamp actual
$currentTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "Timestamp: $currentTimestamp" -ForegroundColor Gray

# Actualizar build number
$content = $content -replace "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+", "window.DASHBOARD_BUILD_NUMBER = $newBuild"

# Actualizar build timestamp
$content = $content -replace "window\.DASHBOARD_BUILD\s*=\s*'[^']+'", "window.DASHBOARD_BUILD = '$currentTimestamp'"

# Guardar archivo
Set-Content -Path $DASHBOARD_PATH -Value $content -Encoding UTF8 -NoNewline

Write-Host "OK: Version actualizada" -ForegroundColor Green
Write-Host ""

Write-Host "=== Verificar cambios ===" -ForegroundColor Yellow
Select-String -Path $DASHBOARD_PATH -Pattern "DASHBOARD_BUILD|DASHBOARD_BUILD_NUMBER" | Select-Object -First 2
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "OK: Version incrementada. Listo para commit y push" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

exit 0
