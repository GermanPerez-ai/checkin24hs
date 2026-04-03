# Script PowerShell para actualizar BUILD_NUMBER y BUILD_TIMESTAMP en dashboard (raíz + deploy)
# Así el servidor siempre recibe el mismo número que la raíz. Ejecutado por pre-commit.

$rootFile = "dashboard.html"
$deployFile = "deploy/dashboard.html"
$buildIdFile = "deploy/dashboard-html/BUILD_ID"

# Usar el mayor build number entre raíz y deploy para no bajar de versión
$currentBuild = 64
foreach ($f in @($rootFile, $deployFile)) {
    if (Test-Path $f) {
        $c = Get-Content $f -Raw -Encoding UTF8
        if ($c -match 'window\.DASHBOARD_BUILD_NUMBER\s*=\s*([0-9]+)') {
            $n = [int]$matches[1]
            if ($n -gt $currentBuild) { $currentBuild = $n }
        }
    }
}

$newBuild = $currentBuild + 1
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "Actualizando build number (raiz + deploy + BUILD_ID)..." -ForegroundColor Cyan
Write-Host "   Build actual: $currentBuild -> Nuevo: $newBuild" -ForegroundColor Gray
Write-Host "   Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

function Update-DashboardContent {
    param([string]$content, [int]$build, [string]$ts)
    $content = $content -replace 'window\.DASHBOARD_BUILD_NUMBER\s*=\s*[0-9]+', "window.DASHBOARD_BUILD_NUMBER = $build"
    $content = $content -replace "window\.DASHBOARD_BUILD\s*=\s*'[^']+'", "window.DASHBOARD_BUILD = '$ts'"
    $content = $content -replace '(<span id="build-number">)[0-9]+(</span>)', "`${1}$build`$2"
    return $content
}

# Raíz
if (Test-Path $rootFile) {
    $content = Get-Content $rootFile -Raw -Encoding UTF8
    $content = Update-DashboardContent -content $content -build $newBuild -ts $timestamp
    Set-Content -Path $rootFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "OK $rootFile = $newBuild" -ForegroundColor Green
}

# Deploy (el que usa el servidor)
if (Test-Path $deployFile) {
    $content = Get-Content $deployFile -Raw -Encoding UTF8
    $content = Update-DashboardContent -content $content -build $newBuild -ts $timestamp
    Set-Content -Path $deployFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "OK $deployFile = $newBuild" -ForegroundColor Green
}

# BUILD_ID para el script de deploy en el servidor
$buildIdDir = Split-Path $buildIdFile -Parent
if (-not (Test-Path $buildIdDir)) { New-Item -ItemType Directory -Path $buildIdDir -Force | Out-Null }
Set-Content -Path $buildIdFile -Value "$newBuild`n" -Encoding UTF8 -NoNewline
Write-Host "OK $buildIdFile = $newBuild" -ForegroundColor Green
Write-Host ""
