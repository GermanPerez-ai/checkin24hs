# Script PowerShell para eliminar/mover archivos obsoletos de forma segura

Write-Host "ELIMINAR ARCHIVOS OBSOLETOS" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
$projectPath = "C:\Users\German\Downloads\Checkin24hs"
Set-Location $projectPath

Write-Host "Directorio actual: $projectPath" -ForegroundColor Gray
Write-Host ""

# Archivos obsoletos a eliminar/mover
$archivosObsoletos = @(
    "index.html",
    "checkin24hs-react-version.html",
    "index-standalone.html",
    "index-mobile-multilang.html"
)

Write-Host "Verificando archivos obsoletos..." -ForegroundColor Yellow
Write-Host ""

$archivosEncontrados = @()
$archivosNoEncontrados = @()

foreach ($archivo in $archivosObsoletos) {
    if (Test-Path $archivo) {
        $archivosEncontrados += $archivo
        $tamano = (Get-Item $archivo).Length
        $tamanoKB = [math]::Round($tamano / 1KB, 2)
        Write-Host "   Encontrado: $archivo ($tamanoKB KB)" -ForegroundColor Green
    } else {
        $archivosNoEncontrados += $archivo
        Write-Host "   No encontrado: $archivo" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($archivosEncontrados.Count -eq 0) {
    Write-Host "No se encontraron archivos obsoletos para eliminar." -ForegroundColor Cyan
    exit 0
}

Write-Host "Archivos a procesar: $($archivosEncontrados.Count)" -ForegroundColor Cyan
Write-Host ""

# Preguntar qué hacer
Write-Host "¿Qué deseas hacer con estos archivos?" -ForegroundColor Yellow
Write-Host "   1. Mover a carpeta de backups (RECOMENDADO)"
Write-Host "   2. Eliminar completamente"
Write-Host "   3. Cancelar"
Write-Host ""
$opcion = Read-Host "Selecciona una opción (1-3)"

if ($opcion -eq "3") {
    Write-Host "Operacion cancelada." -ForegroundColor Red
    exit 0
}

if ($opcion -eq "1") {
    # Mover a backups
    $backupDir = "backups\archivos_obsoletos_$(Get-Date -Format 'yyyy-MM-dd')"
    
    Write-Host ""
    Write-Host "Moviendo archivos a backups..." -ForegroundColor Yellow
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-Host "   Carpeta creada: $backupDir" -ForegroundColor Green
    }
    
    foreach ($archivo in $archivosEncontrados) {
        try {
            Move-Item -Path $archivo -Destination $backupDir -Force
            Write-Host "   Movido: $archivo" -ForegroundColor Green
        } catch {
            Write-Host "   Error al mover $archivo : $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Archivos movidos a: $backupDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "Si necesitas recuperarlos mas tarde, estan en:" -ForegroundColor Cyan
    Write-Host "   $backupDir" -ForegroundColor Gray
    
} elseif ($opcion -eq "2") {
    # Eliminar completamente
    Write-Host ""
    Write-Host "ADVERTENCIA: Estas a punto de ELIMINAR estos archivos permanentemente." -ForegroundColor Red
    Write-Host ""
    $confirmar = Read-Host "Estas seguro? Escribe 'SI' para confirmar"
    
    if ($confirmar -eq "SI") {
        Write-Host ""
        Write-Host "Eliminando archivos..." -ForegroundColor Yellow
        
        foreach ($archivo in $archivosEncontrados) {
            try {
                Remove-Item -Path $archivo -Force
                Write-Host "   Eliminado: $archivo" -ForegroundColor Green
            } catch {
                Write-Host "   Error al eliminar $archivo : $_" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Archivos eliminados permanentemente." -ForegroundColor Green
    } else {
        Write-Host "Operacion cancelada." -ForegroundColor Red
    }
} else {
    Write-Host "Opcion invalida." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Proceso completado" -ForegroundColor Green
Write-Host ""
