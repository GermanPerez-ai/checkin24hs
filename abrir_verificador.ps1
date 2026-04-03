# Script PowerShell para abrir el verificador en Chrome
Write-Host "Abrindo verificador de servidores WhatsApp..." -ForegroundColor Cyan
Write-Host ""

$archivo = Join-Path $PSScriptRoot "verificar_servidores_whatsapp.html"
$url = "file:///$($archivo.Replace('\', '/'))"

# Intentar encontrar Chrome
$chromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)

$chromeFound = $false
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        Write-Host "Abriendo con Chrome: $path" -ForegroundColor Green
        Start-Process $path $url
        $chromeFound = $true
        break
    }
}

if (-not $chromeFound) {
    Write-Host "Chrome no encontrado. Abriendo con el navegador predeterminado..." -ForegroundColor Yellow
    Start-Process $archivo
}

Write-Host ""
Write-Host "NOTA: Si ves errores de CORS:" -ForegroundColor Yellow
Write-Host "  1. Instala un servidor local: python -m http.server 8000" -ForegroundColor White
Write-Host "  2. Abre: http://localhost:8000/verificar_servidores_whatsapp.html" -ForegroundColor White
Write-Host ""
