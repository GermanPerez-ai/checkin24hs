# Script para limpiar sesión de WhatsApp en Docker (Windows PowerShell)

Write-Host "🧹 Limpiando sesión de WhatsApp en Docker..." -ForegroundColor Cyan
Write-Host ""

# Nombre del contenedor (ajusta según tu configuración)
$containerName = "whatsapp-server"

# Verificar si el contenedor existe
$containers = docker ps -a --format "{{.Names}}"
if ($containers -notcontains $containerName) {
    Write-Host "⚠️  Contenedor '$containerName' no encontrado" -ForegroundColor Yellow
    Write-Host "📋 Contenedores disponibles:" -ForegroundColor Cyan
    docker ps -a --format "{{.Names}}"
    Write-Host ""
    $containerName = Read-Host "Ingresa el nombre del contenedor"
}

# Detener el contenedor
Write-Host "🛑 Deteniendo contenedor..." -ForegroundColor Yellow
docker stop $containerName

# Intentar eliminar la sesión
Write-Host "🗑️  Eliminando sesión de WhatsApp..." -ForegroundColor Yellow
try {
    docker exec $containerName rm -rf .wwebjs_auth 2>$null
    Write-Host "✅ Sesión eliminada" -ForegroundColor Green
} catch {
    Write-Host "⚠️  No se pudo eliminar automáticamente" -ForegroundColor Yellow
    Write-Host "   Ejecuta manualmente:" -ForegroundColor White
    Write-Host "   docker exec $containerName rm -rf .wwebjs_auth" -ForegroundColor Gray
}

# Reiniciar el contenedor
Write-Host "🔄 Reiniciando contenedor..." -ForegroundColor Yellow
docker start $containerName

Write-Host ""
Write-Host "✅ Limpieza completada!" -ForegroundColor Green
Write-Host "📱 El servidor debería mostrar el código QR al reiniciar" -ForegroundColor Cyan
Write-Host ""

