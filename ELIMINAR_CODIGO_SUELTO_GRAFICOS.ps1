# Script para eliminar código suelto de gráficos que causa error de sintaxis

$file = "dashboard.html"
$lines = Get-Content $file -Encoding UTF8

# Encontrar las líneas a eliminar (desde después de updateExpensesCharts hasta antes de "Filtrar gastos")
$startIndex = -1
$endIndex = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "// Gr.*ficos eliminados - funci.*n vac.*a") {
        $startIndex = $i + 1  # Empezar después del cierre de la función
    }
    if ($startIndex -ge 0 -and $lines[$i] -match "// Filtrar gastos") {
        $endIndex = $i - 1  # Terminar antes del comentario "Filtrar gastos"
        break
    }
}

if ($startIndex -ge 0 -and $endIndex -ge $startIndex) {
    Write-Host "Eliminando líneas $startIndex a $endIndex" -ForegroundColor Yellow
    
    # Crear nuevo array sin las líneas problemáticas
    $newLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -lt $startIndex -or $i -gt $endIndex) {
            $newLines += $lines[$i]
        }
    }
    
    # Guardar archivo
    Set-Content -Path $file -Value $newLines -Encoding UTF8
    
    Write-Host "Código suelto eliminado correctamente" -ForegroundColor Green
    Write-Host "Líneas eliminadas: $($endIndex - $startIndex + 1)" -ForegroundColor Cyan
} else {
    Write-Host "No se encontraron las líneas a eliminar" -ForegroundColor Red
    Write-Host "startIndex: $startIndex, endIndex: $endIndex" -ForegroundColor Yellow
}
