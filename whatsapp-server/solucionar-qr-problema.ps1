# 🔧 Script de Solución Rápida para Problemas de QR
# 
# Este script diagnostica y soluciona problemas comunes con el QR de WhatsApp

param(
    [string]$ServerUrl = "http://localhost",
    [int]$Instance = 1
)

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "🔧 DIAGNÓSTICO Y SOLUCIÓN DE PROBLEMAS DE QR - WHATSAPP" -ForegroundColor White
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

# Función para hacer request HTTP
function Invoke-APIRequest {
    param([string]$Url)
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
        return $response
    } catch {
        return $null
    }
}

$port = 3000 + $Instance
$baseUrl = "$ServerUrl`:$port"

Write-Host "📊 DIAGNÓSTICO" -ForegroundColor Yellow
Write-Host ("-" * 70) -ForegroundColor Gray
Write-Host ""

# 1. Verificar estado del servidor
Write-Host "1️⃣  Verificando estado del servidor..." -ForegroundColor Cyan
$status = Invoke-APIRequest "$baseUrl/api/status"
if ($status) {
    Write-Host "   ✅ Servidor respondiendo" -ForegroundColor Green
    Write-Host "   📱 Estado WhatsApp: $($status.whatsapp)" -ForegroundColor $(if ($status.connected) { "Green" } else { "Yellow" })
    Write-Host "   📞 Teléfono: $($status.phone)" -ForegroundColor Cyan
} else {
    Write-Host "   ❌ Servidor no responde en $baseUrl" -ForegroundColor Red
    Write-Host "   💡 Verifica que el servidor esté corriendo" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 2. Verificar QR
Write-Host "2️⃣  Verificando estado del QR..." -ForegroundColor Cyan
$qrData = Invoke-APIRequest "$baseUrl/api/qr"

if ($qrData) {
    if ($qrData.status -eq "expired") {
        Write-Host "   ❌ QR EXPIRADO hace $($qrData.qrAge) minutos" -ForegroundColor Red
        Write-Host "   💡 Este es el problema. Necesitas regenerar el QR." -ForegroundColor Yellow
    } elseif ($qrData.status -eq "waiting_scan") {
        $age = if ($qrData.qrAge) { "$($qrData.qrAge) minutos" } else { "desconocido" }
        $expiresIn = if ($qrData.expiresIn) { "$($qrData.expiresIn) segundos" } else { "desconocido" }
        Write-Host "   ⚠️  QR activo (edad: $age, expira en: $expiresIn)" -ForegroundColor Yellow
        
        if ($qrData.qrAge -gt 5) {
            Write-Host "   ⚠️  Este QR tiene más de 5 minutos. Probablemente expirado." -ForegroundColor Red
        }
    } elseif ($qrData.status -eq "connected") {
        Write-Host "   ✅ WhatsApp está conectado, no se necesita QR" -ForegroundColor Green
        exit 0
    }
} else {
    Write-Host "   ❌ No se pudo obtener información del QR" -ForegroundColor Red
}

Write-Host ""

# 3. Diagnóstico detallado
Write-Host "3️⃣  Diagnóstico detallado..." -ForegroundColor Cyan
$diagnosis = Invoke-APIRequest "$baseUrl/api/diagnose"

if ($diagnosis) {
    Write-Host "   📊 Estado de conexión: $($diagnosis.connectionStatus)" -ForegroundColor Cyan
    Write-Host "   🔌 Socket activo: $(if ($diagnosis.hasSocket) { 'Sí' } else { 'No' })" -ForegroundColor Cyan
    Write-Host "   📱 QR disponible: $(if ($diagnosis.hasQR) { 'Sí' } else { 'No' })" -ForegroundColor Cyan
    
    if ($diagnosis.qr) {
        Write-Host ""
        Write-Host "   📱 Información del QR:" -ForegroundColor Yellow
        Write-Host "      - Edad: $($diagnosis.qr.ageMinutes) minutos" -ForegroundColor Cyan
        Write-Host "      - Expirado: $(if ($diagnosis.qr.isExpired) { 'Sí ❌' } else { 'No ✅' })" -ForegroundColor $(if ($diagnosis.qr.isExpired) { "Red" } else { "Green" })
        
        if ($diagnosis.qr.expiresIn) {
            Write-Host "      - Expira en: $($diagnosis.qr.expiresIn) segundos" -ForegroundColor Cyan
        }
        
        if ($diagnosis.qr.isExpired -or $diagnosis.qr.ageMinutes -gt 5) {
            Write-Host ""
            Write-Host "   ⚠️  PROBLEMA DETECTADO: QR expirado o muy antiguo" -ForegroundColor Red
            Write-Host "   💡 Solución: Regenerar el QR ahora" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "🔧 SOLUCIÓN" -ForegroundColor Yellow
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

# Preguntar si quiere regenerar el QR
$regenerate = Read-Host "¿Quieres regenerar el QR ahora? (S/N)"

if ($regenerate -eq "S" -or $regenerate -eq "s") {
    Write-Host ""
    Write-Host "🔄 Regenerando QR..." -ForegroundColor Cyan
    
    try {
        $regenerateResponse = Invoke-RestMethod -Uri "$baseUrl/api/qr/regenerate" -Method Post -TimeoutSec 10
        Write-Host "   ✅ $($regenerateResponse.message)" -ForegroundColor Green
        Write-Host ""
        Write-Host "⏳ Espera 5-10 segundos y luego:" -ForegroundColor Yellow
        Write-Host "   1. Recarga la página del QR en tu navegador" -ForegroundColor White
        Write-Host "   2. O usa: .\configurar-qr.ps1 -Action qr -Instance $Instance" -ForegroundColor White
        Write-Host ""
        Write-Host "📱 IMPORTANTE: Escanea el NUEVO QR dentro de 2 minutos" -ForegroundColor Yellow
    } catch {
        Write-Host "   ❌ Error regenerando QR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Solución manual:" -ForegroundColor Yellow
        Write-Host "   1. Detén el servidor" -ForegroundColor White
        Write-Host "   2. Elimina la carpeta: auth_info_baileys_$Instance" -ForegroundColor White
        Write-Host "   3. Reinicia el servidor" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "📋 PASOS MANUALES PARA SOLUCIONAR:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opción 1: Regenerar QR desde el servidor" -ForegroundColor Cyan
    Write-Host "   1. Abre: $baseUrl/api/qr/regenerate" -ForegroundColor White
    Write-Host "   2. O usa: POST $baseUrl/api/qr/regenerate" -ForegroundColor White
    Write-Host ""
    Write-Host "Opción 2: Limpiar sesión completamente" -ForegroundColor Cyan
    Write-Host "   1. Ejecuta: .\configurar-qr.ps1 -Action clean -Instance $Instance" -ForegroundColor White
    Write-Host "   2. Reinicia el servidor" -ForegroundColor White
    Write-Host ""
    Write-Host "Opción 3: Reinicio completo" -ForegroundColor Cyan
    Write-Host "   1. Detén el servidor" -ForegroundColor White
    Write-Host "   2. Elimina la carpeta: whatsapp-server\auth_info_baileys_$Instance" -ForegroundColor White
    Write-Host "   3. Reinicia el servidor" -ForegroundColor White
    Write-Host "   4. Espera a que se genere un nuevo QR" -ForegroundColor White
    Write-Host "   5. Escanea el nuevo QR INMEDIATAMENTE (expira en 2 minutos)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
