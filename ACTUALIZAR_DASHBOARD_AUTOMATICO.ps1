# Script PowerShell para actualizar dashboard.html automáticamente
# Actualiza build number, hace commit y push

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔄 ACTUALIZAR DASHBOARD AUTOMÁTICO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
$projectPath = "c:\Users\German\Downloads\Checkin24hs"
Set-Location $projectPath

$dashboardFile = "dashboard.html"

if (-not (Test-Path $dashboardFile)) {
    Write-Host "❌ Error: No se encuentra $dashboardFile" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Paso 1: Actualizando build number..." -ForegroundColor Yellow

# Leer el archivo
$content = Get-Content $dashboardFile -Raw -Encoding UTF8

# Obtener build number actual
$currentBuild = 64
if ($content -match "window\.DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)") {
    $currentBuild = [int]$matches[1]
    Write-Host "   Build actual: $currentBuild" -ForegroundColor Gray
} else {
    Write-Host "   ⚠️  No se encontró build number, usando 64 como base" -ForegroundColor Yellow
    $currentBuild = 64
}

# Incrementar build number
$newBuild = $currentBuild + 1
Write-Host "   Nuevo build: $newBuild" -ForegroundColor Green

# Generar timestamp actual
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "   Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

# Actualizar build number
$content = $content -replace "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+", "window.DASHBOARD_BUILD_NUMBER = $newBuild"

# Actualizar build timestamp
$content = $content -replace "window\.DASHBOARD_BUILD\s*=\s*'[^']+'", "window.DASHBOARD_BUILD = '$timestamp'"

# Guardar el archivo
Set-Content -Path $dashboardFile -Value $content -Encoding UTF8 -NoNewline

Write-Host "✅ Build number actualizado: $currentBuild → $newBuild" -ForegroundColor Green
Write-Host "✅ Timestamp actualizado: $timestamp" -ForegroundColor Green
Write-Host ""

# Verificar cambios
Write-Host "📋 Verificación:" -ForegroundColor Cyan
Select-String -Path $dashboardFile -Pattern "DASHBOARD_BUILD" | Select-Object -First 2
Write-Host ""

# Agregar a Git
Write-Host "📋 Paso 2: Agregando a Git..." -ForegroundColor Yellow
git add dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Archivo agregado" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No se pudo agregar archivo" -ForegroundColor Yellow
}
Write-Host ""

# Commit
Write-Host "📋 Paso 3: Creando commit..." -ForegroundColor Yellow
$COMMIT_MSG = "Build #${newBuild}: Actualizar dashboard

- Build number: ${newBuild} (incrementado desde ${currentBuild})
- Timestamp: ${timestamp}
- Actualización automática de build number"

Write-Host "   Mensaje de commit:" -ForegroundColor Gray
Write-Host "   $COMMIT_MSG" -ForegroundColor Gray
Write-Host ""
Write-Host "   ¿Continuar con el commit? (S/N): " -NoNewline
$confirm = Read-Host

if ($confirm -eq "S" -or $confirm -eq "s") {
    git commit -m $COMMIT_MSG
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Commit creado" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  No se pudo crear commit" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Proceso cancelado" -ForegroundColor Red
    exit
}
Write-Host ""

# Push
Write-Host "📋 Paso 4: Subiendo a GitHub..." -ForegroundColor Yellow
Write-Host "   ¿Subir cambios a GitHub? (S/N): " -NoNewline
$push = Read-Host

if ($push -eq "S" -or $push -eq "s") {
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Cambios subidos a GitHub" -ForegroundColor Green
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "✅ ÉXITO: Dashboard actualizado" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Build desplegado: #$newBuild" -ForegroundColor Cyan
        Write-Host "🕐 Timestamp: $timestamp" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "   ❌ Error al subir cambios" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠️  Cambios no subidos a GitHub" -ForegroundColor Yellow
}

Write-Host ""
