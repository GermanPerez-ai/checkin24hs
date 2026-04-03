# Script para subir dashboard.html usando plink (PuTTY)
# Requiere tener PuTTY instalado o plink.exe en el PATH

$hostname = "72.61.58.240"
$archivo = "deploy\dashboard.html"
$destino = "/root/checkin24hs/deploy/dashboard.html"

Write-Host "Subiendo archivo usando plink..." -ForegroundColor Yellow
Write-Host "Host: $hostname" -ForegroundColor Gray
Write-Host "Archivo: $archivo" -ForegroundColor Gray
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $archivo)) {
    Write-Host "ERROR: No se encontro el archivo: $archivo" -ForegroundColor Red
    exit 1
}

# Intentar usar plink si está disponible
$plinkPath = "plink.exe"
if (-not (Get-Command $plinkPath -ErrorAction SilentlyContinue)) {
    # Buscar en ubicaciones comunes
    $puttyPaths = @(
        "${env:ProgramFiles}\PuTTY\plink.exe",
        "${env:ProgramFiles(x86)}\PuTTY\plink.exe",
        "$env:LOCALAPPDATA\Programs\PuTTY\plink.exe"
    )
    
    foreach ($path in $puttyPaths) {
        if (Test-Path $path) {
            $plinkPath = $path
            break
        }
    }
}

if (-not (Test-Path $plinkPath)) {
    Write-Host "ERROR: plink.exe no encontrado" -ForegroundColor Red
    Write-Host "Instala PuTTY desde: https://www.putty.org/" -ForegroundColor Yellow
    Write-Host "O usa SCP directamente en PowerShell" -ForegroundColor Yellow
    exit 1
}

Write-Host "Usando: $plinkPath" -ForegroundColor Gray
Write-Host ""

# Usar pscp (PuTTY SCP) si está disponible
$pscpPath = $plinkPath -replace "plink.exe", "pscp.exe"
if (Test-Path $pscpPath) {
    Write-Host "Usando pscp para transferir archivo..." -ForegroundColor Cyan
    & $pscpPath -pw "" $archivo "root@${hostname}:${destino}"
} else {
    Write-Host "pscp.exe no encontrado, usando scp normal..." -ForegroundColor Yellow
    scp $archivo "root@${hostname}:${destino}"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Archivo subido correctamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora conectate al servidor y ejecuta:" -ForegroundColor Cyan
    Write-Host "  ssh root@$hostname" -ForegroundColor White
    Write-Host "  cd /root/checkin24hs" -ForegroundColor White
    Write-Host "  python3 ACTUALIZAR_DASHBOARD_SERVIDOR.py" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    Write-Host "Intenta ejecutar SCP manualmente en PowerShell" -ForegroundColor Yellow
}



