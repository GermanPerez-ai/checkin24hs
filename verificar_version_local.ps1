# Script PowerShell para verificar version del dashboard.html local

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICACION DE VERSION LOCAL" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$dashboardPath = "C:\Users\German\Downloads\Checkin24hs\dashboard.html"

if (-not (Test-Path $dashboardPath)) {
    Write-Host "ERROR: No se encontro el archivo dashboard.html" -ForegroundColor Red
    Write-Host "   Ruta esperada: $dashboardPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK Archivo encontrado: $dashboardPath" -ForegroundColor Green
Write-Host ""

# Leer el archivo
$content = Get-Content $dashboardPath -Raw -Encoding UTF8

# Extraer version usando metodo simple
$versionLine = $content | Select-String -Pattern "window\.DASHBOARD_VERSION\s*=" | Select-Object -First 1
$buildLine = $content | Select-String -Pattern "window\.BUILD_TIMESTAMP\s*=" | Select-Object -First 1

if ($versionLine) {
    $versionMatch = $versionLine.Line -match "['`"]([^'`"]+)['`"]"
    if ($versionMatch) {
        $version = $matches[1]
        Write-Host "Version: $version" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No se pudo extraer la version" -ForegroundColor Red
        $version = ""
    }
} else {
    Write-Host "ERROR: No se encontro window.DASHBOARD_VERSION" -ForegroundColor Red
    $version = ""
}

if ($buildLine) {
    $buildMatch = $buildLine.Line -match "['`"]([^'`"]+)['`"]"
    if ($buildMatch) {
        $build = $matches[1]
        Write-Host "Build:   $build" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No se pudo extraer el build" -ForegroundColor Red
        $build = ""
    }
} else {
    Write-Host "ERROR: No se encontro window.BUILD_TIMESTAMP" -ForegroundColor Red
    $build = ""
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "INSTRUCCIONES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para comparar con el servidor:" -ForegroundColor Yellow
Write-Host "1. Ejecuta en el servidor: ./verificar_version_simple_final.sh" -ForegroundColor White
Write-Host "2. O verifica en Chrome (F12 -> Console):" -ForegroundColor White
Write-Host "   window.DASHBOARD_VERSION" -ForegroundColor Gray
Write-Host "   window.BUILD_TIMESTAMP" -ForegroundColor Gray
Write-Host ""
Write-Host "Si los valores son diferentes, necesitas subir el archivo al servidor." -ForegroundColor Yellow
Write-Host ""
