# Script para subir cambios de la ruta /og-cotizar.jpg
# Ejecuta este script en PowerShell desde la raíz del proyecto

Write-Host "🔧 Preparando cambios para subir..." -ForegroundColor Cyan

# Cambiar al directorio del proyecto
Set-Location "C:\Users\German\Downloads\Checkin24hs"

# Eliminar archivo de bloqueo si existe
if (Test-Path .git\index.lock) {
    Write-Host "⚠️ Eliminando archivo de bloqueo..." -ForegroundColor Yellow
    Remove-Item .git\index.lock -Force -ErrorAction SilentlyContinue
}

# Agregar archivos modificados
Write-Host "📦 Agregando archivos al staging..." -ForegroundColor Cyan
git add checkin24hs-admin/server.js
git add checkin24hs-admin/Dockerfile
git add cotizador-cliente.html
git add server.js
git add AGREGAR_RUTA_OG_IMAGE_DASHBOARD.md

# Verificar qué se agregó
Write-Host "`n📋 Archivos en staging:" -ForegroundColor Cyan
git status --short

# Hacer commit
Write-Host "`n💾 Creando commit..." -ForegroundColor Cyan
git commit -m "Agregar ruta /og-cotizar.jpg en dashboard para preview de Open Graph/WhatsApp

- Agregada ruta /og-cotizar.jpg en checkin24hs-admin/server.js
- Actualizado Dockerfile para copiar server.js real
- Actualizados metadatos Open Graph en cotizador-cliente.html
- Agregada ruta /og-cotizar.jpg también en server.js principal"

# Subir a GitHub
Write-Host "`n🚀 Subiendo cambios a GitHub..." -ForegroundColor Cyan
git push origin main

Write-Host "`n✅ ¡Cambios subidos exitosamente!" -ForegroundColor Green
Write-Host "`n📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Ve a EasyPanel" -ForegroundColor White
Write-Host "2. Abre el servicio del dashboard" -ForegroundColor White
Write-Host "3. Haz clic en 'Redeploy' o 'Reconstruir'" -ForegroundColor White
Write-Host "4. Espera 2-5 minutos a que termine" -ForegroundColor White
Write-Host "5. Verifica: https://dashboard.checkin24hs.com/og-cotizar.jpg" -ForegroundColor White
