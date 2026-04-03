# Script completo para verificar todas las conexiones de WhatsApp
# Ejecuta todas las verificaciones posibles desde Windows

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACION COMPLETA DE WHATSAPP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$servidor = "72.61.58.240"
$puertos3000 = @(3001, 3002, 3003, 3004)
$puertos4000 = @(4001, 4002, 4003, 4004)
$conexionesActivas = 0
$conexionesDesconectadas = 0

# Funcion para verificar estado
function Verificar-WhatsApp {
    param(
        [int]$numero,
        [int]$puerto
    )
    
    $url = "http://$servidor`:$puerto/api/status"
    
    Write-Host "WhatsApp $numero (Puerto $puerto):" -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5 -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.connected -eq $true) {
            Write-Host "   Estado: CONECTADO" -ForegroundColor Green
            Write-Host "   Telefono: $($data.phoneNumber)" -ForegroundColor White
            Write-Host "   Usuario: $($data.userName)" -ForegroundColor White
            Write-Host "   Flor IA: $($data.flor)" -ForegroundColor White
            Write-Host "   Auto-respuesta: $($data.autoReply)" -ForegroundColor White
            Write-Host "   Ultima actividad: $($data.lastActivity)" -ForegroundColor Gray
            $script:conexionesActivas++
            return $true
        } elseif ($data.qrCode) {
            Write-Host "   Estado: ESPERANDO QR" -ForegroundColor Yellow
            Write-Host "   Codigo QR disponible para escanear" -ForegroundColor White
            $script:conexionesDesconectadas++
            return $false
        } else {
            Write-Host "   Estado: DESCONECTADO" -ForegroundColor Red
            Write-Host "   WhatsApp: $($data.whatsapp)" -ForegroundColor White
            $script:conexionesDesconectadas++
            return $false
        }
    } catch {
        Write-Host "   Estado: NO RESPONDE" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        $script:conexionesDesconectadas++
        return $false
    }
}

# 1. Verificar puertos 3001-3004
Write-Host "=== 1. VERIFICANDO PUERTOS 3001-3004 ===" -ForegroundColor Cyan
Write-Host ""
foreach ($i in 0..3) {
    $numero = $i + 1
    $puerto = $puertos3000[$i]
    Verificar-WhatsApp -numero $numero -puerto $puerto
    Write-Host ""
}

# 2. Verificar puertos 4001-4004 (configuracion PM2)
Write-Host "=== 2. VERIFICANDO PUERTOS 4001-4004 (PM2) ===" -ForegroundColor Cyan
Write-Host ""
foreach ($i in 0..3) {
    $numero = $i + 1
    $puerto = $puertos4000[$i]
    Verificar-WhatsApp -numero $numero -puerto $puerto
    Write-Host ""
}

# 3. Resumen
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Conexiones activas: $conexionesActivas" -ForegroundColor Green
Write-Host "Conexiones desconectadas/no disponibles: $conexionesDesconectadas" -ForegroundColor Red
Write-Host "Total verificado: 8 instancias (puertos 3001-3004 y 4001-4004)" -ForegroundColor White
Write-Host ""

# 4. Comandos para ejecutar en el servidor
Write-Host "=== COMANDOS PARA EJECUTAR EN EL SERVIDOR ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para verificar procesos PM2:" -ForegroundColor Yellow
Write-Host "  ssh root@$servidor 'pm2 list'" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar puertos activos:" -ForegroundColor Yellow
$comandoPuertos = "ssh root@$servidor 'netstat -tulpn | grep -E `"3001|3002|3003|3004|4001|4002|4003|4004`"'"
Write-Host "  $comandoPuertos" -ForegroundColor White
Write-Host ""
Write-Host "Para ver logs de una instancia:" -ForegroundColor Yellow
Write-Host "  ssh root@$servidor 'pm2 logs whatsapp-1 --lines 20 --nostream'" -ForegroundColor White
Write-Host ""
Write-Host "Para ejecutar script completo en servidor:" -ForegroundColor Yellow
Write-Host "  ssh root@$servidor 'bash /root/checkin24hs/EJECUTAR_TODAS_VERIFICACIONES.sh'" -ForegroundColor White
Write-Host ""

