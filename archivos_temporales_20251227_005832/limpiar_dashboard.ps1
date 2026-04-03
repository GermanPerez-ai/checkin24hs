# Script para limpiar dashboard.html: eliminar emojis y definiciones duplicadas de showSection

$filePath = "dashboard.html"
$content = Get-Content $filePath -Raw -Encoding UTF8

Write-Host "Limpiando emojis de console.log y alert..."

# Eliminar emojis usando expresiones regulares Unicode
# Patrón para encontrar emojis comunes en JavaScript
$emojiPatterns = @(
    '[\u{1F3AB}]',  # 🎫
    '[\u{1F916}]',  # 🤖
    '[\u{2705}]',   # ✅
    '[\u{1F4BE}]',  # 💾
    '[\u{1F44B}]',  # 👋
    '[\u{1F64F}]'   # 🙏
)

foreach ($pattern in $emojiPatterns) {
    # Eliminar emojis de console.log
    $content = $content -replace "console\.log\(([^)]*)$pattern([^)]*)\)", 'console.log($1$2)'
    $content = $content -replace "console\.log\(`([^`]*)$pattern([^`]*)`\)", 'console.log(`$1$2`)'
    # Eliminar emojis de alert
    $content = $content -replace "alert\(([^)]*)$pattern([^)]*)\)", 'alert($1$2)'
    $content = $content -replace "alert\(`([^`]*)$pattern([^`]*)`\)", 'alert(`$1$2`)'
}

# Eliminar emojis sueltos en el contenido (más agresivo)
$content = $content -replace '[\u{1F3AB}\u{1F916}\u{2705}\u{1F4BE}\u{1F44B}\u{1F64F}]', ''

Write-Host "Eliminando definiciones duplicadas de window.showSection..."

# Dividir en líneas para procesar
$lines = $content -split "`r?`n"
$cleanedLines = @()
$inHead = $false
$firstShowSectionFound = $false
$skipBlock = $false
$braceCount = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # Detectar inicio y fin del head
    if ($line -match '<head>') {
        $inHead = $true
    }
    if ($line -match '</head>') {
        $inHead = $false
    }
    
    # Detectar primera definición de showSection en el head (líneas 6-19)
    if ($inHead -and $line -match 'window\.showSection\s*=\s*function' -and -not $firstShowSectionFound) {
        $firstShowSectionFound = $true
        $cleanedLines += $line
        continue
    }
    
    # Saltar otras definiciones de showSection
    if ($line -match 'window\.showSection\s*=\s*function' -and $firstShowSectionFound) {
        $skipBlock = $true
        $braceCount = 0
        continue
    }
    
    # Si estamos en un bloque que debemos saltar, contar llaves
    if ($skipBlock) {
        $openBraces = ([regex]::Matches($line, '\{')).Count
        $closeBraces = ([regex]::Matches($line, '\}')).Count
        $braceCount += $openBraces - $closeBraces
        
        # Si las llaves están balanceadas, terminar de saltar
        if ($braceCount -le 0) {
            $skipBlock = $false
            $braceCount = 0
        }
        continue
    }
    
    # Saltar líneas de console.log que mencionen showSection definida
    if ($line -match "console\.log\('showSection definida") {
        continue
    }
    
    $cleanedLines += $line
}

$cleanedContent = $cleanedLines -join "`n"

# Guardar el archivo limpio
$cleanedContent | Set-Content $filePath -Encoding UTF8 -NoNewline

Write-Host "Dashboard limpiado exitosamente!"
Write-Host "- Emojis eliminados"
Write-Host "- Definiciones duplicadas de showSection removidas"
