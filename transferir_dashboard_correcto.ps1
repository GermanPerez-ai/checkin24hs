# Script para transferir el archivo dashboard.html correcto al servidor
# Usar IP directa para evitar problemas de resolución DNS

$serverIP = "72.61.58.240"
$serverUser = "root"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"

Write-Host "📤 Transferiendo dashboard.html al servidor..." -ForegroundColor Cyan

# Verificar que el archivo local existe
if (-not (Test-Path $localFile)) {
    Write-Host "❌ Error: No se encontró el archivo local $localFile" -ForegroundColor Red
    exit 1
}

# Mostrar tamaño del archivo
$fileSize = (Get-Item $localFile).Length
Write-Host "📊 Tamaño del archivo: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Yellow

# Transferir usando SCP
Write-Host "🔄 Iniciando transferencia..." -ForegroundColor Yellow

scp -o StrictHostKeyChecking=no "$localFile" "${serverUser}@${serverIP}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo transferido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Conectarse al servidor: ssh ${serverUser}@${serverIP}"
    Write-Host "2. Verificar el archivo: head -5 /root/checkin24hs/deploy/dashboard.html"
    Write-Host "3. Verificar que solo tiene 1 tag <html>: grep -c '<html' /root/checkin24hs/deploy/dashboard.html"
    Write-Host "4. Reiniciar el contenedor Docker si es necesario"
} else {
    Write-Host "❌ Error durante la transferencia (código: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "💡 Verifica que tengas acceso SSH configurado" -ForegroundColor Yellow
}

