# Script para verificar el error de conexión IMAP del webmail

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔍 VERIFICACIÓN ERROR CONEXIÓN IMAP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$SERVICE_NAME = "checkin24hs_webmail"
$IMAP_HOST = "mail.checkin24hs.com"
$IMAP_IP = "72.61.58.240"

# 1. Verificar variables de entorno del servicio
Write-Host "1️⃣ Variables de entorno del servicio webmail:" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

try {
    $envVars = docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s`n" .}}{{end}}' 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ No se pudo obtener las variables de entorno" -ForegroundColor Red
        Write-Host "   Verifica que el servicio '$SERVICE_NAME' exista" -ForegroundColor Yellow
    } else {
        Write-Host "Variables relacionadas con IMAP/SMTP:" -ForegroundColor White
        $envVars | Select-String -Pattern "ROUNDCUBE|IMAP|SMTP|MAIL|HOST|PORT|SSL" | Sort-Object
        
        Write-Host ""
        Write-Host "📋 Configuración actual:" -ForegroundColor White
        
        $defaultHost = ($envVars | Select-String -Pattern "ROUNDCUBEMAIL_DEFAULT_HOST=").ToString().Split("=")[1]
        $defaultPort = ($envVars | Select-String -Pattern "ROUNDCUBEMAIL_DEFAULT_PORT=").ToString().Split("=")[1]
        $defaultSSL = ($envVars | Select-String -Pattern "ROUNDCUBEMAIL_DEFAULT_HOST_SSL=").ToString().Split("=")[1]
        $smtpServer = ($envVars | Select-String -Pattern "ROUNDCUBEMAIL_SMTP_SERVER=").ToString().Split("=")[1]
        
        if ($defaultHost) {
            Write-Host "   ROUNDCUBEMAIL_DEFAULT_HOST: $defaultHost" -ForegroundColor Green
        } else {
            Write-Host "   ❌ ROUNDCUBEMAIL_DEFAULT_HOST: NO CONFIGURADO" -ForegroundColor Red
        }
        
        if ($defaultPort) {
            Write-Host "   ROUNDCUBEMAIL_DEFAULT_PORT: $defaultPort" -ForegroundColor Green
        } else {
            Write-Host "   ❌ ROUNDCUBEMAIL_DEFAULT_PORT: NO CONFIGURADO" -ForegroundColor Red
        }
        
        if ($defaultSSL) {
            Write-Host "   ROUNDCUBEMAIL_DEFAULT_HOST_SSL: $defaultSSL" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  ROUNDCUBEMAIL_DEFAULT_HOST_SSL: NO CONFIGURADO (por defecto: false)" -ForegroundColor Yellow
        }
        
        if ($smtpServer) {
            Write-Host "   ROUNDCUBEMAIL_SMTP_SERVER: $smtpServer" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  ROUNDCUBEMAIL_SMTP_SERVER: NO CONFIGURADO" -ForegroundColor Yellow
        }
        
        # Verificar si está usando IP en lugar de dominio
        if ($defaultHost -eq $IMAP_IP) {
            Write-Host ""
            Write-Host "   ⚠️  ADVERTENCIA: Está usando IP directa ($IMAP_IP) en lugar del dominio" -ForegroundColor Yellow
            Write-Host "      Debería usar: mail.checkin24hs.com" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ Error al obtener variables de entorno: $_" -ForegroundColor Red
}

Write-Host ""

# 2. Verificar contenedor
Write-Host "2️⃣ Configuración dentro del contenedor:" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$containerId = docker ps --filter "name=webmail" --format "{{.ID}}" | Select-Object -First 1

if (-not $containerId) {
    Write-Host "❌ No se encontró contenedor activo de webmail" -ForegroundColor Red
    Write-Host "   Verifica que el servicio esté corriendo: docker service ps $SERVICE_NAME" -ForegroundColor Yellow
} else {
    Write-Host "✅ Contenedor encontrado: $containerId" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "   Archivo config.inc.php (buscando configuración IMAP):" -ForegroundColor White
    docker exec $containerId grep -iE "default_host|imap_host|imap_port|imap_conn_options" /var/www/html/config/config.inc.php 2>&1 | Select-Object -First 10
    
    Write-Host ""
    Write-Host "   Archivo config.docker.inc.php (últimas 30 líneas):" -ForegroundColor White
    docker exec $containerId tail -30 /var/www/html/config/config.docker.inc.php 2>&1
}

Write-Host ""

# 3. Verificar conectividad con el servidor IMAP
Write-Host "3️⃣ Verificando conectividad con el servidor IMAP:" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Host "   Probando mail.checkin24hs.com:993 (IMAP SSL)..." -ForegroundColor White
$test993 = Test-NetConnection -ComputerName $IMAP_HOST -Port 993 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($test993.TcpTestSucceeded) {
    Write-Host "   ✅ Puerto 993 accesible en $IMAP_HOST" -ForegroundColor Green
} else {
    Write-Host "   ❌ Puerto 993 NO accesible en $IMAP_HOST" -ForegroundColor Red
}

Write-Host "   Probando mail.checkin24hs.com:143 (IMAP sin SSL)..." -ForegroundColor White
$test143 = Test-NetConnection -ComputerName $IMAP_HOST -Port 143 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($test143.TcpTestSucceeded) {
    Write-Host "   ✅ Puerto 143 accesible en $IMAP_HOST" -ForegroundColor Green
} else {
    Write-Host "   ❌ Puerto 143 NO accesible en $IMAP_HOST" -ForegroundColor Red
}

Write-Host ""
Write-Host "   Probando $IMAP_IP:993 (IMAP SSL)..." -ForegroundColor White
$test993IP = Test-NetConnection -ComputerName $IMAP_IP -Port 993 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($test993IP.TcpTestSucceeded) {
    Write-Host "   ✅ Puerto 993 accesible en $IMAP_IP" -ForegroundColor Green
} else {
    Write-Host "   ❌ Puerto 993 NO accesible en $IMAP_IP" -ForegroundColor Red
}

Write-Host "   Probando $IMAP_IP:143 (IMAP sin SSL)..." -ForegroundColor White
$test143IP = Test-NetConnection -ComputerName $IMAP_IP -Port 143 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($test143IP.TcpTestSucceeded) {
    Write-Host "   ✅ Puerto 143 accesible en $IMAP_IP" -ForegroundColor Green
} else {
    Write-Host "   ❌ Puerto 143 NO accesible en $IMAP_IP" -ForegroundColor Red
}

# Verificar resolución DNS
Write-Host ""
Write-Host "   Verificando resolución DNS:" -ForegroundColor White
try {
    $dnsResult = Resolve-DnsName -Name $IMAP_HOST -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dnsResult) {
        Write-Host "   ✅ $IMAP_HOST resuelve a: $($dnsResult.IPAddress)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No se pudo resolver $IMAP_HOST" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Error al resolver DNS: $_" -ForegroundColor Red
}

Write-Host ""

# 4. Verificar servicios de correo
Write-Host "4️⃣ Verificando servicios de correo en el servidor:" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "   Servicios Docker relacionados con correo:" -ForegroundColor White
docker ps --format "table {{.Names}}\t{{.Ports}}" | Select-String -Pattern "mail|postfix|dovecot|imap|smtp"

Write-Host ""

# 5. Verificar logs
Write-Host "5️⃣ Logs del webmail (buscando errores IMAP):" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "   Últimas 50 líneas de logs:" -ForegroundColor White
docker service logs $SERVICE_NAME --tail 50 2>&1 | Select-String -Pattern "imap|error|failed|connection|authentication" | Select-Object -Last 20

Write-Host ""

# 6. Resumen
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "💡 DIAGNÓSTICO Y RECOMENDACIONES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if ($defaultHost -eq $IMAP_IP) {
    Write-Host "❌ PROBLEMA IDENTIFICADO:" -ForegroundColor Red
    Write-Host "   El webmail está configurado para usar la IP directa ($IMAP_IP)" -ForegroundColor Yellow
    Write-Host "   en lugar del dominio (mail.checkin24hs.com)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   SOLUCIÓN:" -ForegroundColor Green
    Write-Host "   1. Ve a EasyPanel → Servicio 'webmail' → Variables de Entorno" -ForegroundColor White
    Write-Host "   2. Cambia ROUNDCUBEMAIL_DEFAULT_HOST de $IMAP_IP a mail.checkin24hs.com" -ForegroundColor White
    Write-Host "   3. Asegúrate de tener configurado:" -ForegroundColor White
    Write-Host "      - ROUNDCUBEMAIL_DEFAULT_PORT=993 (o 143)" -ForegroundColor White
    Write-Host "      - ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true (si usas puerto 993)" -ForegroundColor White
    Write-Host "   4. Reinicia el servicio: docker service update --force $SERVICE_NAME" -ForegroundColor White
    Write-Host ""
}

if (-not $defaultPort) {
    Write-Host "❌ PROBLEMA IDENTIFICADO:" -ForegroundColor Red
    Write-Host "   Falta la configuración del puerto IMAP (ROUNDCUBEMAIL_DEFAULT_PORT)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   SOLUCIÓN:" -ForegroundColor Green
    Write-Host "   1. Ve a EasyPanel → Servicio 'webmail' → Variables de Entorno" -ForegroundColor White
    Write-Host "   2. Agrega ROUNDCUBEMAIL_DEFAULT_PORT=993 (con SSL) o 143 (sin SSL)" -ForegroundColor White
    Write-Host "   3. Si usas puerto 993, también agrega: ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true" -ForegroundColor White
    Write-Host ""
}

if (-not $test993.TcpTestSucceeded -and -not $test993IP.TcpTestSucceeded) {
    Write-Host "❌ PROBLEMA IDENTIFICADO:" -ForegroundColor Red
    Write-Host "   No se puede conectar al servidor IMAP en el puerto 993" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   POSIBLES CAUSAS:" -ForegroundColor Yellow
    Write-Host "   1. No hay un servidor de correo configurado" -ForegroundColor White
    Write-Host "   2. El servidor de correo no está corriendo" -ForegroundColor White
    Write-Host "   3. El firewall está bloqueando el puerto 993" -ForegroundColor White
    Write-Host "   4. El servidor de correo está en otra IP o puerto" -ForegroundColor White
    Write-Host ""
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Verificación completada" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
