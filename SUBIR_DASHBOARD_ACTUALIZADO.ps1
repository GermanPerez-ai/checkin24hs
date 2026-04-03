# Script para subir dashboard.html actualizado al servidor
$servidor = "root@72.61.58.240"
$rutaLocal = "deploy\dashboard.html"
$rutaRemota = "/root/checkin24hs/deploy/dashboard.html"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SUBIENDO DASHBOARD ACTUALIZADO AL SERVIDOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo local existe
if (-not (Test-Path $rutaLocal)) {
    Write-Host "ERROR: No se encontro el archivo: $rutaLocal" -ForegroundColor Red
    Write-Host "Asegurate de estar en el directorio correcto" -ForegroundColor Yellow
    exit 1
}

Write-Host "Archivo local encontrado: $rutaLocal" -ForegroundColor Green

# Verificar que tiene los cambios
$contenido = Get-Content $rutaLocal -Raw
if ($contenido -match "normalizeServerUrl") {
    Write-Host "Archivo local tiene los cambios necesarios" -ForegroundColor Green
} else {
    Write-Host "ERROR: El archivo local NO tiene los cambios necesarios" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow
Write-Host "Servidor: $servidor" -ForegroundColor Gray
Write-Host "Ruta remota: $rutaRemota" -ForegroundColor Gray
Write-Host ""

# Usar SCP para subir el archivo
try {
    scp $rutaLocal "${servidor}:${rutaRemota}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Archivo subido correctamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "Proximos pasos:" -ForegroundColor Cyan
        Write-Host "1. Conectate al servidor: ssh $servidor" -ForegroundColor White
        Write-Host "2. Ejecuta: cd /root/checkin24hs" -ForegroundColor White
        Write-Host "3. Ejecuta: bash ACTUALIZAR_DASHBOARD_SERVIDOR.sh" -ForegroundColor White
    } else {
        Write-Host "Error al subir el archivo (codigo: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "Verifica tu conexion SSH y permisos" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternativa manual:" -ForegroundColor Yellow
    Write-Host "1. Usa WinSCP, FileZilla o similar para subir el archivo" -ForegroundColor White
    Write-Host "2. Sube: deploy\dashboard.html" -ForegroundColor White
    Write-Host "3. A: /root/checkin24hs/deploy/dashboard.html" -ForegroundColor White
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
