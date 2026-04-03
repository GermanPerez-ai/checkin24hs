# Script para limpiar archivos temporales y scripts que ya no se necesitan
# Mantiene solo los archivos importantes del proyecto

Write-Host "=== LIMPIEZA DE ARCHIVOS TEMPORALES ===" -ForegroundColor Green
Write-Host ""

# Crear carpeta para archivos a eliminar (por seguridad)
$backupDir = "archivos_temporales_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "Carpeta de respaldo creada: $backupDir" -ForegroundColor Yellow
Write-Host ""

# Contador
$contador = 0

# Patrones de archivos a eliminar
$patrones = @(
    # Scripts temporales de corrección
    "APLICAR_*.sh",
    "APLICAR_*.ps1",
    "CORREGIR_*.sh",
    "VERIFICAR_*.sh",
    "SOLUCION_*.sh",
    "SOLUCIONAR_*.sh",
    "DIAGNOSTICO_*.sh",
    "DIAGNOSTICAR_*.sh",
    "FORZAR_*.sh",
    "BORRAR_*.sh",
    "LIMPIAR_*.sh",
    "RESTAURAR_*.sh",
    "RESTAURAR_*.ps1",
    
    # Documentación de troubleshooting específica
    "SOLUCION_*.md",
    "SOLUCIONAR_*.md",
    "DIAGNOSTICO_*.md",
    "DIAGNOSTICAR_*.md",
    "CORRECCION_*.md",
    "CORREGIR_*.md",
    "VERIFICAR_*.md",
    "APLICAR_*.md",
    "RESUMEN_*.md",
    "INSTRUCCIONES_*.md",
    "GUIA_*.md",
    "COMO_*.md",
    "PASO_*.md",
    "COMANDOS_*.txt",
    "COMANDO_*.txt",
    "EJECUTAR_*.txt",
    
    # Archivos temporales
    "*.backup.*",
    "~$*",
    "FRAGMENTO_*.txt",
    "TEST_*.html",
    "TEST_*.js",
    "TEST_*.md",
    
    # Scripts específicos de troubleshooting
    "buscar_y_corregir_*.sh",
    "corregir_*.sh",
    "arreglar_*.sh",
    "diagnosticar_*.sh",
    "verificar_*.sh",
    "aplicar_*.sh",
    "subir_*.ps1",
    "eliminar_*.ps1",
    "limpiar_*.ps1"
)

Write-Host "Buscando archivos temporales..." -ForegroundColor Yellow
Write-Host ""

foreach ($patron in $patrones) {
    $archivos = Get-ChildItem -Path . -Filter $patron -File -ErrorAction SilentlyContinue
    foreach ($archivo in $archivos) {
        # Excluir este mismo script y archivos importantes
        if ($archivo.Name -ne "LIMPIAR_ARCHIVOS_TEMPORALES.ps1" -and 
            $archivo.Name -notlike "*README*" -and
            $archivo.Name -notlike "*LICENSE*" -and
            $archivo.Name -notlike "*AUTHORS*" -and
            $archivo.Name -notlike "*COPYRIGHT*") {
            
            Move-Item -Path $archivo.FullName -Destination $backupDir -Force
            $contador++
            Write-Host "  Movido: $($archivo.Name)" -ForegroundColor Gray
        }
    }
}

# Eliminar archivos .zip temporales
$zips = Get-ChildItem -Path . -Filter "*-deploy.zip" -File -ErrorAction SilentlyContinue
foreach ($zip in $zips) {
    Move-Item -Path $zip.FullName -Destination $backupDir -Force
    $contador++
    Write-Host "  Movido: $($zip.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Green
Write-Host "Archivos movidos a '$backupDir': $contador" -ForegroundColor Yellow
Write-Host ""
Write-Host "ARCHIVOS IMPORTANTES MANTENIDOS:" -ForegroundColor Cyan
Write-Host "  - deploy/dashboard.html" -ForegroundColor White
Write-Host "  - deploy/crm.html, deploy/crm.js" -ForegroundColor White
Write-Host "  - README.md, LICENSE, etc." -ForegroundColor White
Write-Host ""
Write-Host "Si todo funciona bien, puedes eliminar la carpeta '$backupDir' después de verificar." -ForegroundColor Yellow
Write-Host "Si necesitas recuperar algo, está en esa carpeta." -ForegroundColor Yellow

