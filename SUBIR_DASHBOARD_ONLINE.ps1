# SUBIR_DASHBOARD_ONLINE.ps1
# Ejecutá este script en la raíz del repo cuando quieras que lo que tenés en local
# sea lo que se sirva en https://dashboard.checkin24hs.com/
#
# Qué hace:
# 1. Sube el número de build (79 -> 80, etc.) en todos los archivos.
# 2. Sincroniza deploy/dashboard.html con dashboard.html de la raíz (mismo contenido).
# 3. Te dice exactamente qué hacer en EasyPanel para que no use caché vieja.

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = Get-Location.Path }

# Detectar build actual desde dashboard.html raíz
$dashboardRoot = Join-Path $root "dashboard.html"
if (-not (Test-Path $dashboardRoot)) {
    Write-Host "No se encuentra dashboard.html en la raíz. Ejecutá el script desde la carpeta del repo." -ForegroundColor Red
    exit 1
}

$content = Get-Content $dashboardRoot -Raw
if ($content -match 'DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)') {
    $currentBuild = [int]$Matches[1]
} else {
    Write-Host "No se pudo leer el build actual en dashboard.html." -ForegroundColor Red
    exit 1
}

$nextBuild = $currentBuild + 1
$today = Get-Date -Format "yyyy-MM-dd"
Write-Host ""
Write-Host "Build actual: $currentBuild -> Nuevo build: $nextBuild" -ForegroundColor Cyan
Write-Host ""

# 1) Actualizar dashboard.html (raíz)
$content = $content -replace 'DASHBOARD_BUILD_NUMBER\s*=\s*\d+', "DASHBOARD_BUILD_NUMBER = $nextBuild"
$content = $content -replace 'Build #<span id="build-number">\d+</span>', "Build #<span id=`"build-number`">$nextBuild</span>"
$content = $content -replace '<!-- BUILD: #\d+[^>]*-->', "<!-- BUILD: #$nextBuild - $today - Subir online -->"
Set-Content -Path $dashboardRoot -Value $content -NoNewline -Encoding UTF8
Write-Host "  [OK] dashboard.html (raíz) -> Build #$nextBuild" -ForegroundColor Green

# 2) Copiar dashboard.html raíz -> deploy/dashboard.html (para que coincidan)
$deployDashboard = Join-Path $root "deploy\dashboard.html"
Copy-Item -Path $dashboardRoot -Destination $deployDashboard -Force
Write-Host "  [OK] deploy/dashboard.html sincronizado con raíz" -ForegroundColor Green

# 3) Actualizar docker-compose.easypanel.yml
$composePath = Join-Path $root "docker-compose.easypanel.yml"
$compose = Get-Content $composePath -Raw
$compose = $compose -replace 'BUILD_ID:\s*"\d+"', "BUILD_ID: `"$nextBuild`""
Set-Content -Path $composePath -Value $compose -NoNewline -Encoding UTF8
Write-Host "  [OK] docker-compose.easypanel.yml -> BUILD_ID: $nextBuild" -ForegroundColor Green

# 4) Actualizar deploy/dashboard-html/BUILD_ID (esto invalida la caché de Docker en el servidor)
$buildIdPath = Join-Path $root "deploy\dashboard-html\BUILD_ID"
Set-Content -Path $buildIdPath -Value "$nextBuild" -NoNewline -Encoding UTF8
Write-Host "  [OK] deploy/dashboard-html/BUILD_ID -> $nextBuild" -ForegroundColor Green

# 5) Actualizar ARG en Dockerfile
$dockerfilePath = Join-Path $root "deploy\dashboard-html\Dockerfile"
$dockerfile = Get-Content $dockerfilePath -Raw
$dockerfile = $dockerfile -replace 'ARG BUILD_ID=\d+', "ARG BUILD_ID=$nextBuild"
Set-Content -Path $dockerfilePath -Value $dockerfile -NoNewline -Encoding UTF8
Write-Host "  [OK] deploy/dashboard-html/Dockerfile -> ARG BUILD_ID=$nextBuild" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  LISTO. Ahora hacé esto (en orden):" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Subir los cambios a GitHub:" -ForegroundColor White
Write-Host "   git add dashboard.html deploy/dashboard.html deploy/dashboard-html/BUILD_ID deploy/dashboard-html/Dockerfile docker-compose.easypanel.yml" -ForegroundColor Gray
Write-Host "   git commit -m \"Dashboard Build #$nextBuild - subir online\"" -ForegroundColor Gray
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "2. En EasyPanel:" -ForegroundColor White
Write-Host "   - Entrá a tu app del dashboard." -ForegroundColor Gray
Write-Host "   - Clic en REDEPLOY (o Deploy)." -ForegroundColor Gray
Write-Host "   - Si ves opcion 'Build without cache' / 'No cache' / 'Clear cache', ACTIVALA esta vez." -ForegroundColor Gray
Write-Host ""
Write-Host "3. Esperá 1-2 minutos, luego abrí:" -ForegroundColor White
Write-Host "   https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host "   Y en el navegador: Ctrl+Shift+R (recarga forzada sin cache)." -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verificá que diga Build #$nextBuild abajo a la izquierda en el menu." -ForegroundColor White
Write-Host ""
Write-Host "Si después de esto sigue viendo la version vieja, usa el plan B: CORRER_DASHBOARD_LOCAL_ONLINE.md" -ForegroundColor Yellow
Write-Host ""
