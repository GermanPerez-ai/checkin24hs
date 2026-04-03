# Script para subir el archivo correcto al servidor
$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "Subiendo dashboard.html corregido..." -ForegroundColor Cyan

# Verificar archivo local
$archivo = "$rutaLocal\deploy\dashboard.html"
if (-not (Test-Path $archivo)) {
    Write-Host "Error: No se encontro el archivo" -ForegroundColor Red
    exit 1
}

# Verificar línea 5150 local
$lineas = Get-Content $archivo
$linea5150 = $lineas[5149]
Write-Host "Linea 5150 local: $linea5150" -ForegroundColor Yellow

# Subir archivo
scp $archivo "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta en el servidor:" -ForegroundColor Cyan
    Write-Host "  bash /root/checkin24hs/VERIFICAR_Y_CORREGIR_TODOS.sh" -ForegroundColor White
} else {
    Write-Host "Error subiendo archivo" -ForegroundColor Red
}




