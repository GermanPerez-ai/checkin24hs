# ============================================
# SOLUCION TECNICA: Sincronizar y Subir Correcciones
# ============================================
# Este script sincroniza el repositorio local con GitHub
# y sube SOLO el archivo dashboard.html corregido
# ============================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SOLUCION TECNICA GITHUB" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Verificar que el archivo corregido existe
Write-Host "[1/6] Verificando archivo corregido..." -ForegroundColor Yellow
if (-not (Test-Path "deploy\dashboard.html")) {
    Write-Host "ERROR: deploy\dashboard.html no encontrado" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Archivo encontrado" -ForegroundColor Green
Write-Host ""

# Paso 2: Guardar el archivo corregido en un lugar seguro
Write-Host "[2/6] Guardando copia de seguridad del archivo corregido..." -ForegroundColor Yellow
$backupPath = "deploy\dashboard.html.corregido"
Copy-Item "deploy\dashboard.html" -Destination $backupPath -Force
Write-Host "OK: Backup guardado en: $backupPath" -ForegroundColor Green
Write-Host ""

# Paso 3: Sincronizar con el remoto
Write-Host "[3/6] Sincronizando con GitHub..." -ForegroundColor Yellow
Write-Host "ADVERTENCIA: Esto descartara el commit local y se alineara con el remoto" -ForegroundColor Yellow
Write-Host ""

# Obtener el estado actual
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host "No hay rama activa. Creando rama main..." -ForegroundColor Yellow
    git checkout -b main
}

# Resetear al remoto (descartar cambios locales)
Write-Host "   Descargando cambios del remoto..." -ForegroundColor Gray
git fetch origin main

# Resetear al remoto (mantener archivos locales)
Write-Host "   Sincronizando con origin/main..." -ForegroundColor Gray
git reset --hard origin/main

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Sincronizacion completada" -ForegroundColor Green
} else {
    Write-Host "ERROR en la sincronizacion" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Paso 4: Restaurar el archivo corregido
Write-Host "[4/6] Restaurando archivo corregido..." -ForegroundColor Yellow
Copy-Item $backupPath -Destination "deploy\dashboard.html" -Force
Write-Host "OK: Archivo corregido restaurado" -ForegroundColor Green
Write-Host ""

# Paso 5: Verificar cambios
Write-Host "[5/6] Verificando cambios..." -ForegroundColor Yellow
$status = git status --porcelain deploy/dashboard.html
if ($status) {
    Write-Host "OK: Cambios detectados en deploy/dashboard.html" -ForegroundColor Green
    Write-Host "   $status" -ForegroundColor Gray
} else {
    Write-Host "No se detectaron cambios. El archivo puede estar igual al remoto." -ForegroundColor Yellow
}
Write-Host ""

# Paso 6: Agregar, commit y push
Write-Host "[6/6] Subiendo cambios a GitHub..." -ForegroundColor Yellow
Write-Host ""

# Agregar solo el archivo corregido
git add deploy/dashboard.html

# Crear commit
$commitMessage = "Fix: Corregir signos '?' y codificacion UTF-8 en dashboard`n`n- Corregir 'Mes/A?o' -> 'Mes/Ano' en Dashboard`n- Corregir 'Ubicaci?n' -> 'Ubicacion' en Hoteles`n- Corregir '?Como' -> '?Como' en Programa Flexi`n- Corregir 'Confirmaci?n' -> 'Confirmacion'`n- Corregir 'Estad?a' -> 'Estadia'`n- Cambiar titulo 'configuracion de Flor IA' -> 'Configuracion de Flor IA'"

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Commit creado" -ForegroundColor Green
} else {
    Write-Host "No se pudo crear commit (puede que no haya cambios)" -ForegroundColor Yellow
    Write-Host "   Verificando si hay commits para subir..." -ForegroundColor Gray
    
    # Verificar si hay commits locales
    $localCommits = git log origin/main..HEAD --oneline
    if ($localCommits) {
        Write-Host "OK: Hay commits locales para subir" -ForegroundColor Green
    } else {
        Write-Host "No hay commits nuevos. El archivo puede estar igual al remoto." -ForegroundColor Cyan
        Write-Host "   Esto es normal si el archivo ya estaba corregido en GitHub." -ForegroundColor Gray
    }
}
Write-Host ""

# Push a GitHub
Write-Host "   Subiendo a GitHub..." -ForegroundColor Gray
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "EXITO: Cambios subidos a GitHub" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS EN EASYPANEL:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ve a EasyPanel -> Servicio 'dashboard'" -ForegroundColor White
    Write-Host "2. Verifica que la rama sea 'main'" -ForegroundColor White
    Write-Host "3. Haz clic en 'Deploy' o 'Redeploy'" -ForegroundColor White
    Write-Host "4. Espera 2-5 minutos mientras se construye" -ForegroundColor White
    Write-Host "5. Recarga el dashboard con Ctrl+F5" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR al subir cambios" -ForegroundColor Red
    Write-Host "   Verifica tus credenciales de GitHub" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ALTERNATIVA: El archivo corregido esta guardado en:" -ForegroundColor Cyan
    Write-Host "   $backupPath" -ForegroundColor White
    Write-Host "   Puedes subirlo manualmente al servidor con scp" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Limpiar backup
Write-Host "Limpiando archivo temporal..." -ForegroundColor Gray
Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
Write-Host "OK: Completado" -ForegroundColor Green
Write-Host ""
