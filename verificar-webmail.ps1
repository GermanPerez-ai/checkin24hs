# Script para verificar el estado del webmail
# Ejecuta este script en el servidor donde está desplegado el webmail

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔍 Verificación del Estado del Webmail" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar servicios relacionados con correo
Write-Host "📋 Verificando servicios de correo..." -ForegroundColor Yellow
Write-Host ""

$services = @("roundcube", "postfix", "dovecot", "nginx")

foreach ($service in $services) {
    $status = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($status) {
        if ($status.Status -eq "Running") {
            Write-Host "✅ $service : $($status.Status)" -ForegroundColor Green
        } else {
            Write-Host "❌ $service : $($status.Status)" -ForegroundColor Red
            Write-Host "   Ejecuta: sudo systemctl start $service" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  $service : No encontrado" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📡 Verificando puertos en uso..." -ForegroundColor Yellow
Write-Host ""

# Verificar puertos comunes de webmail
$ports = @(80, 443, 8080, 8081)

foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "✅ Puerto $port : En uso" -ForegroundColor Green
        Write-Host "   Estado: $($connection.State)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Puerto $port : No en uso" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🌐 Verificando acceso al webmail..." -ForegroundColor Yellow
Write-Host ""

$webmailUrl = "http://webmail.checkin24hs.com"
try {
    $response = Invoke-WebRequest -Uri $webmailUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Webmail accesible: $webmailUrl" -ForegroundColor Green
    Write-Host "   Código de estado: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Webmail no accesible: $webmailUrl" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Si los servicios no están corriendo, inícialos:" -ForegroundColor White
Write-Host "   sudo systemctl start roundcube postfix dovecot nginx" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Verifica la configuración de Nginx:" -ForegroundColor White
Write-Host "   sudo nginx -t" -ForegroundColor Gray
Write-Host "   sudo systemctl reload nginx" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Revisa los logs si hay problemas:" -ForegroundColor White
Write-Host "   sudo tail -f /var/log/nginx/webmail-error.log" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Consulta SOLUCION_WEBMAIL.md para más detalles" -ForegroundColor White
Write-Host ""

