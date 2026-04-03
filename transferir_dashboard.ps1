# Script para transferir dashboard.html al servidor
$serverIP = "72.61.58.240"
$serverUser = "root"
$localFile = "deploy\dashboard.html"
$remotePath = "/root/checkin24hs/deploy/dashboard.html"

Write-Host "Transferiendo dashboard.html al servidor..." -ForegroundColor Cyan

# Verificar que el archivo local existe
if (-not (Test-Path $localFile)) {
    Write-Host "Error: No se encontro el archivo local $localFile" -ForegroundColor Red
    exit 1
}

# Mostrar tamaño del archivo
$fileSize = (Get-Item $localFile).Length
$htmlCount = (Get-Content $localFile -Raw | Select-String -Pattern '<html' -AllMatches).Matches.Count

Write-Host "Archivo local encontrado:" -ForegroundColor Green
Write-Host "  - Tamaño: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor White
Write-Host "  - Tags <html>: $htmlCount" -ForegroundColor White
Write-Host ""

if ($htmlCount -ne 1) {
    Write-Host "ADVERTENCIA: El archivo local tiene $htmlCount tags <html> (deberia ser 1)" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Iniciando transferencia..." -ForegroundColor Yellow
Write-Host "NOTA: Si te pide contrasena, ingresala ahora." -ForegroundColor Cyan
Write-Host ""

scp -o StrictHostKeyChecking=no "$localFile" "${serverUser}@${serverIP}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Archivo transferido correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Conectarse al servidor: ssh ${serverUser}@${serverIP}" -ForegroundColor White
    Write-Host "2. Verificar el archivo: head -5 /root/checkin24hs/deploy/dashboard.html" -ForegroundColor White
    Write-Host "3. Verificar tags HTML: grep -c '<html' /root/checkin24hs/deploy/dashboard.html" -ForegroundColor White
    Write-Host "4. Si muestra 1, el archivo esta correcto" -ForegroundColor White
    Write-Host "5. Copiar a contenedores Docker si es necesario" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Error durante la transferencia (codigo: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternativas:" -ForegroundColor Yellow
    Write-Host "1. Usar WinSCP (interfaz grafica)" -ForegroundColor White
    Write-Host "2. Ejecutar manualmente: scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html" -ForegroundColor White
    Write-Host "3. Verificar que tengas acceso SSH configurado" -ForegroundColor White
}


