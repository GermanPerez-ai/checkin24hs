# Restaurar backup estado1 - dashboard.html
$servidor = "root@72.61.58.240"
$rutaLocal = "C:\Users\German\Downloads\Checkin24hs"
$rutaServidor = "/root/checkin24hs"

Write-Host "=== RESTAURANDO BACKUP ESTADO1 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que el backup existe
$backup = "$rutaLocal\dashboard.html.backup.20251222_085633"
if (-not (Test-Path $backup)) {
    Write-Host "Error: No se encontro el backup" -ForegroundColor Red
    exit 1
}

# Ya está restaurado localmente, ahora subir al servidor
Write-Host "Subiendo dashboard.html restaurado..." -ForegroundColor Yellow
scp "$rutaLocal\deploy\dashboard.html" "${servidor}:${rutaServidor}/deploy/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Archivo subido correctamente" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Subiendo script de aplicacion..." -ForegroundColor Yellow
    scp "$rutaLocal\APLICAR_BACKUP_CORREGIDO.sh" "${servidor}:${rutaServidor}/APLICAR_BACKUP_CORREGIDO.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Script subido" -ForegroundColor Green
        Write-Host ""
        Write-Host "Aplicando en todos los contenedores..." -ForegroundColor Cyan
        ssh $servidor "chmod +x $rutaServidor/APLICAR_BACKUP_CORREGIDO.sh; bash $rutaServidor/APLICAR_BACKUP_CORREGIDO.sh"
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

