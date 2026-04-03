# Script para corregir problemas de codificación UTF-8 en console.log del dashboard.html
# Usa System.Text.Encoding para manejar correctamente UTF-8

$DASHBOARD_PATH = "deploy\dashboard.html"
$BACKUP_FILE = "deploy\dashboard.html.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "=== Crear backup ===" -ForegroundColor Cyan
Copy-Item $DASHBOARD_PATH $BACKUP_FILE
Write-Host "✅ Backup: $BACKUP_FILE" -ForegroundColor Green
Write-Host ""

Write-Host "=== Corregir codificación UTF-8 en console.log ===" -ForegroundColor Cyan

# Leer el contenido con UTF-8 usando System.Text.Encoding
$utf8 = [System.Text.Encoding]::UTF8
$content = [System.IO.File]::ReadAllText($DASHBOARD_PATH, $utf8)

# Diccionario de correcciones UTF-8 (usando caracteres Unicode directamente)
$correcciones = @(
    @{Pattern='est\?'; Replacement='está'},
    @{Pattern='funci\?n'; Replacement='función'},
    @{Pattern='vac\?o'; Replacement='vacío'},
    @{Pattern='DIAGN\?STICO'; Replacement='DIAGNÓSTICO'},
    @{Pattern='AUTOM\?TICO'; Replacement='AUTOMÁTICO'},
    @{Pattern='\?ltimas'; Replacement='últimas'},
    @{Pattern='estad\?sticas'; Replacement='estadísticas'},
    @{Pattern='D\?a'; Replacement='Día'},
    @{Pattern='\?Coincide'; Replacement='¿Coincide'},
    @{Pattern='c\?digo'; Replacement='código'},
    @{Pattern='nuevo est\?'; Replacement='nuevo está'},
    @{Pattern='es funci\?n'; Replacement='es función'},
    @{Pattern='mensaje vac\?o'; Replacement='mensaje vacío'},
    @{Pattern='Promedio/D\?a'; Replacement='Promedio/Día'},
    @{Pattern='configuraci\?n'; Replacement='configuración'},
    @{Pattern='verificaci\?n'; Replacement='verificación'},
    @{Pattern='autenticaci\?n'; Replacement='autenticación'},
    @{Pattern='reservaci\?n'; Replacement='reservación'},
    @{Pattern='actualizaci\?n'; Replacement='actualización'},
    @{Pattern='eliminaci\?n'; Replacement='eliminación'},
    @{Pattern='creaci\?n'; Replacement='creación'},
    @{Pattern='edici\?n'; Replacement='edición'},
    @{Pattern='selecci\?n'; Replacement='selección'},
    @{Pattern='aplicaci\?n'; Replacement='aplicación'},
    @{Pattern='operaci\?n'; Replacement='operación'},
    @{Pattern='instalaci\?n'; Replacement='instalación'},
    @{Pattern='presentaci\?n'; Replacement='presentación'},
    @{Pattern='preparaci\?n'; Replacement='preparación'},
    @{Pattern='confirmaci\?n'; Replacement='confirmación'},
    @{Pattern='cancelaci\?n'; Replacement='cancelación'},
    @{Pattern='validaci\?n'; Replacement='validación'},
    @{Pattern='generaci\?n'; Replacement='generación'},
    @{Pattern='ejecuci\?n'; Replacement='ejecución'}
)

# Dividir en líneas y procesar solo las que contienen console.log/warn/error
$lineas = $content -split "`n"
$lineasCorregidas = @()

foreach ($linea in $lineas) {
    if ($linea -match "console\.(log|warn|error)") {
        $lineaCorregida = $linea
        foreach ($correccion in $correcciones) {
            $lineaCorregida = $lineaCorregida -replace $correccion.Pattern, $correccion.Replacement
        }
        $lineasCorregidas += $lineaCorregida
    } else {
        $lineasCorregidas += $linea
    }
}

# Unir las líneas corregidas
$contentCorregido = $lineasCorregidas -join "`n"

# Guardar el archivo con UTF-8 usando System.Text.Encoding
[System.IO.File]::WriteAllText($DASHBOARD_PATH, $contentCorregido, $utf8)

Write-Host "✅ Correcciones aplicadas" -ForegroundColor Green
Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "1. Revisa el archivo para verificar las correcciones" -ForegroundColor White
Write-Host "2. Ejecuta ACTUALIZAR_VERSION_Y_SUBIR.ps1 para subir los cambios" -ForegroundColor White
Write-Host ""
