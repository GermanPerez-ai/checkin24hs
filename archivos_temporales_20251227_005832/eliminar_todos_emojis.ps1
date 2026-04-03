# Script para eliminar TODOS los emojis de console.log en dashboard.html

$filePath = "dashboard.html"
$backupPath = "dashboard.html.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Crear backup
Copy-Item $filePath $backupPath
Write-Host "Backup creado: $backupPath" -ForegroundColor Green

# Leer el archivo línea por línea
$lines = Get-Content $filePath -Encoding UTF8
$newLines = @()

foreach ($line in $lines) {
    # Si la línea contiene console.log/error/warn/info, eliminar emojis
    if ($line -match 'console\.(log|error|warn|info)') {
        # Eliminar emojis comunes
        $line = $line -replace '[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁✏️🗑️🖼️👁️⚙️⏭️ℹ️]', ''
    }
    $newLines += $line
}

# Guardar el archivo
$newLines | Set-Content -Path $filePath -Encoding UTF8

Write-Host "Todos los emojis eliminados de console.log" -ForegroundColor Green
Write-Host "Archivo actualizado: $filePath" -ForegroundColor Green


