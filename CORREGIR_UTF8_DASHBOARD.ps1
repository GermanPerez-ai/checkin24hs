# Script para corregir caracteres especiales en dashboard.html
$filePath = "dashboard.html"

if (Test-Path $filePath) {
    Write-Host "Leyendo archivo..."
    $content = Get-Content $filePath -Raw -Encoding UTF8
    
    Write-Host "Corrigiendo caracteres especiales..."
    
    # Reemplazar caracteres problemáticos comunes
    $content = $content -replace 'VERSI\?N', 'VERSIÓN'
    $content = $content -replace 'CR\?TICO', 'CRÍTICO'
    $content = $content -replace 'versi\?n', 'versión'
    $content = $content -replace 'autom\?ticamente', 'automáticamente'
    $content = $content -replace 'configuraci\?n', 'configuración'
    $content = $content -replace 'verificaci\?n', 'verificación'
    $content = $content -replace 'c\?digo', 'código'
    $content = $content -replace 'C\?DIGO', 'CÓDIGO'
    $content = $content -replace 'actualizaci\?n', 'actualización'
    $content = $content -replace 'informaci\?n', 'información'
    $content = $content -replace 'aplicaci\?n', 'aplicación'
    $content = $content -replace 'operaci\?n', 'operación'
    $content = $content -replace 'configuraci\?n', 'configuración'
    $content = $content -replace 'autenticaci\?n', 'autenticación'
    $content = $content -replace 'sincronizaci\?n', 'sincronización'
    $content = $content -replace 'administraci\?n', 'administración'
    $content = $content -replace 'cotizaci\?n', 'cotización'
    $content = $content -replace 'Cotizaci\?n', 'Cotización'
    $content = $content -replace 'cotizaciones', 'cotizaciones'
    $content = $content -replace 'Cotizaciones', 'Cotizaciones'
    
    Write-Host "Guardando archivo con codificación UTF-8..."
    [System.IO.File]::WriteAllText((Resolve-Path $filePath), $content, [System.Text.Encoding]::UTF8)
    
    Write-Host "✅ Archivo corregido y guardado como UTF-8"
} else {
    Write-Host "❌ Archivo no encontrado: $filePath"
}
