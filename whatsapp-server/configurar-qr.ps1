# 🔧 Script de Configuración de QR para WhatsApp (PowerShell)
# 
# Este script te permite configurar y gestionar el código QR de WhatsApp
# de manera fácil desde PowerShell en Windows.

param(
    [string]$ServerUrl = "http://localhost",
    [int]$Instance = 1,
    [string]$Action = "menu"
)

# Colores para la terminal
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Green { param([string]$text) Write-ColorOutput Green $text }
function Write-Red { param([string]$text) Write-ColorOutput Red $text }
function Write-Yellow { param([string]$text) Write-ColorOutput Yellow $text }
function Write-Cyan { param([string]$text) Write-ColorOutput Cyan $text }

# Cargar configuración
$ConfigFile = Join-Path $PSScriptRoot ".qr-config.json"
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        if ($config.serverUrl) {
            $ServerUrl = $config.serverUrl
        }
    } catch {
        Write-Yellow "⚠️  Error leyendo configuración, usando valores por defecto"
    }
}

# Función para obtener estado
function Get-QRStatus {
    param([string]$Url, [int]$Inst = 1)
    
    $port = 3000 + $Inst
    $apiUrl = "$Url`:$port/api/status"
    
    Write-Cyan "🔍 Verificando estado en $apiUrl..."
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 5
        return $response
    } catch {
        Write-Red "❌ Error obteniendo estado: $($_.Exception.Message)"
        return $null
    }
}

# Función para obtener QR
function Get-QRCode {
    param([string]$Url, [int]$Inst = 1)
    
    $port = 3000 + $Inst
    $apiUrl = "$Url`:$port/api/qr"
    
    Write-Cyan "📱 Obteniendo QR desde $apiUrl..."
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 5
        return $response
    } catch {
        Write-Red "❌ Error obteniendo QR: $($_.Exception.Message)"
        return $null
    }
}

# Función para guardar QR como imagen
function Save-QRImage {
    param([object]$QRData, [string]$FileName = "qr-code.png")
    
    if (-not $QRData.qrImage -and -not $QRData.qr) {
        Write-Red "❌ No hay datos de QR para guardar"
        return $false
    }
    
    try {
        if ($QRData.qrImage -and $QRData.qrImage.StartsWith("data:image")) {
            # Es una imagen base64
            $base64Data = $QRData.qrImage -replace '^data:image/\w+;base64,', ''
            $bytes = [Convert]::FromBase64String($base64Data)
            [System.IO.File]::WriteAllBytes($FileName, $bytes)
            return $true
        }
        
        if ($QRData.qr) {
            # Usar API externa
            $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=512x512&data=" + [System.Web.HttpUtility]::UrlEncode($QRData.qr)
            Invoke-WebRequest -Uri $qrUrl -OutFile $FileName
            return $true
        }
        
        return $false
    } catch {
        Write-Red "❌ Error guardando QR: $($_.Exception.Message)"
        return $false
    }
}

# Mostrar menú
function Show-Menu {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "🔧 CONFIGURACIÓN DE QR - WHATSAPP CHECKIN24HS" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ver estado de conexión"
    Write-Host "2. Obtener código QR"
    Write-Host "3. Guardar QR como imagen"
    Write-Host "4. Verificar todas las instancias (1-4)"
    Write-Host "5. Limpiar sesión y generar nuevo QR"
    Write-Host "6. Configurar URL del servidor"
    Write-Host "0. Salir"
    Write-Host ""
}

# Menú principal
function Show-MainMenu {
    Write-Host "📱 Configurador de QR para WhatsApp" -ForegroundColor White
    Write-Cyan "🌐 URL del servidor: $ServerUrl"
    
    while ($true) {
        Show-Menu
        $opcion = Read-Host "Selecciona una opción"
        
        switch ($opcion.Trim()) {
            "1" { Invoke-ViewStatus }
            "2" { Invoke-ViewQR }
            "3" { Invoke-SaveQR }
            "4" { Invoke-CheckAllInstances }
            "5" { Invoke-CleanSession }
            "6" { $script:ServerUrl = Invoke-ConfigureServer }
            "0" {
                Write-Green "`n👋 ¡Hasta luego!"
                exit 0
            }
            default {
                Write-Red "`n❌ Opción inválida"
            }
        }
        
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
    }
}

# Ver estado
function Invoke-ViewStatus {
    $inst = Read-Host "`n📱 Número de instancia (1-4, Enter para 1)"
    if ([string]::IsNullOrWhiteSpace($inst)) { $inst = "1" }
    $numInst = [int]$inst
    
    if ($numInst -lt 1 -or $numInst -gt 4) {
        Write-Red "❌ Instancia debe estar entre 1 y 4"
        return
    }
    
    $estado = Get-QRStatus -Url $ServerUrl -Inst $numInst
    
    if (-not $estado) {
        Write-Red "❌ No se pudo obtener el estado del servidor"
        return
    }
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "📊 ESTADO INSTANCIA $numInst" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    if ($estado.connected) {
        Write-Green "`n🔌 Conexión: ✅ Conectado"
    } else {
        Write-Red "`n🔌 Conexión: ❌ Desconectado"
    }
    
    Write-Host "📱 WhatsApp: $($estado.whatsapp)" -ForegroundColor $(if ($estado.whatsapp -eq "connected") { "Green" } else { "Yellow" })
    Write-Cyan "🤖 Flor IA: $($estado.flor)"
    Write-Cyan "🔄 Auto-respuesta: $(if ($estado.autoReply) { "Activada" } else { "Desactivada" })"
    
    if ($estado.phone) {
        Write-Green "`n📞 Teléfono: $($estado.phone)"
        Write-Green "👤 Nombre: $($estado.name)"
    }
    
    if ($estado.qrCode) {
        Write-Yellow "`n📱 QR Code: Disponible"
        Write-Cyan "🔗 URL: $($estado.qrCode.Substring(0, [Math]::Min(80, $estado.qrCode.Length)))..."
    } else {
        Write-Yellow "`n📱 QR Code: $(if ($estado.connected) { "No necesario (conectado)" } else { "No disponible" })"
    }
}

# Ver QR
function Invoke-ViewQR {
    $inst = Read-Host "`n📱 Número de instancia (1-4, Enter para 1)"
    if ([string]::IsNullOrWhiteSpace($inst)) { $inst = "1" }
    $numInst = [int]$inst
    
    if ($numInst -lt 1 -or $numInst -gt 4) {
        Write-Red "❌ Instancia debe estar entre 1 y 4"
        return
    }
    
    $qrData = Get-QRCode -Url $ServerUrl -Inst $numInst
    
    if (-not $qrData) {
        Write-Red "❌ No se pudo obtener el QR del servidor"
        return
    }
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "📱 CÓDIGO QR - INSTANCIA $numInst" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    Write-Host "`n📊 Estado: $($qrData.status)" -ForegroundColor $(if ($qrData.status -eq "waiting_scan") { "Yellow" } else { "Green" })
    
    if ($qrData.qr) {
        Write-Cyan "`n📱 Código QR (primeros 50 caracteres):"
        Write-Yellow "$($qrData.qr.Substring(0, [Math]::Min(50, $qrData.qr.Length)))..."
        
        if ($qrData.qrImage) {
            Write-Green "`n✅ Imagen QR generada (base64)"
        }
        
        $qrUrl = if ($qrData.qrImage) { $qrData.qrImage } else { "https://api.qrserver.com/v1/create-qr-code/?size=512x512&data=" + [System.Web.HttpUtility]::UrlEncode($qrData.qr) }
        
        Write-Cyan "`n🔗 URL del QR:"
        Write-Yellow "$($qrUrl.Substring(0, [Math]::Min(100, $qrUrl.Length)))..."
        
        Write-Cyan "`n💡 Puedes abrir esta URL en tu navegador para ver el QR"
        Write-Cyan "   O usar la opción 3 para guardarlo como imagen"
    } else {
        Write-Red "`n❌ No hay QR disponible"
        if ($qrData.status -eq "connected") {
            Write-Yellow "   WhatsApp ya está conectado, no se necesita QR"
        } else {
            Write-Yellow "   El servidor puede estar inicializando..."
        }
    }
}

# Guardar QR
function Invoke-SaveQR {
    $inst = Read-Host "`n📱 Número de instancia (1-4, Enter para 1)"
    if ([string]::IsNullOrWhiteSpace($inst)) { $inst = "1" }
    $numInst = [int]$inst
    
    if ($numInst -lt 1 -or $numInst -gt 4) {
        Write-Red "❌ Instancia debe estar entre 1 y 4"
        return
    }
    
    $filename = Read-Host "`n💾 Nombre del archivo (Enter para qr-$numInst.png"
    if ([string]::IsNullOrWhiteSpace($filename)) { $filename = "qr-$numInst.png" }
    
    Write-Cyan "`n📥 Descargando QR..."
    
    $qrData = Get-QRCode -Url $ServerUrl -Inst $numInst
    
    if (-not $qrData -or -not $qrData.qr) {
        Write-Red "❌ No se pudo obtener el QR del servidor"
        return
    }
    
    if (Save-QRImage -QRData $qrData -FileName $filename) {
        Write-Green "`n✅ QR guardado exitosamente en: $filename"
        Write-Cyan "`n📱 Puedes abrir este archivo con cualquier visor de imágenes"
        Write-Cyan "   Y escanearlo con WhatsApp desde tu teléfono"
    }
}

# Verificar todas las instancias
function Invoke-CheckAllInstances {
    Write-Cyan "`n🔍 Verificando todas las instancias..."
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    for ($i = 1; $i -le 4; $i++) {
        Write-Host "`n📱 Instancia $i:" -ForegroundColor White
        $estado = Get-QRStatus -Url $ServerUrl -Inst $i
        
        if (-not $estado) {
            Write-Red "   ❌ Servidor no disponible en puerto $($3000 + $i)"
            continue
        }
        
        $status = if ($estado.connected) { "✅ Conectado" } else { "⏳ Esperando QR" }
        $color = if ($estado.connected) { "Green" } else { "Yellow" }
        Write-Host "   $status" -ForegroundColor $color
        
        if ($estado.phone) {
            Write-Cyan "   📞 $($estado.phone) ($($estado.name))"
        }
        
        if ($estado.qrCode -and -not $estado.connected) {
            Write-Yellow "   📱 QR disponible"
        }
    }
}

# Limpiar sesión
function Invoke-CleanSession {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Yellow
    Write-Host "⚠️  LIMPIAR SESIÓN" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow
    
    $inst = Read-Host "`n📱 Número de instancia (1-4, Enter para 1)"
    if ([string]::IsNullOrWhiteSpace($inst)) { $inst = "1" }
    $numInst = [int]$inst
    
    if ($numInst -lt 1 -or $numInst -gt 4) {
        Write-Red "❌ Instancia debe estar entre 1 y 4"
        return
    }
    
    $confirmacion = Read-Host "`n⚠️  ¿Estás seguro de limpiar la sesión $numInst? (s/N)"
    
    if ($confirmacion.ToLower() -ne "s") {
        Write-Yellow "❌ Operación cancelada"
        return
    }
    
    $authDir = Join-Path $PSScriptRoot "auth_info_baileys_$numInst"
    
    if (-not (Test-Path $authDir)) {
        Write-Yellow "`n⚠️  No existe sesión para limpiar en instancia $numInst"
        return
    }
    
    try {
        Remove-Item -Path $authDir -Recurse -Force
        Write-Green "`n✅ Sesión limpiada exitosamente"
        Write-Cyan "`n📱 Reinicia el servidor para generar un nuevo QR"
    } catch {
        Write-Red "`n❌ Error limpiando sesión: $($_.Exception.Message)"
    }
}

# Configurar servidor
function Invoke-ConfigureServer {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "⚙️  CONFIGURAR URL DEL SERVIDOR" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Yellow "`nURL actual: $ServerUrl"
    
    $newUrl = Read-Host "`nIngresa la nueva URL del servidor (Enter para mantener actual)"
    
    if ([string]::IsNullOrWhiteSpace($newUrl)) {
        Write-Green "✅ URL no cambiada"
        return $ServerUrl
    }
    
    $finalUrl = $newUrl.Trim()
    
    # Asegurar que tenga protocolo
    if (-not $finalUrl.StartsWith("http://") -and -not $finalUrl.StartsWith("https://")) {
        $finalUrl = "http://$finalUrl"
    }
    
    # Remover barra final
    $finalUrl = $finalUrl.TrimEnd("/")
    
    try {
        $config = @{ serverUrl = $finalUrl } | ConvertTo-Json
        Set-Content -Path $ConfigFile -Value $config
        
        Write-Green "`n✅ URL guardada: $finalUrl"
        return $finalUrl
    } catch {
        Write-Red "`n❌ Error guardando configuración: $($_.Exception.Message)"
        return $ServerUrl
    }
}

# Ejecutar según acción
switch ($Action.ToLower()) {
    "status" { Invoke-ViewStatus }
    "qr" { Invoke-ViewQR }
    "save" { Invoke-SaveQR }
    "check" { Invoke-CheckAllInstances }
    "clean" { Invoke-CleanSession }
    "menu" { Show-MainMenu }
    default { Show-MainMenu }
}
