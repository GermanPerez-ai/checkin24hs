# Script para crear ZIP del DASHBOARD (no index.html)
Write-Host "Creando ZIP para DASHBOARD..." -ForegroundColor Yellow

# Crear carpeta deploy si no existe
$deployDir = "deploy"
if (-not (Test-Path $deployDir)) {
    New-Item -ItemType Directory -Path $deployDir | Out-Null
}

# Archivos a incluir
$archivos = @(
    "dashboard.html",
    "crm.html",
    "crm.js",
    "flor-widget.js",
    "flor-agent.js",
    "flor-ai-service.js",
    "flor-knowledge-base.js",
    "flor-learning-system.js",
    "flor-chatbot.html",
    "supabase-client.js",
    "supabase-config.js",
    "database.js",
    "logo.png",
    "logo-checkin24hs.svg",
    "logo-checkin24hs-circular-olive.svg",
    "logo-checkin24hs-olive.svg"
)

# Copiar archivos a la carpeta deploy
foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Copy-Item -Path $archivo -Destination $deployDir -Force
        Write-Host "Copiado: $archivo" -ForegroundColor Green
    }
}

# El nginx.conf y Dockerfile ya están en deploy/

# Eliminar ZIP anterior si existe
if (Test-Path "dashboard-deploy.zip") {
    Remove-Item "dashboard-deploy.zip" -Force
}

# Crear ZIP
Compress-Archive -Path "$deployDir\*" -DestinationPath "dashboard-deploy.zip" -Force

# Mostrar resultado
if (Test-Path "dashboard-deploy.zip") {
    $tamano = [math]::Round((Get-Item "dashboard-deploy.zip").Length / 1MB, 2)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "ZIP CREADO EXITOSAMENTE!" -ForegroundColor Green
    Write-Host "Archivo: dashboard-deploy.zip" -ForegroundColor Cyan
    Write-Host "Tamano: $tamano MB" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Este ZIP configurara dashboard.html como pagina principal" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: No se pudo crear el ZIP" -ForegroundColor Red
}

