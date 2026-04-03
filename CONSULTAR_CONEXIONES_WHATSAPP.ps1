# Script para consultar conexiones activas de WhatsApp
# Verifica el estado de todas las instancias de WhatsApp (1-4)

Write-Host ""
Write-Host "=== CONSULTANDO CONEXIONES ACTIVAS DE WHATSAPP ===" -ForegroundColor Cyan
Write-Host ""

# Configuracion
$servidor = "72.61.58.240"
$puertos = @(3001, 3002, 3003, 3004)
$conexionesActivas = 0
$conexionesDesconectadas = 0

# Funcion para verificar estado de una instancia
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
        } elseif ($data.qrCode) {
            Write-Host "   Estado: ESPERANDO QR" -ForegroundColor Yellow
            Write-Host "   Codigo QR disponible para escanear" -ForegroundColor White
            $script:conexionesDesconectadas++
        } else {
            Write-Host "   Estado: DESCONECTADO" -ForegroundColor Red
            Write-Host "   WhatsApp: $($data.whatsapp)" -ForegroundColor White
            $script:conexionesDesconectadas++
        }
    } catch {
        Write-Host "   Estado: NO RESPONDE" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        $script:conexionesDesconectadas++
    }
    
    Write-Host ""
}

# Verificar cada instancia
foreach ($i in 0..3) {
    $numero = $i + 1
    $puerto = $puertos[$i]
    Verificar-WhatsApp -numero $numero -puerto $puerto
}

# Resumen
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Conexiones activas: $conexionesActivas" -ForegroundColor Green
Write-Host "Conexiones desconectadas/no disponibles: $conexionesDesconectadas" -ForegroundColor Red
Write-Host "Total de instancias: 4" -ForegroundColor White
Write-Host ""

# Verificar tambien con PM2 si esta disponible
Write-Host "=== VERIFICANDO PROCESOS PM2 (si esta disponible) ===" -ForegroundColor Cyan
Write-Host "Para verificar procesos PM2, ejecuta en el servidor:" -ForegroundColor Yellow
$comandoPM2 = "ssh root@$servidor pm2 list"
Write-Host "  $comandoPM2" -ForegroundColor White
Write-Host ""

# Opcion para verificar puertos directamente
Write-Host "=== VERIFICAR PUERTOS EN EL SERVIDOR ===" -ForegroundColor Cyan
Write-Host "Para verificar puertos directamente, ejecuta:" -ForegroundColor Yellow
$comandoPuertos = "ssh root@$servidor bash /root/checkin24hs/verificar_whatsapp.sh"
Write-Host "  $comandoPuertos" -ForegroundColor White
Write-Host ""
