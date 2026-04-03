# Script para Intercambiar admincheckin con Dashboard en EasyPanel
# Autor: German Perez
# Fecha: 2025-01-28

Write-Host "🔄 Script de Intercambio: admincheckin -> Dashboard EasyPanel" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Buscar la carpeta admincheckin
Write-Host "📂 Buscando carpeta admincheckin..." -ForegroundColor Yellow

$admincheckinPath = $null

# Buscar en ubicaciones comunes
$searchPaths = @(
    "C:\Users\German\Downloads\Checkin24hs\admincheckin",
    "C:\Users\German\admincheckin",
    "C:\Users\German\Desktop\admincheckin",
    "C:\Users\German\Documents\admincheckin",
    ".\admincheckin"
)

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $admincheckinPath = $path
        Write-Host "✅ Encontrada en: $path" -ForegroundColor Green
        break
    }
}

# Si no se encuentra, pedir al usuario
if (-not $admincheckinPath) {
    Write-Host "❌ No se encontró la carpeta admincheckin automáticamente." -ForegroundColor Red
    Write-Host ""
    $admincheckinPath = Read-Host "Por favor, ingresa la ruta completa de la carpeta admincheckin"
    
    if (-not (Test-Path $admincheckinPath)) {
        Write-Host "❌ Error: La ruta no existe: $admincheckinPath" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📋 Información de la carpeta encontrada:" -ForegroundColor Cyan
Write-Host "   Ruta: $admincheckinPath" -ForegroundColor White

# Verificar que tenga los archivos necesarios
$hasPackageJson = Test-Path (Join-Path $admincheckinPath "package.json")
$hasSrc = Test-Path (Join-Path $admincheckinPath "src")

Write-Host ""
if ($hasPackageJson) {
    Write-Host "✅ Tiene package.json" -ForegroundColor Green
} else {
    Write-Host "⚠️  No tiene package.json (puede ser una aplicación diferente)" -ForegroundColor Yellow
}

if ($hasSrc) {
    Write-Host "✅ Tiene carpeta src/" -ForegroundColor Green
} else {
    Write-Host "⚠️  No tiene carpeta src/ (puede tener otra estructura)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "¿Qué quieres hacer?" -ForegroundColor Cyan
Write-Host "1. Reemplazar checkin24hs-admin con admincheckin (mantener nombre en GitHub)"
Write-Host "2. Agregar admincheckin como nueva carpeta (cambiar ruta en EasyPanel)"
Write-Host "3. Solo mostrar información (no hacer cambios)"
Write-Host ""

$opcion = Read-Host "Elige una opción (1, 2 o 3)"

$proyectoPath = "C:\Users\German\Downloads\Checkin24hs"

if ($opcion -eq "1") {
    Write-Host ""
    Write-Host "🔄 Opción 1: Reemplazar checkin24hs-admin" -ForegroundColor Cyan
    
    $checkin24hsAdminPath = Join-Path $proyectoPath "checkin24hs-admin"
    
    if (-not (Test-Path $checkin24hsAdminPath)) {
        Write-Host "❌ Error: No existe checkin24hs-admin en el proyecto" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "⚠️  ADVERTENCIA: Esto reemplazará el contenido de checkin24hs-admin" -ForegroundColor Yellow
    Write-Host "   Se creará un backup automático en checkin24hs-admin-backup" -ForegroundColor Yellow
    $confirmar = Read-Host "¿Continuar? (S/N)"
    
    if ($confirmar -ne "S" -and $confirmar -ne "s") {
        Write-Host "❌ Operación cancelada" -ForegroundColor Red
        exit 0
    }
    
    # Crear backup
    $backupPath = Join-Path $proyectoPath "checkin24hs-admin-backup"
    Write-Host ""
    Write-Host "📦 Creando backup..." -ForegroundColor Yellow
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Recurse -Force
    }
    Copy-Item -Path $checkin24hsAdminPath -Destination $backupPath -Recurse
    Write-Host "✅ Backup creado en: $backupPath" -ForegroundColor Green
    
    # Eliminar contenido actual (excepto .git)
    Write-Host ""
    Write-Host "🗑️  Eliminando contenido actual..." -ForegroundColor Yellow
    Get-ChildItem -Path $checkin24hsAdminPath -Exclude ".git" | Remove-Item -Recurse -Force
    
    # Copiar contenido de admincheckin
    Write-Host "📋 Copiando contenido de admincheckin..." -ForegroundColor Yellow
    Copy-Item -Path "$admincheckinPath\*" -Destination $checkin24hsAdminPath -Recurse -Force
    
    Write-Host "✅ Reemplazo completado" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Revisa los cambios: git status" -ForegroundColor White
    Write-Host "   2. Agrega los cambios: git add checkin24hs-admin/" -ForegroundColor White
    Write-Host "   3. Confirma: git commit -m 'Reemplazar con admincheckin funcional'" -ForegroundColor White
    Write-Host "   4. Sube a GitHub: git push" -ForegroundColor White
    Write-Host "   5. En EasyPanel, verifica que la ruta sea: /checkin24hs-admin" -ForegroundColor White
    Write-Host "   6. Implementa el servicio en EasyPanel" -ForegroundColor White
    
} elseif ($opcion -eq "2") {
    Write-Host ""
    Write-Host "🔄 Opción 2: Agregar admincheckin como nueva carpeta" -ForegroundColor Cyan
    
    $destinoPath = Join-Path $proyectoPath "admincheckin"
    
    if (Test-Path $destinoPath) {
        Write-Host "⚠️  La carpeta admincheckin ya existe en el proyecto" -ForegroundColor Yellow
        $sobrescribir = Read-Host "¿Sobrescribir? (S/N)"
        if ($sobrescribir -ne "S" -and $sobrescribir -ne "s") {
            Write-Host "❌ Operación cancelada" -ForegroundColor Red
            exit 0
        }
        Remove-Item $destinoPath -Recurse -Force
    }
    
    Write-Host ""
    Write-Host "📋 Copiando admincheckin al proyecto..." -ForegroundColor Yellow
    Copy-Item -Path $admincheckinPath -Destination $destinoPath -Recurse
    
    Write-Host "✅ Carpeta copiada a: $destinoPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Revisa los cambios: git status" -ForegroundColor White
    Write-Host "   2. Agrega los cambios: git add admincheckin/" -ForegroundColor White
    Write-Host "   3. Confirma: git commit -m 'Agregar admincheckin funcional'" -ForegroundColor White
    Write-Host "   4. Sube a GitHub: git push" -ForegroundColor White
    Write-Host "   5. En EasyPanel, cambia la ruta a: /admincheckin" -ForegroundColor White
    Write-Host "   6. Implementa el servicio en EasyPanel" -ForegroundColor White
    
} elseif ($opcion -eq "3") {
    Write-Host ""
    Write-Host "ℹ️  Solo mostrando información (no se hicieron cambios)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 Resumen:" -ForegroundColor Cyan
    Write-Host "   Carpeta admincheckin: $admincheckinPath" -ForegroundColor White
    Write-Host "   Tiene package.json: $hasPackageJson" -ForegroundColor White
    Write-Host "   Tiene src/: $hasSrc" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Para hacer el intercambio, ejecuta este script de nuevo y elige opción 1 o 2" -ForegroundColor Yellow
} else {
    Write-Host "❌ Opción inválida" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Script completado" -ForegroundColor Green

