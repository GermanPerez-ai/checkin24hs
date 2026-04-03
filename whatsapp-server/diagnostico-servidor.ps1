# 🔍 Script de Diagnóstico del Servidor WhatsApp
# 
# Este script verifica si el servidor está corriendo y accesible

param(
    [string]$ServerUrl = "http://api1.checkin24hs.com",
    [int]$Instance = 1,
    [int]$Port = 0
)

if ($Port -eq 0) {
    $Port = 3000 + $Instance
}

$fullUrl = "$ServerUrl`:$Port"

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "🔍 DIAGNÓSTICO DEL SERVIDOR WHATSAPP" -ForegroundColor White
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "📡 URL: $fullUrl" -ForegroundColor Yellow
Write-Host "📱 Instancia: $Instance" -ForegroundColor Yellow
Write-Host "🔌 Puerto: $Port" -ForegroundColor Yellow
Write-Host ""

# Función para hacer request HTTP
function Test-ServerConnection {
    param(
        [string]$Url,
        [int]$Timeout = 5
    )
    
    try {
        Write-Host "🔍 Probando conexión a $Url..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec $Timeout -UseBasicParsing
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            Content = $response.Content
        }
    } catch {
        $errorMessage = $_.Exception.Message
        
        # Determinar tipo de error
        if ($errorMessage -like "*timeout*" -or $errorMessage -like "*timed out*") {
            $errorType = "TIMEOUT"
        } elseif ($errorMessage -like "*refused*" -or $errorMessage -like "*connection refused*") {
            $errorType = "CONNECTION_REFUSED"
        } elseif ($errorMessage -like "*not found*" -or $errorMessage -like "*404*") {
            $errorType = "NOT_FOUND"
        } elseif ($errorMessage -like "*could not resolve*" -or $errorMessage -like "*DNS*") {
            $errorType = "DNS_ERROR"
        } else {
            $errorType = "UNKNOWN"
        }
        
        return @{
            Success = $false
            ErrorType = $errorType
            ErrorMessage = $errorMessage
        }
    }
}

# 1. Verificar si el servidor responde
Write-Host "1️⃣  Verificando si el servidor está accesible..." -ForegroundColor Yellow
Write-Host ("-" * 70) -ForegroundColor Gray

$healthCheck = Test-ServerConnection "$fullUrl/api/health"
if (-not $healthCheck.Success) {
    Write-Host "   ❌ El servidor NO está accesible" -ForegroundColor Red
    Write-Host "   Error: $($healthCheck.ErrorType)" -ForegroundColor Red
    Write-Host "   Detalles: $($healthCheck.ErrorMessage)" -ForegroundColor Red
    Write-Host ""
    
    # Diagnóstico específico según el tipo de error
    switch ($healthCheck.ErrorType) {
        "TIMEOUT" {
            Write-Host "   💡 El servidor no responde. Posibles causas:" -ForegroundColor Yellow
            Write-Host "      - El servicio no está corriendo" -ForegroundColor White
            Write-Host "      - El puerto $Port no está abierto en el firewall" -ForegroundColor White
            Write-Host "      - El servicio está en un contenedor Docker que no expone el puerto" -ForegroundColor White
            Write-Host "      - El servicio está escuchando solo en localhost (127.0.0.1)" -ForegroundColor White
        }
        "CONNECTION_REFUSED" {
            Write-Host "   💡 La conexión fue rechazada. Posibles causas:" -ForegroundColor Yellow
            Write-Host "      - No hay ningún servicio escuchando en el puerto $Port" -ForegroundColor White
            Write-Host "      - El servicio está detenido" -ForegroundColor White
            Write-Host "      - El puerto está bloqueado por un firewall" -ForegroundColor White
        }
        "DNS_ERROR" {
            Write-Host "   💡 Error de DNS. Posibles causas:" -ForegroundColor Yellow
            Write-Host "      - El dominio $ServerUrl no existe o no está configurado" -ForegroundColor White
            Write-Host "      - Problemas de resolución DNS" -ForegroundColor White
        }
        default {
            Write-Host "   💡 Error desconocido. Verifica:" -ForegroundColor Yellow
            Write-Host "      - Que el servidor esté corriendo" -ForegroundColor White
            Write-Host "      - Que el puerto $Port esté abierto" -ForegroundColor White
            Write-Host "      - Que la URL sea correcta" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "2️⃣  SOLUCIONES SUGERIDAS" -ForegroundColor Yellow
    Write-Host ("-" * 70) -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "   A. Verificar en EasyPanel:" -ForegroundColor Cyan
    Write-Host "      1. Ve a EasyPanel (http://TU_IP:3000)" -ForegroundColor White
    Write-Host "      2. Busca el servicio 'whatsapp$Instance' o 'checkin24hs_whatsapp$Instance'" -ForegroundColor White
    Write-Host "      3. Verifica que esté en estado 'Running' (verde)" -ForegroundColor White
    Write-Host "      4. Si está detenido, haz clic en 'Start' o 'Iniciar'" -ForegroundColor White
    Write-Host ""
    
    Write-Host "   B. Verificar puerto en EasyPanel:" -ForegroundColor Cyan
    Write-Host "      1. Ve al servicio en EasyPanel" -ForegroundColor White
    Write-Host "      2. Ve a la sección 'Resources' o 'Recursos'" -ForegroundColor White
    Write-Host "      3. Verifica que el puerto esté configurado como: $Port" -ForegroundColor White
    Write-Host "      4. Si no, cámbialo y reinicia el servicio" -ForegroundColor White
    Write-Host ""
    
    Write-Host "   C. Verificar variables de entorno:" -ForegroundColor Cyan
    Write-Host "      1. En EasyPanel, ve a 'Environment' o 'Variables de Entorno'" -ForegroundColor White
    Write-Host "      2. Verifica que exista: PORT=$Port" -ForegroundColor White
    Write-Host "      3. Verifica que exista: INSTANCE_NUMBER=$Instance" -ForegroundColor White
    Write-Host "      4. Si faltan, agréguelas y reinicia" -ForegroundColor White
    Write-Host ""
    
    Write-Host "   D. Verificar logs del servicio:" -ForegroundColor Cyan
    Write-Host "      1. En EasyPanel, ve a la pestaña 'Logs'" -ForegroundColor White
    Write-Host "      2. Busca errores o mensajes como:" -ForegroundColor White
    Write-Host "         - 'Servidor iniciado en puerto $Port'" -ForegroundColor Gray
    Write-Host "         - 'Error iniciando servidor'" -ForegroundColor Gray
    Write-Host "         - 'Puerto ya en uso'" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "   E. Si estás usando Docker directamente:" -ForegroundColor Cyan
    Write-Host "      1. Verifica que el contenedor esté corriendo:" -ForegroundColor White
    Write-Host "         docker ps | grep whatsapp" -ForegroundColor Gray
    Write-Host "      2. Verifica que el puerto esté mapeado:" -ForegroundColor White
    Write-Host "         docker port CONTAINER_ID" -ForegroundColor Gray
    Write-Host "      3. Verifica logs del contenedor:" -ForegroundColor White
    Write-Host "         docker logs CONTAINER_ID" -ForegroundColor Gray
    Write-Host ""
    
    exit 1
} else {
    Write-Host "   ✅ El servidor ESTÁ accesible" -ForegroundColor Green
    Write-Host "   Status Code: $($healthCheck.StatusCode)" -ForegroundColor Green
}

Write-Host ""

# 2. Verificar endpoint de estado
Write-Host "2️⃣  Verificando endpoint /api/status..." -ForegroundColor Yellow
Write-Host ("-" * 70) -ForegroundColor Gray

$statusCheck = Test-ServerConnection "$fullUrl/api/status"
if ($statusCheck.Success) {
    try {
        $statusData = $statusCheck.Content | ConvertFrom-Json
        Write-Host "   ✅ Endpoint funcionando" -ForegroundColor Green
        Write-Host "   📱 Estado WhatsApp: $($statusData.whatsapp)" -ForegroundColor Cyan
        Write-Host "   🔌 Conexión: $(if ($statusData.connected) { 'Conectado ✅' } else { 'Desconectado ❌' })" -ForegroundColor $(if ($statusData.connected) { "Green" } else { "Yellow" })
        if ($statusData.phone) {
            Write-Host "   📞 Teléfono: $($statusData.phone)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "   ⚠️  Endpoint responde pero con formato incorrecto" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Endpoint /api/status no disponible" -ForegroundColor Red
}

Write-Host ""

# 3. Verificar endpoint de QR
Write-Host "3️⃣  Verificando endpoint /api/qr..." -ForegroundColor Yellow
Write-Host ("-" * 70) -ForegroundColor Gray

$qrCheck = Test-ServerConnection "$fullUrl/api/qr"
if ($qrCheck.Success) {
    try {
        $qrData = $qrCheck.Content | ConvertFrom-Json
        Write-Host "   ✅ Endpoint funcionando" -ForegroundColor Green
        Write-Host "   📊 Estado QR: $($qrData.status)" -ForegroundColor Cyan
        if ($qrData.status -eq "waiting_scan") {
            Write-Host "   📱 QR disponible para escanear" -ForegroundColor Green
        } elseif ($qrData.status -eq "expired") {
            Write-Host "   ⚠️  QR expirado" -ForegroundColor Yellow
        } elseif ($qrData.status -eq "connected") {
            Write-Host "   ✅ WhatsApp conectado" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️  Endpoint responde pero con formato incorrecto" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Endpoint /api/qr no disponible" -ForegroundColor Red
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "✅ DIAGNÓSTICO COMPLETADO" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

if ($healthCheck.Success) {
    Write-Host "💡 El servidor está funcionando. Puedes acceder a:" -ForegroundColor Green
    Write-Host "   - Panel Web: $fullUrl" -ForegroundColor Cyan
    Write-Host "   - Estado: $fullUrl/api/status" -ForegroundColor Cyan
    Write-Host "   - QR: $fullUrl/api/qr" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Si aún tienes problemas, verifica:" -ForegroundColor Yellow
    Write-Host "   1. Que el QR no esté expirado (más de 2 minutos)" -ForegroundColor White
    Write-Host "   2. Que la sesión no esté corrupta" -ForegroundColor White
    Write-Host "   3. Los logs del servidor para errores específicos" -ForegroundColor White
} else {
    Write-Host "⚠️  El servidor no está accesible. Sigue las soluciones sugeridas arriba." -ForegroundColor Yellow
}

Write-Host ""
