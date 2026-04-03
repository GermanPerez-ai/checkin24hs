# Script para diagnosticar error 503 en webmail
# Ejecuta este script en el servidor donde está desplegado el webmail

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔍 Diagnóstico de Error 503" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar configuración de Nginx
Write-Host "📋 Verificando configuración de Nginx..." -ForegroundColor Yellow
Write-Host ""

$nginxConfig = "/etc/nginx/sites-available/webmail.checkin24hs.com"
if (Test-Path $nginxConfig) {
    Write-Host "✅ Archivo de configuración encontrado" -ForegroundColor Green
    
    # Buscar proxy_pass
    $proxyPass = Select-String -Path $nginxConfig -Pattern "proxy_pass" -ErrorAction SilentlyContinue
    if ($proxyPass) {
        Write-Host "🔗 Proxy encontrado:" -ForegroundColor Yellow
        Write-Host "   $($proxyPass.Line.Trim())" -ForegroundColor Gray
        
        # Extraer puerto
        if ($proxyPass.Line -match ':\d+') {
            $port = $matches[0] -replace ':', ''
            Write-Host "   Puerto configurado: $port" -ForegroundColor Gray
            
            # Verificar si el puerto está en uso
            Write-Host ""
            Write-Host "🔌 Verificando puerto $port..." -ForegroundColor Yellow
            $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($connection) {
                Write-Host "✅ Puerto $port está en uso" -ForegroundColor Green
            } else {
                Write-Host "❌ Puerto $port NO está en uso" -ForegroundColor Red
                Write-Host "   El servicio backend no está corriendo" -ForegroundColor Yellow
            }
        }
    }
    
    # Buscar fastcgi_pass (PHP)
    $fastcgiPass = Select-String -Path $nginxConfig -Pattern "fastcgi_pass" -ErrorAction SilentlyContinue
    if ($fastcgiPass) {
        Write-Host "🔗 PHP-FPM encontrado:" -ForegroundColor Yellow
        Write-Host "   $($fastcgiPass.Line.Trim())" -ForegroundColor Gray
        
        # Verificar PHP-FPM
        Write-Host ""
        Write-Host "🐘 Verificando PHP-FPM..." -ForegroundColor Yellow
        $phpServices = @("php8.1-fpm", "php8.0-fpm", "php7.4-fpm", "php-fpm")
        $phpRunning = $false
        
        foreach ($phpService in $phpServices) {
            $status = Get-Service -Name $phpService -ErrorAction SilentlyContinue
            if ($status -and $status.Status -eq "Running") {
                Write-Host "✅ $phpService está corriendo" -ForegroundColor Green
                $phpRunning = $true
                break
            }
        }
        
        if (-not $phpRunning) {
            Write-Host "❌ PHP-FPM NO está corriendo" -ForegroundColor Red
            Write-Host "   Ejecuta: sudo systemctl start php8.1-fpm" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️  Archivo de configuración no encontrado en: $nginxConfig" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📡 Verificando puertos comunes..." -ForegroundColor Yellow
Write-Host ""

$commonPorts = @(80, 443, 8080, 3000, 9000)
foreach ($port in $commonPorts) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "✅ Puerto $port : En uso" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Puerto $port : No en uso" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🐳 Verificando contenedores Docker..." -ForegroundColor Yellow
Write-Host ""

try {
    $dockerContainers = docker ps -a 2>&1
    if ($LASTEXITCODE -eq 0) {
        $webmailContainers = $dockerContainers | Select-String -Pattern "webmail|roundcube|mail"
        if ($webmailContainers) {
            Write-Host "✅ Contenedores encontrados:" -ForegroundColor Green
            $webmailContainers | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        } else {
            Write-Host "⚠️  No se encontraron contenedores de webmail" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  Docker no está disponible o no hay permisos" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  No se pudo verificar Docker" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Verificando logs de Nginx..." -ForegroundColor Yellow
Write-Host ""

$errorLog = "/var/log/nginx/webmail-error.log"
if (Test-Path $errorLog) {
    Write-Host "📄 Últimas líneas del log de errores:" -ForegroundColor Yellow
    Write-Host ""
    Get-Content $errorLog -Tail 10 -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_ -match "503|Connection refused|upstream") {
            Write-Host "   $_" -ForegroundColor Red
        } else {
            Write-Host "   $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "⚠️  Log de errores no encontrado: $errorLog" -ForegroundColor Yellow
    Write-Host "   Verifica: sudo tail -f /var/log/nginx/error.log" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📋 Resumen y Próximos Pasos" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Si el puerto no está en uso:" -ForegroundColor White
Write-Host "   - Inicia el servicio backend (Node.js, Docker, etc.)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Si PHP-FPM no está corriendo:" -ForegroundColor White
Write-Host "   sudo systemctl start php8.1-fpm" -ForegroundColor Gray
Write-Host "   sudo systemctl enable php8.1-fpm" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Verifica los logs para más detalles:" -ForegroundColor White
Write-Host "   sudo tail -f /var/log/nginx/webmail-error.log" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Consulta SOLUCION_ERROR_503.md para más detalles" -ForegroundColor White
Write-Host ""

