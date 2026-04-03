# Script para incrementar build number automáticamente antes de commit
# Uso: .\INCREMENTAR_BUILD_AUTOMATICO.ps1

$DASHBOARD_PATH = "dashboard.html"

Write-Host ""
Write-Host "🔢 Incrementando Build Number..." -ForegroundColor Cyan

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

Write-Host "✅ Build incrementado a #$newBuild" -ForegroundColor Green
Write-Host ""
