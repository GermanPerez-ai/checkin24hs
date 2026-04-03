# Script para subir dashboard.html optimizado al servidor
$server = "root@72.61.58.240"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"
$localFile = "deploy/dashboard.html"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SUBIENDO DASHBOARD OPTIMIZADO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $localFile)) {
    Write-Host "Error: No se encontro el archivo $localFile" -ForegroundColor Red
    Write-Host "Asegurate de estar en el directorio correcto (Checkin24hs)" -ForegroundColor Yellow
    exit 1
}

# Verificar tamano del archivo
$fileSize = (Get-Item $localFile).Length / 1MB
Write-Host "Archivo local: $localFile" -ForegroundColor Yellow
Write-Host "Tamano: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Yellow
Write-Host "Servidor: $server" -ForegroundColor Yellow
Write-Host "Ruta remota: $remotePath" -ForegroundColor Yellow
Write-Host ""

Write-Host "OPTIMIZACIONES INCLUIDAS:" -ForegroundColor Green
Write-Host "  - Polling con backoff exponencial (2s a 10s)" -ForegroundColor White
Write-Host "  - Timeout aumentado a 10 segundos" -ForegroundColor White
Write-Host "  - Actualizacion automatica del QR cada 30s" -ForegroundColor White
Write-Host "  - Mayor tolerancia a errores (120 intentos)" -ForegroundColor White
Write-Host "  - Manejo mejorado de errores de red" -ForegroundColor White
Write-Host ""

Write-Host "Subiendo archivo..." -ForegroundColor Yellow
$startTime = Get-Date
scp $localFile "${server}:${remotePath}"
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Archivo subido exitosamente en $([math]::Round($duration, 2)) segundos" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Recarga la pagina del dashboard (Ctrl+Shift+R o F5)" -ForegroundColor White
    Write-Host "2. Prueba conectar WhatsApp nuevamente" -ForegroundColor White
    Write-Host "3. Deberias notar:" -ForegroundColor White
    Write-Host "   - QR aparece mas rapido" -ForegroundColor Gray
    Write-Host "   - Menos errores durante la conexion" -ForegroundColor Gray
    Write-Host "   - QR se actualiza automaticamente si expira" -ForegroundColor Gray
    Write-Host "   - Conexion mas estable" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Si el dashboard no se actualiza, espera 30 segundos y recarga" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Error al subir el archivo" -ForegroundColor Red
    Write-Host "Verifica:" -ForegroundColor Yellow
    Write-Host "   - Que tengas conexion a internet" -ForegroundColor Gray
    Write-Host "   - Que la clave SSH este configurada" -ForegroundColor Gray
    Write-Host "   - Que el servidor este accesible" -ForegroundColor Gray
    exit 1
}
