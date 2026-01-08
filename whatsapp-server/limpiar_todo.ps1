# Script completo para limpiar sesión de WhatsApp y procesos bloqueados

Write-Host "🧹 Limpiando sesión de WhatsApp y procesos bloqueados..." -ForegroundColor Cyan
Write-Host ""

# 1. Detener procesos de Node relacionados con WhatsApp
Write-Host "🔍 Buscando procesos de Node..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*whatsapp*" -or $_.CommandLine -like "*whatsapp*"
}

if ($nodeProcesses) {
    Write-Host "🛑 Deteniendo procesos de Node..." -ForegroundColor Yellow
    $nodeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Procesos de Node detenidos" -ForegroundColor Green
} else {
    Write-Host "ℹ️  No se encontraron procesos de Node de WhatsApp" -ForegroundColor Gray
}

# 2. Detener procesos de Chrome/Chromium
Write-Host ""
Write-Host "🔍 Buscando procesos de Chrome/Chromium..." -ForegroundColor Yellow
$chromeProcesses = Get-Process -Name "chrome","chromium" -ErrorAction SilentlyContinue

if ($chromeProcesses) {
    Write-Host "⚠️  Se encontraron $($chromeProcesses.Count) procesos de Chrome" -ForegroundColor Yellow
    Write-Host "   ¿Deseas detenerlos? (S/N): " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "S" -or $response -eq "s" -or $response -eq "Y" -or $response -eq "y") {
        $chromeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Procesos de Chrome detenidos" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Procesos de Chrome no detenidos" -ForegroundColor Gray
    }
} else {
    Write-Host "ℹ️  No se encontraron procesos de Chrome" -ForegroundColor Gray
}

# 3. Limpiar carpeta de sesión local
Write-Host ""
Write-Host "📋 Limpiando carpeta de sesión local..." -ForegroundColor Yellow
$sessionDir = Join-Path $PSScriptRoot ".wwebjs_auth"

if (Test-Path $sessionDir) {
    Write-Host "🗑️  Eliminando carpeta de sesión..." -ForegroundColor Yellow
    Remove-Item $sessionDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Carpeta de sesión eliminada" -ForegroundColor Green
    Write-Host "   Necesitarás escanear el QR nuevamente" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  Carpeta de sesión no encontrada localmente" -ForegroundColor Gray
    Write-Host "   (Puede estar en el servidor remoto)" -ForegroundColor Gray
}

# 4. Limpiar archivos de lock en la carpeta Default si existe
Write-Host ""
Write-Host "📋 Buscando archivos de lock..." -ForegroundColor Yellow
$defaultDir = Join-Path $sessionDir "Default"

if (Test-Path $defaultDir) {
    $lockFiles = Get-ChildItem -Path $defaultDir -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -like "*Lock*" -or $_.Name -like "*Singleton*"
    }
    
    if ($lockFiles) {
        $lockFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Archivos de lock eliminados" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No se encontraron archivos de lock" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "✅ Limpieza completada!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Reinicia el servidor de WhatsApp" -ForegroundColor White
Write-Host "   2. Deberías ver el código QR para escanear" -ForegroundColor White
Write-Host "   3. Escanea el QR con tu teléfono" -ForegroundColor White
Write-Host ""

