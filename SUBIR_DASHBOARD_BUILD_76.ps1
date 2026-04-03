# Subir modificaciones locales + Build #76 para deploy desde Git (EasyPanel sin bind mounts)
# Ejecutar desde la raíz del repo: .\SUBIR_DASHBOARD_BUILD_76.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Build #76 - Dashboard desde Git (EasyPanel sin bind mounts); og-cotizar.jpg en imagen" -ForegroundColor Cyan
Write-Host ""

# Archivos modificados/creados en esta sesión (dashboard, imagen cotización, EasyPanel Git)
$files = @(
    "dashboard.html",                                    # Build #76 + cambios locales
    "whatsapp-server/whatsapp-server-baileys.js",        # Imagen cotización Flor
    "checkin24hs-admin/server.js",                       # og-cotizar.jpg en build
    "checkin24hs-admin/public/og-cotizar.jpg",           # Imagen promocional
    "deploy/dashboard-html/Dockerfile",                  # og-cotizar.jpg en imagen
    "deploy/dashboard-html/server.js",                   # Prioridad og-cotizar.jpg local
    "deploy/dashboard-html/DEPLOY_DASHBOARD_HTML.md",
    "docs/EASYPANEL_DASHBOARD_GIT_FLUJO.md",
    "docs/ACTUALIZAR_DASHBOARD_OG_COTIZAR.md",
    "docs/VERIFICAR_OG_COTIZAR_EN_CONTENEDOR.md",
    "docs/PASOS_DESPUES_IMAGEN_COTIZACION.md",
    "SUBIR_OG_COTIZAR_AL_SERVIDOR.ps1",
    "SUBIR_IMAGEN_COTIZACION.ps1",
    "SUBIR_DASHBOARD_BUILD_76.ps1"
)

Write-Host "1. Agregando archivos..." -ForegroundColor Cyan
foreach ($f in $files) {
    if (Test-Path $f) {
        git add $f
        Write-Host "   + $f" -ForegroundColor Gray
    } else {
        Write-Host "   (no existe: $f)" -ForegroundColor Yellow
    }
}

# Por si hay más cambios en deploy/ o docs/
git add deploy/
git add docs/
git add dashboard.html
git add whatsapp-server/whatsapp-server-baileys.js
git add checkin24hs-admin/

Write-Host ""
Write-Host "2. Estado:" -ForegroundColor Cyan
git status

Write-Host ""
Write-Host "3. Commit (Build #76)..." -ForegroundColor Cyan
git commit -m "Build #76: Dashboard desde Git (EasyPanel sin bind mounts); og-cotizar.jpg en imagen; Flor imagen cotización"

Write-Host ""
Write-Host "4. Push..." -ForegroundColor Cyan
git push

Write-Host ""
Write-Host "Listo. Build #76 subido. En EasyPanel: Implementar (Deploy) del servicio dashboard." -ForegroundColor Green
