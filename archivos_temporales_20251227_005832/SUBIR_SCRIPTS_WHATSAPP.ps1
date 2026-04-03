# Script PowerShell para subir scripts de WhatsApp al servidor

$servidor = "root@72.61.58.240"
$rutaServidor = "/root/checkin24hs"

Write-Host "Subiendo scripts de WhatsApp al servidor..." -ForegroundColor Yellow

# Archivos a subir
$archivos = @(
    "VERIFICAR_SERVICIOS_Y_CREAR_WHATSAPP1.sh",
    "CONFIGURAR_TRAEFIK_WHATSAPP1.sh",
    "CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh",
    "CREAR_SERVICIOS_WHATSAPP_COMPLETO.sh"
)

foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Write-Host "Subiendo $archivo..." -ForegroundColor Cyan
        scp $archivo "${servidor}:${rutaServidor}/"
    } else {
        Write-Host "⚠️  Archivo $archivo no encontrado" -ForegroundColor Yellow
    }
}

Write-Host "✅ Scripts subidos correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Ejecuta en el servidor:" -ForegroundColor Yellow
Write-Host "  cd /root/checkin24hs" -ForegroundColor Cyan
Write-Host "  chmod +x *.sh" -ForegroundColor Cyan
Write-Host "  bash VERIFICAR_SERVICIOS_Y_CREAR_WHATSAPP1.sh" -ForegroundColor Cyan






