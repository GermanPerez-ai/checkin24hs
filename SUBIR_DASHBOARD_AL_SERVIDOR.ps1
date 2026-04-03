# Subir dashboard actualizado al servidor (scp + ssh desde tu PC)
# Necesitas clave SSH para el host que uses en -Server.
# Si actualizas solo por SSH (sin subir desde PC): ve ACTUALIZAR_DASHBOARD_SOLO_SSH.md

param(
    [string]$Server = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

# Servidor: 72.61.58.240. Override: -Server o $env:DASHBOARD_SERVER
if (-not $Server) {
    $Server = $env:DASHBOARD_SERVER
    if (-not $Server) { $Server = "root@72.61.58.240" }
}
$rutaServidor = "/root/checkin24hs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Subir dashboard al servidor (scp)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Servidor: $Server" -ForegroundColor Gray
Write-Host "  (usa -Server usuario@host si conectas a otro)" -ForegroundColor DarkGray
Write-Host ""

$dashboardPath = Join-Path $projectRoot "dashboard.html"
if (-not (Test-Path $dashboardPath)) {
    Write-Host "No se encuentra dashboard.html en: $projectRoot" -ForegroundColor Red
    exit 1
}

$build = (Select-String -Path $dashboardPath -Pattern "DASHBOARD_BUILD_NUMBER = (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) | Select-Object -First 1
Write-Host "Dashboard local - Build #$build" -ForegroundColor Gray
Write-Host ""

# 1. Crear directorio en servidor (comprobar conexión)
Write-Host "1. Comprobando conexión y creando directorio..." -ForegroundColor Yellow
$null = ssh -o ConnectTimeout=8 $Server "mkdir -p $rutaServidor" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Error: no se pudo conectar por SSH." -ForegroundColor Red
    Write-Host ""
    Write-Host "   Usa -Server con el host donde SÍ tienes clave SSH, por ejemplo:" -ForegroundColor Yellow
    Write-Host "   .\SUBIR_DASHBOARD_AL_SERVIDOR.ps1 -Server root@TU_HOST" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Si solo actualizas por SSH (sin subir desde PC), ve:" -ForegroundColor Yellow
    Write-Host "   ACTUALIZAR_DASHBOARD_SOLO_SSH.md" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
Write-Host "   OK" -ForegroundColor Green
Write-Host ""

# 2. Subir dashboard.html
Write-Host "2. Subiendo dashboard.html..." -ForegroundColor Yellow
scp $dashboardPath "${Server}:${rutaServidor}/dashboard.html"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Error al subir dashboard.html" -ForegroundColor Red
    exit 1
}
Write-Host "   OK" -ForegroundColor Green
Write-Host ""

# 3. Subir supabase-client.js si existe
$supabasePath = Join-Path $projectRoot "supabase-client.js"
if (Test-Path $supabasePath) {
    Write-Host "3. Subiendo supabase-client.js..." -ForegroundColor Yellow
    scp $supabasePath "${Server}:${rutaServidor}/supabase-client.js" 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "   OK" -ForegroundColor Green } else { Write-Host "   (omitido)" -ForegroundColor Gray }
} else {
    Write-Host "3. supabase-client.js no encontrado (omitido)" -ForegroundColor Gray
}
Write-Host ""

# 4. Subir script de actualización si existe
$scriptPath = Join-Path $projectRoot "ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh"
if (Test-Path $scriptPath) {
    Write-Host "4. Subiendo ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh..." -ForegroundColor Yellow
    scp $scriptPath "${Server}:${rutaServidor}/" 2>$null
    ssh $Server "chmod +x ${rutaServidor}/ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh" 2>$null
    Write-Host "   OK" -ForegroundColor Green
} else {
    Write-Host "4. ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh no encontrado" -ForegroundColor Gray
}
Write-Host ""

# 5. Ejecutar actualización en servidor
Write-Host "5. Aplicando cambios y reiniciando servicio..." -ForegroundColor Yellow
ssh $Server "cd $rutaServidor && (test -f ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh && chmod +x ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh && ./ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh) || (docker service update --force checkin24hs_dashboard 2>/dev/null; echo 'Servicio reiniciado (sin script)')"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Dashboard subido correctamente" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Verificar: https://dashboard.checkin24hs.com (Ctrl+Shift+R para evitar cache)" -ForegroundColor Gray
Write-Host ""
