# Script para crear el archivo .env
# Ejecuta este script: .\crear_env.ps1

$envContent = @"
GEMINI_API_KEY=tu_api_key_de_gemini_aquí
GEMINI_MODEL=gemini-2.5-flash
"@

$envPath = Join-Path $PSScriptRoot ".env"

# Verificar si el archivo ya existe
if (Test-Path $envPath) {
    Write-Host "⚠️ El archivo .env ya existe en: $envPath" -ForegroundColor Yellow
    $overwrite = Read-Host "¿Deseas sobrescribirlo? (S/N)"
    if ($overwrite -ne "S" -and $overwrite -ne "s") {
        Write-Host "❌ Operación cancelada." -ForegroundColor Red
        exit
    }
}

# Crear el archivo
try {
    $envContent | Out-File -FilePath $envPath -Encoding utf8 -NoNewline
    Write-Host "✅ Archivo .env creado exitosamente en: $envPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️ IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "   Ahora debes editar el archivo .env y reemplazar 'tu_api_key_de_gemini_aquí'"
    Write-Host "   con tu API Key real de Gemini." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Puedes obtener tu API Key en: https://makersuite.google.com/app/apikey" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error al crear el archivo: $_" -ForegroundColor Red
}
