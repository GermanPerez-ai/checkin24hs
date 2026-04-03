# Script simple para subir dashboard.html usando SCP
# Ajusta el HOSTNAME o IP según tu servidor

$hostname = "srv1152402.hostinger.com"  # Cambia esto por tu IP o hostname real
$archivo = "deploy\dashboard.html"
$destino = "/root/checkin24hs/deploy/dashboard.html"

Write-Host "Subiendo archivo al servidor..." -ForegroundColor Yellow
Write-Host "Host: $hostname" -ForegroundColor Gray
Write-Host "Archivo: $archivo" -ForegroundColor Gray
Write-Host "Destino: $destino" -ForegroundColor Gray
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $archivo)) {
    Write-Host "ERROR: No se encontro el archivo: $archivo" -ForegroundColor Red
    Write-Host "Asegurate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

# Ejecutar SCP
Write-Host "Ejecutando SCP..." -ForegroundColor Cyan
scp $archivo "root@${hostname}:${destino}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Archivo subido correctamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conectate al servidor y ejecuta:" -ForegroundColor Cyan
    Write-Host "  ssh root@$hostname" -ForegroundColor White
    Write-Host "  cd /root/checkin24hs" -ForegroundColor White
    Write-Host "  python3 ACTUALIZAR_DASHBOARD_SERVIDOR.py" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  1. El hostname no es correcto (cambialo en la linea 4 del script)" -ForegroundColor White
    Write-Host "  2. No tienes acceso SSH configurado" -ForegroundColor White
    Write-Host "  3. El servidor no esta accesible" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternativa: Usa WinSCP o FileZilla para subir el archivo manualmente" -ForegroundColor Cyan
}



