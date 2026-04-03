# Script para subir correcciones de signos "?" a GitHub
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🚀 SUBIR CORRECCIONES A GITHUB" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "deploy\dashboard.html")) {
    Write-Host "❌ Error: No se encuentra deploy\dashboard.html" -ForegroundColor Red
    Write-Host "   Asegúrate de estar en el directorio Checkin24hs" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Archivo dashboard.html encontrado" -ForegroundColor Green
Write-Host ""

# Verificar estado de Git
Write-Host "=== Verificando estado de Git ===" -ForegroundColor Yellow
git status --short | Select-Object -First 10
Write-Host ""

# Verificar si hay cambios en deploy/dashboard.html
$dashboardChanges = git status --short deploy/dashboard.html
if ($dashboardChanges) {
    Write-Host "✅ Cambios detectados en deploy/dashboard.html" -ForegroundColor Green
} else {
    Write-Host "⚠️  No hay cambios en deploy/dashboard.html" -ForegroundColor Yellow
    Write-Host "   ¿Quieres continuar de todas formas? (S/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "S" -and $response -ne "s") {
        Write-Host "❌ Cancelado" -ForegroundColor Red
        exit 0
    }
}
Write-Host ""

# Verificar rama actual
Write-Host "=== Verificando rama actual ===" -ForegroundColor Yellow
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host "⚠️  No hay rama activa. Creando rama 'main'..." -ForegroundColor Yellow
    git checkout -b main
    $currentBranch = "main"
}
Write-Host "Rama actual: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Agregar archivos
Write-Host "=== Agregando archivos a staging ===" -ForegroundColor Yellow
git add deploy/dashboard.html
Write-Host "✅ deploy/dashboard.html agregado" -ForegroundColor Green

# Verificar si hay otros archivos importantes
if (Test-Path "deploy\serve-dashboard.js") {
    git add deploy/serve-dashboard.js
    Write-Host "✅ deploy/serve-dashboard.js agregado" -ForegroundColor Green
}

Write-Host ""

# Hacer commit
Write-Host "=== Creando commit ===" -ForegroundColor Yellow
$commitMessage = "Fix: Corregir signos '?' y problemas de codificación UTF-8 en dashboard

- Corregir 'Mes/A?o' -> 'Mes/Año' en Dashboard
- Corregir 'Ubicaci?n' -> 'Ubicación' en Hoteles
- Corregir '?Cómo' -> '¿Cómo' en Programa Flexi
- Corregir 'Confirmaci?n' -> 'Confirmación'
- Corregir 'Estad?a' -> 'Estadía'
- Corregir problemas de codificación UTF-8
- Cambiar título 'configuración de Flor IA' -> 'Configuración de Flor IA'"

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Commit creado exitosamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al crear commit" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verificar remoto
Write-Host "=== Verificando remoto ===" -ForegroundColor Yellow
$remote = git remote get-url origin
Write-Host "Remoto: $remote" -ForegroundColor Cyan
Write-Host ""

# Push a GitHub
Write-Host "=== Subiendo a GitHub ===" -ForegroundColor Yellow
Write-Host "Rama: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Si es el primer commit, usar -u para establecer upstream
$firstCommit = git log --oneline -1 2>&1
if ($LASTEXITCODE -ne 0 -or -not $firstCommit) {
    Write-Host "Primer commit detectado. Usando 'git push -u origin $currentBranch'..." -ForegroundColor Yellow
    git push -u origin $currentBranch
} else {
    Write-Host "Haciendo push normal..." -ForegroundColor Yellow
    git push origin $currentBranch
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Cambios subidos exitosamente a GitHub" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "📋 PRÓXIMOS PASOS" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ve a EasyPanel:" -ForegroundColor Yellow
    Write-Host "   - Proyecto: checkin24hs" -ForegroundColor White
    Write-Host "   - Servicio: dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Verifica la configuración:" -ForegroundColor Yellow
    Write-Host "   - Source: GitHub" -ForegroundColor White
    Write-Host "   - Repository: GermanPerez-ai/checkin24hs" -ForegroundColor White
    Write-Host "   - Branch: $currentBranch" -ForegroundColor White
    Write-Host "   - Build Path: /deploy (o /)" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Haz clic en 'Deploy' o 'Redeploy'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "4. Espera 2-5 minutos mientras se construye" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "5. Recarga el dashboard con Ctrl+F5" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al subir cambios" -ForegroundColor Red
    Write-Host "   Verifica tus credenciales de GitHub" -ForegroundColor Yellow
    exit 1
}
