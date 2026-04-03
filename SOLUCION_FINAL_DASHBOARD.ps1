# Solución Final - Subir dashboard.html corregido
$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "=== SOLUCION FINAL DASHBOARD ===" -ForegroundColor Cyan
Write-Host ""

# Verificar archivo
$archivo = "$rutaLocal\deploy\dashboard.html"
if (-not (Test-Path $archivo)) {
    Write-Host "Error: No se encontro el archivo" -ForegroundColor Red
    exit 1
}

# Verificar línea 5150
$lineas = Get-Content $archivo
$linea5150 = $lineas[5149]
Write-Host "Linea 5150 local: $linea5150" -ForegroundColor Yellow

# Subir archivo
Write-Host "Subiendo archivo..." -ForegroundColor Yellow
scp $archivo "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Subiendo script de aplicacion..." -ForegroundColor Yellow
    scp "$rutaLocal\APLICAR_SOLUCION_FINAL.sh" "${servidor}:${rutaServidor}/APLICAR_SOLUCION_FINAL.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Script subido" -ForegroundColor Green
        Write-Host ""
        Write-Host "Aplicando en servidor..." -ForegroundColor Cyan
        ssh $servidor "chmod +x $rutaServidor/APLICAR_SOLUCION_FINAL.sh; bash $rutaServidor/APLICAR_SOLUCION_FINAL.sh"
    }
    
} else {
    Write-Host "Error subiendo archivo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "Abre en modo incognito: https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host ""

