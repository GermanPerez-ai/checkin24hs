# Script para eliminar emojis de console.log en dashboard.html

$filePath = "dashboard.html"
$backupPath = "dashboard.html.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Crear backup
Copy-Item $filePath $backupPath
Write-Host "Backup creado: $backupPath" -ForegroundColor Green

# Leer el archivo
$content = Get-Content $filePath -Raw -Encoding UTF8

# Eliminar emojis comunes de console.log usando expresiones regulares
# Patrón: buscar console.log seguido de cualquier texto que contenga emojis
$patterns = @(
    "console\.log\('([^']*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^']*)'\)",
    'console\.log\("([^"]*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^"]*)"\)',
    "console\.log\(`([^`]*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^`]*)`\)",
    "console\.error\('([^']*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^']*)'\)",
    'console\.error\("([^"]*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^"]*)"\)',
    "console\.warn\('([^']*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^']*)'\)",
    'console\.warn\("([^"]*)[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]([^"]*)"\)'
)

# Reemplazar cada patrón eliminando el emoji
foreach ($pattern in $patterns) {
    $content = $content -replace $pattern, {
        param($match)
        $match.Value -replace '[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]', ''
    }
}

# También eliminar emojis sueltos en console.log usando un enfoque más simple
# Buscar líneas que contengan console.log y emojis, y eliminar los emojis
$lines = $content -split "`n"
$newLines = @()
foreach ($line in $lines) {
    if ($line -match 'console\.(log|error|warn|info)') {
        $line = $line -replace '[🎫🤖✅💾🔄📊☁️⚠️❌🔐📁]', ''
    }
    $newLines += $line
}
$content = $newLines -join "`n"

# Guardar el archivo
Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Emojis eliminados de console.log" -ForegroundColor Green
Write-Host "Archivo actualizado: $filePath" -ForegroundColor Green
