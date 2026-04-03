# Script completo: Incrementar versión, commit y push a GitHub

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ACTUALIZAR VERSION Y SUBIR A GITHUB" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Incrementar versión
Write-Host "[1/4] Incrementando build number..." -ForegroundColor Yellow
& .\INCREMENTAR_VERSION.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Error al incrementar version" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Paso 2: Obtener nuevo build number
$content = Get-Content "deploy\dashboard.html" -Raw -Encoding UTF8
if ($content -match "window\.DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)") {
    $NEW_BUILD = $matches[1]
} else {
    $NEW_BUILD = "?"
}

if ($content -match "window\.DASHBOARD_BUILD\s*=\s*'([^']+)'") {
    $NEW_TIMESTAMP = $matches[1]
} else {
    $NEW_TIMESTAMP = "?"
}

Write-Host "[2/4] Agregando cambios a Git..." -ForegroundColor Yellow
git add deploy/dashboard.html

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Archivo agregado" -ForegroundColor Green
} else {
    Write-Host "ERROR: Error al agregar archivo" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Paso 3: Commit
Write-Host "[3/4] Creando commit..." -ForegroundColor Yellow
$COMMIT_MSG = "Build #${NEW_BUILD}: Actualizar version del dashboard`n`n- Build number: ${NEW_BUILD}`n- Timestamp: ${NEW_TIMESTAMP}`n- Correcciones de codificacion UTF-8 aplicadas"

git commit -m $COMMIT_MSG

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Commit creado" -ForegroundColor Green
} else {
    Write-Host "No se pudo crear commit (puede que no haya cambios)" -ForegroundColor Yellow
}
Write-Host ""

# Paso 4: Push
Write-Host "[4/4] Subiendo a GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "EXITO: Version actualizada y subida" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Ve a EasyPanel -> Servicio 'dashboard'" -ForegroundColor White
    Write-Host "2. Haz clic en 'Deploy' o 'Redeploy'" -ForegroundColor White
    Write-Host "3. Espera 2-5 minutos" -ForegroundColor White
    Write-Host "4. Recarga la pagina con Ctrl+F5" -ForegroundColor White
    Write-Host "5. Verifica que la version se muestre en el sidebar" -ForegroundColor White
    Write-Host ""
    Write-Host "Version desplegada: Build #$NEW_BUILD" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR al subir cambios" -ForegroundColor Red
    Write-Host "   Verifica tus credenciales de GitHub" -ForegroundColor Yellow
    exit 1
}
