# Script para corregir problemas de gastos y eliminar gráficos

$file = "dashboard.html"
$content = Get-Content $file -Raw -Encoding UTF8

# 1. Hacer addNewExpense disponible globalmente
if ($content -notmatch "window\.addNewExpense = addNewExpense") {
    $content = $content -replace "(document\.getElementById\('expenseModal'\)\.style\.display = 'block';\s*\})", "`$1`n        `n        // Hacer disponible globalmente`n        window.addNewExpense = addNewExpense;"
}

# 2. Eliminar HTML de gráficos (líneas 4146-4187 aproximadamente)
$pattern = '(?s)<!-- Grid de Gr.*?Tabla -->.*?<div class="dashboard-grid">.*?<!-- Gr.*?fico de Composici.*?n de Gastos.*?</div>.*?<!-- Gr.*?fico de Desglose de Gastos Variables.*?</div>.*?</div>.*?<!-- Gr.*?fico de Gasto vs Presupuesto.*?</div>.*?<!-- Tabla de Gastos -->'
$content = $content -replace $pattern, '<!-- Tabla de Gastos -->'

# 3. Eliminar funciones de gráficos
$pattern2 = '(?s)// Gr.*?fico de composici.*?n \(Pie Chart\).*?function updateCompositionChart.*?\}\s*// Gr.*?fico de gastos variables.*?function updateVariableExpensesChart.*?\}\s*// Gr.*?fico de Gasto vs Presupuesto.*?function updateBudgetChart.*?\}'
$content = $content -replace $pattern2, '// Funciones de gráficos eliminadas - ya no se usan'

# 4. Corregir caracteres mal codificados en comentarios
$content = $content -replace 'categoras', 'categorías'
$content = $content -replace 'perodo', 'período'
$content = $content -replace 'Adquisicin', 'Adquisición'

# Guardar archivo
Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8

Write-Host "Correcciones aplicadas:" -ForegroundColor Green
Write-Host "1. addNewExpense disponible globalmente" -ForegroundColor Cyan
Write-Host "2. Gráficos HTML eliminados" -ForegroundColor Cyan
Write-Host "3. Funciones de gráficos eliminadas" -ForegroundColor Cyan
Write-Host "4. Caracteres corregidos" -ForegroundColor Cyan
