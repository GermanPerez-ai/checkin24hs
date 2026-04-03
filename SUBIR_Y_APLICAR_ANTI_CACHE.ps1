# Script para subir y aplicar solucion anti-cache completa
# Ejecutar desde PowerShell en: C:\Users\German\Downloads\Checkin24hs

Write-Host "=== SUBIR Y APLICAR SOLUCION ANTI-CACHE COMPLETA ===" -ForegroundColor Green
Write-Host ""

# Verificar archivos
$files = @("deploy/dashboard.html", "server.js", "SOLUCION_COMPLETA_ANTI_CACHE.sh")
$missing = @()

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Host "ERROR: Faltan los siguientes archivos:" -ForegroundColor Red
    foreach ($file in $missing) {
        Write-Host "   - $file" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
foreach ($file in $files) {
    Write-Host "   - $file" -ForegroundColor White
}
Write-Host ""

Write-Host "Subiendo archivos al servidor..." -ForegroundColor Yellow
scp deploy/dashboard.html server.js SOLUCION_COMPLETA_ANTI_CACHE.sh root@72.61.58.240:/root/checkin24hs/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "ARCHIVOS SUBIDOS EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta estos comandos en SSH:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host "sed -i 's/\r$//' SOLUCION_COMPLETA_ANTI_CACHE.sh" -ForegroundColor White
    Write-Host "chmod +x SOLUCION_COMPLETA_ANTI_CACHE.sh" -ForegroundColor White
    Write-Host "bash SOLUCION_COMPLETA_ANTI_CACHE.sh" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Error al subir los archivos" -ForegroundColor Red
}
