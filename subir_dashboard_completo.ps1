# Script PowerShell para subir dashboard.html al servidor
# Uso: .\subir_dashboard_completo.ps1

Write-Host "🚀 SUBIENDO dashboard.html AL SERVIDOR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path "dashboard.html")) {
    Write-Host "❌ ERROR: No se encontró dashboard.html en la carpeta actual" -ForegroundColor Red
    Write-Host "💡 Asegúrate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Archivo encontrado: dashboard.html" -ForegroundColor Green
$fileSize = (Get-Item "dashboard.html").Length / 1MB
Write-Host "   Tamaño: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
Write-Host ""

# IP del servidor
$serverIP = "72.61.58.240"
$serverUser = "root"

Write-Host "📤 Paso 1: Subiendo archivo al servidor..." -ForegroundColor Cyan
Write-Host "   Servidor: $serverUser@$serverIP" -ForegroundColor Gray
Write-Host ""

# Subir el archivo
try {
    scp dashboard.html "${serverUser}@${serverIP}:/tmp/dashboard.html"
    Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR al subir el archivo: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Soluciones:" -ForegroundColor Yellow
    Write-Host "   1. Verifica que tienes OpenSSH instalado" -ForegroundColor Yellow
    Write-Host "   2. O usa WinSCP para subir el archivo manualmente" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔧 Paso 2: Conectándose al servidor..." -ForegroundColor Cyan
Write-Host "   Ejecuta estos comandos en el servidor:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   curl -o reemplazar_dashboard.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/reemplazar_dashboard_servidor.sh" -ForegroundColor White
Write-Host "   chmod +x reemplazar_dashboard.sh" -ForegroundColor White
Write-Host "   ./reemplazar_dashboard.sh" -ForegroundColor White
Write-Host ""

# Preguntar si quiere conectarse automáticamente
$connect = Read-Host "¿Conectarse al servidor ahora? (s/n)"
if ($connect -eq "s" -or $connect -eq "S") {
    Write-Host ""
    Write-Host "🔗 Conectando al servidor..." -ForegroundColor Cyan
    ssh "${serverUser}@${serverIP}"
} else {
    Write-Host ""
    Write-Host "✅ Archivo subido. Conéctate manualmente cuando estés listo." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ PROCESO COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 Próximos pasos:" -ForegroundColor Yellow
Write-Host "   1. Ejecuta el script reemplazar_dashboard.sh en el servidor" -ForegroundColor White
Write-Host "   2. Espera a que termine" -ForegroundColor White
Write-Host "   3. Abre https://dashboard.checkin24hs.com" -ForegroundColor White
Write-Host "   4. Presiona Ctrl+F5 (limpiar caché)" -ForegroundColor White
Write-Host "   5. Verifica que funciona" -ForegroundColor White
Write-Host ""

