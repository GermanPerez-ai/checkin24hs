# Script para subir dashboard.html con correccion de hoteles
$server = "root@72.61.58.240"
$remotePath = "/root/checkin24hs/deploy"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SUBIENDO DASHBOARD CON CORRECCION DE HOTELES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Archivo a subir: deploy/dashboard.html" -ForegroundColor Yellow
Write-Host "Destino: ${server}:${remotePath}/dashboard.html" -ForegroundColor Yellow
Write-Host ""
Write-Host "MEJORAS INCLUIDAS:" -ForegroundColor Green
Write-Host "  - Los hoteles ahora se cargan desde Supabase" -ForegroundColor White
Write-Host "  - Solo muestra hoteles activos" -ForegroundColor White
Write-Host "  - Se actualiza automaticamente al cambiar de pestaña" -ForegroundColor White
Write-Host ""
Write-Host "Cuando te pida la contraseña, ingresala (no veras los caracteres)" -ForegroundColor Green
Write-Host ""
Write-Host "Presiona Enter para continuar..." -ForegroundColor White
Read-Host

scp deploy/dashboard.html "${server}:${remotePath}/dashboard.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Archivo subido exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Recarga el dashboard en el navegador (F5)" -ForegroundColor White
    Write-Host "2. Ve a Flor IA -> Pestaña 'Conocimiento'" -ForegroundColor White
    Write-Host "3. Deberias ver los hoteles activos en el dropdown" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Fallo al subir archivo" -ForegroundColor Red
    Write-Host "Verifica:" -ForegroundColor Yellow
    Write-Host "  - Que tengas conexion a internet" -ForegroundColor Gray
    Write-Host "  - Que la contraseña sea correcta" -ForegroundColor Gray
    Write-Host "  - Que el servidor este accesible" -ForegroundColor Gray
}

