# Script para subir Dockerfile a GitHub
# Ejecutar desde PowerShell en: C:\Users\German\Downloads\Checkin24hs

Write-Host "=== SUBIR DOCKERFILE A GITHUB ===" -ForegroundColor Green
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "whatsapp-server\Dockerfile")) {
    Write-Host "ERROR: No se encuentra whatsapp-server\Dockerfile" -ForegroundColor Red
    Write-Host "Asegúrate de estar en: C:\Users\German\Downloads\Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Dockerfile encontrado" -ForegroundColor Green
Write-Host ""

# Intentar arreglar Git
Write-Host "1. Arreglando repositorio Git..." -ForegroundColor Yellow

# Eliminar referencia rota si existe
if (Test-Path ".git\refs\heads\main") {
    Remove-Item -Force ".git\refs\heads\main" -ErrorAction SilentlyContinue
}

# Inicializar rama main si no existe
try {
    git checkout -b main 2>$null
    git branch -M main 2>$null
    Write-Host "✅ Rama main inicializada" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Rama main ya existe o hay un problema" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "2. Agregando Dockerfile..." -ForegroundColor Yellow
git add whatsapp-server/Dockerfile

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dockerfile agregado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Error al agregar Dockerfile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "3. Haciendo commit..." -ForegroundColor Yellow
git commit -m "Actualizar Dockerfile: agregar fallback a Puppeteer para Chromium"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Commit realizado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Error al hacer commit (puede que no haya cambios)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "4. Subiendo a GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅✅✅ DOCKERFILE SUBIDO EXITOSAMENTE ✅✅✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ve a EasyPanel y configura:" -ForegroundColor Cyan
    Write-Host "1. Servicios → whatsapp → Fuente → Compilación" -ForegroundColor White
    Write-Host "2. Cambia 'Tipo de build' a 'Dockerfile'" -ForegroundColor White
    Write-Host "3. Ruta: whatsapp-server/Dockerfile" -ForegroundColor White
    Write-Host "4. Limpia Paquetes Nix, APT e Instalación" -ForegroundColor White
    Write-Host "5. Implementa" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Error al subir a GitHub" -ForegroundColor Red
    Write-Host ""
    Write-Host "OPCIÓN ALTERNATIVA:" -ForegroundColor Yellow
    Write-Host "Abre esta URL en tu navegador:" -ForegroundColor Cyan
    Write-Host "https://github.com/GermanPerez-ai/checkin24hs/edit/main/whatsapp-server/Dockerfile" -ForegroundColor White
    Write-Host ""
    Write-Host "Y edita el archivo manualmente desde ahí." -ForegroundColor Yellow
}

Write-Host ""









