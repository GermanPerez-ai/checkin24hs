# Script simple para eliminar emojis usando reemplazos directos
$filePath = "dashboard.html"
$content = Get-Content $filePath -Raw -Encoding UTF8

# Reemplazar emojis específicos
$content = $content -replace '✅', ''
$content = $content -replace '🎫', ''
$content = $content -replace '🤖', ''
$content = $content -replace '💾', ''
$content = $content -replace '👋', ''
$content = $content -replace '🙏', ''

# Guardar
$content | Set-Content $filePath -Encoding UTF8 -NoNewline
Write-Host "Emojis eliminados"

