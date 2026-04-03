# Script PowerShell para actualizar automáticamente el BUILD_TIMESTAMP en dashboard.html
# Ejecutar antes de cada commit o deploy

$dashboardFile = "dashboard.html"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

if (-not (Test-Path $dashboardFile)) {
    Write-Host "❌ Error: No se encuentra $dashboardFile" -ForegroundColor Red
    exit 1
}

# Leer el archivo
$content = Get-Content $dashboardFile -Raw

# Actualizar BUILD_TIMESTAMP usando regex
$pattern = "window\.BUILD_TIMESTAMP = '[^']*'"
$replacement = "window.BUILD_TIMESTAMP = '$timestamp'"
$content = $content -replace $pattern, $replacement

# Guardar el archivo
Set-Content -Path $dashboardFile -Value $content -NoNewline

Write-Host "BUILD_TIMESTAMP actualizado a: $timestamp" -ForegroundColor Green
Write-Host "Archivo: $dashboardFile" -ForegroundColor Cyan
