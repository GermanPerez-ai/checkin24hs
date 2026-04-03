# Script para eliminar código restante de gráficos

$file = "dashboard.html"
$content = Get-Content $file -Raw -Encoding UTF8

# Eliminar código de updateExpensesCharts que todavía tiene lógica de gráficos
$pattern = '(?s)// Actualizar gr.*?ficos de gastos\s+function updateExpensesCharts\(\) \{[^}]*?const expenses = JSON\.parse[^}]*?// Funciones de gr.*?ficos eliminadas[^}]*?// Agrupar gastos por per.*?odo[^}]*?const groupedExpenses[^}]*?const now[^}]*?expenses\.forEach[^}]*?const expenseDate[^}]*?let key[^}]*?if \(period === ''monthly''\)[^}]*?key =[^}]*?else if \(period === ''quarterly''\)[^}]*?const quarter[^}]*?key =[^}]*?else[^}]*?key =[^}]*?if \(!groupedExpenses\[key\]\)[^}]*?groupedExpenses\[key\] = 0[^}]*?groupedExpenses\[key\] \+= expense\.amount[^}]*?\}[^}]*?const labels[^}]*?const actualData[^}]*?const budgetValue[^}]*?const budgetData[^}]*?const ctx = document\.getElementById\(''budgetComparisonChart''\)[^}]*?if \(!ctx\) return[^}]*?if \(expensesCharts\.budget\)[^}]*?expensesCharts\.budget\.destroy\(\)[^}]*?expensesCharts\.budget = new Chart\(ctx[^}]*?type: ''line''[^}]*?data: \{[^}]*?labels: labels[^}]*?datasets: \[[^}]*?\{[^}]*?label: ''Gasto Real''[^}]*?data: actualData[^}]*?borderColor[^}]*?backgroundColor[^}]*?tension[^}]*?fill: true[^}]*?\}[^}]*?\{[^}]*?label: ''Presupuesto''[^}]*?data: budgetData[^}]*?borderColor[^}]*?backgroundColor[^}]*?borderDash[^}]*?tension[^}]*?fill: true[^}]*?\}[^}]*?\][^}]*?\}[^}]*?options: \{[^}]*?responsive[^}]*?maintainAspectRatio[^}]*?plugins: \{[^}]*?tooltip: \{[^}]*?callbacks: \{[^}]*?label: function\(context\)[^}]*?return[^}]*?\}[^}]*?\}[^}]*?\}[^}]*?scales: \{[^}]*?y: \{[^}]*?beginAtZero[^}]*?ticks: \{[^}]*?callback: function\(value\)[^}]*?return[^}]*?\}[^}]*?\}[^}]*?\}[^}]*?\}[^}]*?\}[^}]*?\}[^}]*?\}'

# Simplificar: buscar desde updateExpensesCharts hasta el siguiente comentario o función
$pattern2 = '(?s)(// Actualizar gr.*?ficos de gastos\s+function updateExpensesCharts\(\) \{.*?)(?=\s+// Filtrar gastos|\s+function \w+\(|\s+// [A-Z])'

$replacement = '// Actualizar gráficos de gastos (gráficos eliminados)
        function updateExpensesCharts() {
            // Gráficos eliminados - función vacía
        }'

$content = $content -replace $pattern2, $replacement

# Guardar
Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8

Write-Host "Código de gráficos eliminado" -ForegroundColor Green
