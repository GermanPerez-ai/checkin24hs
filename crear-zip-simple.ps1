# Script simple para crear ZIP de deploy (sin hotel-images)
Write-Host "Creando ZIP para deploy..." -ForegroundColor Yellow

# Archivos a incluir
$archivos = @(
    "dashboard.html",
    "index.html", 
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
    "nginx.conf",
    "logo.png",
    "logo-checkin24hs.svg",
    "logo-checkin24hs-circular-olive.svg",
    "logo-checkin24hs-olive.svg"
)

# Filtrar solo archivos que existen
$archivosExistentes = $archivos | Where-Object { Test-Path $_ }

# Eliminar ZIP anterior si existe
if (Test-Path "checkin24hs-deploy.zip") {
    Remove-Item "checkin24hs-deploy.zip" -Force
}

# Crear ZIP
Compress-Archive -Path $archivosExistentes -DestinationPath "checkin24hs-deploy.zip" -Force

# Mostrar resultado
if (Test-Path "checkin24hs-deploy.zip") {
    $tamano = [math]::Round((Get-Item "checkin24hs-deploy.zip").Length / 1MB, 2)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "ZIP CREADO EXITOSAMENTE!" -ForegroundColor Green
    Write-Host "Archivo: checkin24hs-deploy.zip" -ForegroundColor Cyan
    Write-Host "Tamano: $tamano MB" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora sube este archivo a EasyPanel" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: No se pudo crear el ZIP" -ForegroundColor Red
}

