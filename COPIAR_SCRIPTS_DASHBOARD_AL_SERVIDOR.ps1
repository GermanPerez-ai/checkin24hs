# Script para copiar los scripts de actualización del dashboard al servidor

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📤 Copiar Scripts del Dashboard al Servidor" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Solicitar IP del servidor (con valor por defecto)
$defaultIP = "72.61.58.240"
Write-Host "Ingresa la IP del servidor" -ForegroundColor Yellow
Write-Host "   (Presiona Enter para usar la IP por defecto: $defaultIP): " -NoNewline -ForegroundColor Gray
$serverIP = Read-Host

if (-not $serverIP) {
    $serverIP = $defaultIP
    Write-Host "   ✅ Usando IP por defecto: $serverIP" -ForegroundColor Green
} else {
    Write-Host "   ✅ Usando IP: $serverIP" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Scripts a copiar:" -ForegroundColor Cyan
Write-Host "   1. ACTUALIZAR_DASHBOARD_FINAL.sh" -ForegroundColor Gray
Write-Host "   2. RECORDATORIO_ACTUALIZAR_DASHBOARD.sh" -ForegroundColor Gray
Write-Host ""

# Verificar que los archivos existen
$scripts = @(
    "ACTUALIZAR_DASHBOARD_FINAL.sh",
    "RECORDATORIO_ACTUALIZAR_DASHBOARD.sh"
)

$missingFiles = @()
foreach ($script in $scripts) {
    if (-not (Test-Path $script)) {
        $missingFiles += $script
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Los siguientes archivos no se encontraron:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Red
    }
    exit 1
}

Write-Host "📤 Copiando scripts al servidor..." -ForegroundColor Yellow
Write-Host ""

# Crear directorio si no existe
Write-Host "   📁 Creando directorio /root/checkin24hs si no existe..." -ForegroundColor Gray
ssh "root@${serverIP}" "mkdir -p /root/checkin24hs"

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠️  Advertencia: No se pudo crear el directorio (puede que ya exista)" -ForegroundColor Yellow
}

# Copiar cada script
$successCount = 0
foreach ($script in $scripts) {
    Write-Host "   📤 Copiando $script..." -ForegroundColor Gray
    scp $script "root@${serverIP}:/root/checkin24hs/"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      ✅ $script copiado correctamente" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "      ❌ Error al copiar $script" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🔧 Configurando permisos de ejecución..." -ForegroundColor Yellow

# Configurar permisos de ejecución
foreach ($script in $scripts) {
    ssh "root@${serverIP}" "chmod +x /root/checkin24hs/$script"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Permisos configurados para $script" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  No se pudieron configurar permisos para $script" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($successCount -eq $scripts.Count) {
    Write-Host "✅ Todos los scripts copiados correctamente" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunos scripts no se copiaron correctamente" -ForegroundColor Yellow
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Para usar los scripts en el servidor:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. Conéctate por SSH:" -ForegroundColor White
Write-Host "      ssh root@${serverIP}" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Ve al directorio:" -ForegroundColor White
Write-Host "      cd /root/checkin24hs" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Ejecuta el recordatorio (si olvidaste los pasos):" -ForegroundColor White
Write-Host "      ./RECORDATORIO_ACTUALIZAR_DASHBOARD.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "   4. O ejecuta directamente la actualización:" -ForegroundColor White
Write-Host '      ./ACTUALIZAR_DASHBOARD_FINAL.sh' -ForegroundColor Gray
Write-Host ""
