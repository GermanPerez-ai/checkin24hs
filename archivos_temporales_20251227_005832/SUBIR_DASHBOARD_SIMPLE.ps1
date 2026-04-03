# Script simple para subir dashboard.html corregido
# Ejecutar desde PowerShell en tu computadora Windows

$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "Subiendo dashboard.html corregido al servidor..." -ForegroundColor Cyan
Write-Host ""

# Verificar archivo
$archivo = "$rutaLocal\deploy\dashboard.html"
if (-not (Test-Path $archivo)) {
    Write-Host "Error: No se encontro deploy\dashboard.html" -ForegroundColor Red
    exit 1
}

# Subir archivo
Write-Host "Subiendo archivo..." -ForegroundColor Yellow
scp $archivo "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    
    # Subir script bash
    Write-Host ""
    Write-Host "Subiendo script de aplicacion..." -ForegroundColor Yellow
    scp "$rutaLocal\APLICAR_DASHBOARD_CORREGIDO.sh" "${servidor}:${rutaServidor}/APLICAR_DASHBOARD_CORREGIDO.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Script subido correctamente" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Aplicando cambios en contenedores..." -ForegroundColor Cyan
        $comando = "chmod +x $rutaServidor/APLICAR_DASHBOARD_CORREGIDO.sh; bash $rutaServidor/APLICAR_DASHBOARD_CORREGIDO.sh"
        ssh $servidor $comando
    }
} else {
    Write-Host "Error subiendo archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica los cambios en: https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host "IMPORTANTE: Limpia la cache del navegador completamente" -ForegroundColor Yellow
Write-Host ""




