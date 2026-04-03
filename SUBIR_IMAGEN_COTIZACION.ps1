# Subir cambios de imagen de cotización (Flor + og-cotizar.jpg)
# Ejecutar desde la raíz del repo: .\SUBIR_IMAGEN_COTIZACION.ps1

Set-Location $PSScriptRoot

Write-Host "1. Agregando archivos..." -ForegroundColor Cyan
git add whatsapp-server/whatsapp-server-baileys.js
git add checkin24hs-admin/server.js
git add checkin24hs-admin/public/og-cotizar.jpg
git add docs/PASOS_DESPUES_IMAGEN_COTIZACION.md
git add SUBIR_IMAGEN_COTIZACION.ps1

Write-Host "2. Estado:" -ForegroundColor Cyan
git status

Write-Host "3. Commit..." -ForegroundColor Cyan
git commit -m "Imagen cotización: Flor envía imagen+caption; og-cotizar.jpg en build del dashboard"

Write-Host "4. Push..." -ForegroundColor Cyan
git push

Write-Host "Listo." -ForegroundColor Green
