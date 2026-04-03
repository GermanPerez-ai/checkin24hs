# Subir server.js y og-cotizar.jpg al servidor dashboard (bind mount en /root/checkin24hs/)
# Uso: .\SUBIR_OG_COTIZAR_AL_SERVIDOR.ps1
# Antes: edita $SERVER (IP o hostname del VPS) y si usas otra ruta o usuario, ajústalos.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# --- IP o hostname del servidor (ssh root@72.61.58.240) ---
$SERVER = "72.61.58.240"
$USER  = "root"
$REMOTE_DIR = "/root/checkin24hs"

$serverJs = "deploy\dashboard-html\server.js"
# Imagen promocional del cotizador (Checkin24hs / COTIZAR AHORA). Prioridad: og-preview.jpg, luego public/og-cotizar.jpg
$imageOgPreview = "hotel-images\hotel-images\og-preview.jpg"
$imagePublic    = "checkin24hs-admin\public\og-cotizar.jpg"
$image = if (Test-Path $imageOgPreview) { $imageOgPreview } else { $imagePublic }

if (-not (Test-Path $serverJs)) {
    Write-Host "No se encuentra: $serverJs" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $image)) {
    Write-Host "No se encuentra imagen: $image" -ForegroundColor Red
    exit 1
}
Write-Host "Usando imagen: $image" -ForegroundColor Gray

Write-Host "1. Subiendo server.js a ${USER}@${SERVER}:${REMOTE_DIR}/" -ForegroundColor Cyan
scp $serverJs "${USER}@${SERVER}:${REMOTE_DIR}/server.js"

Write-Host "2. Subiendo og-cotizar.jpg a ${USER}@${SERVER}:${REMOTE_DIR}/" -ForegroundColor Cyan
scp $image "${USER}@${SERVER}:${REMOTE_DIR}/og-cotizar.jpg"

Write-Host "3. Reiniciando servicio en el servidor..." -ForegroundColor Cyan
ssh "${USER}@${SERVER}" "docker service update --force checkin24hs_dashboard"

Write-Host "Listo. Prueba: https://dashboard.checkin24hs.com/og-cotizar.jpg" -ForegroundColor Green
