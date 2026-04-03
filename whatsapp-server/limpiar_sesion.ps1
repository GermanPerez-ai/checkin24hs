# Script para limpiar la sesión de WhatsApp bloqueada (Windows PowerShell)

Write-Host "🧹 Limpiando sesión de WhatsApp..." -ForegroundColor Cyan

# Directorio de sesión
$SESSION_DIR = ".wwebjs_auth"
$DEFAULT_DIR = Join-Path $SESSION_DIR "Default"

# Eliminar archivos de lock
if (Test-Path $DEFAULT_DIR) {
    Write-Host "📋 Eliminando archivos de lock..." -ForegroundColor Yellow
    
    # Archivos de lock específicos
    $lockFiles = @(
        "SingletonLock",
        "SingletonSocket",
        "SingletonCookie"
    )
    
    foreach ($lockFile in $lockFiles) {
        $filePath = Join-Path $DEFAULT_DIR $lockFile
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Eliminado: $lockFile" -ForegroundColor Green
        }
    }
    
    # Eliminar otros archivos de lock
    Get-ChildItem -Path $DEFAULT_DIR -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -like "*Lock*" -or $_.Name -like "*Singleton*"
    } | Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-Host "✅ Archivos de lock eliminados." -ForegroundColor Green
} else {
    Write-Host "⚠️  Directorio de sesión no encontrado." -ForegroundColor Yellow
}

# Matar procesos de Chrome/Puppeteer si existen
Write-Host "🔍 Buscando procesos de Chrome/Puppeteer..." -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.ProcessName -like "*chrome*" -or 
    $_.ProcessName -like "*chromium*" -or
    $_.ProcessName -like "*puppeteer*"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "✅ Procesos terminados." -ForegroundColor Green

# Opción para limpiar toda la sesión
if ($args -contains "--clear-all") {
    Write-Host "`n🗑️  Eliminando toda la sesión..." -ForegroundColor Yellow
    if (Test-Path $SESSION_DIR) {
        Remove-Item $SESSION_DIR -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Sesión completa eliminada. Necesitarás escanear el QR nuevamente." -ForegroundColor Green
    }
} else {
    Write-Host "`n💡 Si el problema persiste, ejecuta:" -ForegroundColor Cyan
    Write-Host "   .\limpiar_sesion.ps1 --clear-all" -ForegroundColor White
    Write-Host "   (Esto eliminará la sesión y necesitarás escanear el QR nuevamente)" -ForegroundColor Gray
}

Write-Host "`n✅ Limpieza completada. Puedes reiniciar el servidor ahora." -ForegroundColor Green

