# Script para crear ZIP de deploy
$tempDir = "deploy_temp"

# Limpiar carpeta temporal si existe
if (Test-Path $tempDir) { 
    Remove-Item -Recurse -Force $tempDir 
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Lista de archivos esenciales
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
    "server.js",
    "package.json",
    "nginx.conf",
    "logo.png"
)

# Copiar archivos
foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Copy-Item -Path $archivo -Destination $tempDir
        Write-Host "Copiado: $archivo"
    }
}

# Copiar logos SVG
Get-ChildItem -Filter "logo-checkin24hs*.svg" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $tempDir
    Write-Host "Copiado: $($_.Name)"
}

# Copiar carpeta hotel-images
if (Test-Path "hotel-images") {
    Copy-Item -Path "hotel-images" -Destination $tempDir -Recurse
    Write-Host "Copiada carpeta: hotel-images"
}

# Copiar carpeta public si existe
if (Test-Path "public") {
    Copy-Item -Path "public" -Destination $tempDir -Recurse
    Write-Host "Copiada carpeta: public"
}

# Crear ZIP
$zipPath = "checkin24hs-deploy.zip"
if (Test-Path $zipPath) { 
    Remove-Item $zipPath 
}

Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

# Mostrar resultado
$size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ZIP creado exitosamente!" -ForegroundColor Green
Write-Host "Archivo: $zipPath" -ForegroundColor Green
Write-Host "Tamano: $size MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Limpiar
Remove-Item -Recurse -Force $tempDir

