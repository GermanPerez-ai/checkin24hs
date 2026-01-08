# Script para crear ZIP del CRM para EasyPanel
# Ejecutar: powershell -ExecutionPolicy Bypass -File crear-zip-crm.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Creando ZIP del CRM para EasyPanel ===" -ForegroundColor Cyan

# Archivos necesarios para el CRM
$archivos = @(
    "crm.html",
    "crm.js",
    "supabase-config.js",
    "supabase-client.js",
    "flor-ai-service.js",
    "flor-agent.js",
    "flor-knowledge-base.js",
    "flor-learning-system.js",
    "flor-widget.js",
    "logo-checkin24hs-circular-olive.svg",
    "logo-checkin24hs.svg",
    "logo.png"
)

# Crear carpeta temporal
$tempDir = "temp-crm-deploy"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copiar Dockerfile y nginx.conf
Copy-Item "deploy-crm\Dockerfile" "$tempDir\Dockerfile" -Force
Write-Host "  Dockerfile copiado" -ForegroundColor Green
Copy-Item "deploy-crm\nginx.conf" "$tempDir\nginx.conf" -Force
Write-Host "  nginx.conf copiado" -ForegroundColor Green

# Copiar archivos del CRM
foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Copy-Item $archivo "$tempDir\$archivo" -Force
        Write-Host "  $archivo copiado" -ForegroundColor Green
    } else {
        Write-Host "  $archivo no encontrado" -ForegroundColor Yellow
    }
}

# Crear ZIP
$zipName = "crm-deploy.zip"
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName -Force

# Limpiar
Remove-Item $tempDir -Recurse -Force

# Mostrar resultado
$zipInfo = Get-Item $zipName
$zipSizeKB = [math]::Round($zipInfo.Length / 1KB, 2)

Write-Host ""
Write-Host "=== ZIP creado exitosamente ===" -ForegroundColor Green
Write-Host "Archivo: $zipName" -ForegroundColor Cyan
Write-Host "Tamano: $zipSizeKB KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Siguiente paso: Sube este ZIP a EasyPanel" -ForegroundColor Yellow
