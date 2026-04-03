# Subir dashboard.html directamente al servidor (sin pasar por GitHub)

Write-Host "📤 Subiendo dashboard.html directamente al servidor..." -ForegroundColor Cyan
Write-Host ""

$archivoLocal = "C:\Users\German\Downloads\Checkin24hs\dashboard.html"
$servidor = "root@72.61.58.240"
$rutaServidor = "/root/checkin24hs/dashboard.html"

# Verificar que el archivo existe
if (-not (Test-Path $archivoLocal)) {
    Write-Host "❌ Error: No se encontró $archivoLocal" -ForegroundColor Red
    exit 1
}

# Verificar Build local
$buildLocal = Select-String -Path $archivoLocal -Pattern "window\.DASHBOARD_BUILD_NUMBER = (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
Write-Host "📊 Build Local: #$buildLocal" -ForegroundColor Green
Write-Host ""

# Subir archivo
Write-Host "📤 Subiendo archivo..." -ForegroundColor Yellow
scp $archivoLocal "${servidor}:${rutaServidor}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔧 Ahora ejecuta en el servidor:" -ForegroundColor Cyan
    Write-Host "   docker service update --force checkin24hs_dashboard" -ForegroundColor White
} else {
    Write-Host "❌ Error al subir archivo" -ForegroundColor Red
}
