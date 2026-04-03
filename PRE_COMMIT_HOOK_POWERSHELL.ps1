# Versión alternativa del pre-commit hook en PowerShell puro
# Si el hook bash no funciona, reemplaza .git/hooks/pre-commit con este contenido
# Pero renómbralo a: .git/hooks/pre-commit.ps1 y configura Git para usarlo

# Verificar si dashboard.html está en el staging area
$stagedFiles = git diff --cached --name-only

if ($stagedFiles -contains "dashboard.html") {
    Write-Host "🔢 Incrementando build number automáticamente..." -ForegroundColor Cyan
    
    $DASHBOARD_PATH = "dashboard.html"
    
    if (-not (Test-Path $DASHBOARD_PATH)) {
        Write-Host "⚠️  dashboard.html no encontrado, saltando incremento" -ForegroundColor Yellow
        exit 0
    }
    
    # Leer archivo
    $content = Get-Content $DASHBOARD_PATH -Raw -Encoding UTF8
    
    # Obtener build number actual
    if ($content -match "window\.DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)") {
        $currentBuild = [int]$matches[1]
        $newBuild = $currentBuild + 1
        Write-Host "Build: $currentBuild -> $newBuild" -ForegroundColor Green
    } else {
        $newBuild = 1
        Write-Host "Primer build: $newBuild" -ForegroundColor Green
    }
    
    # Generar timestamp actual
    $currentTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    # Actualizar build number
    $content = $content -replace "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+", "window.DASHBOARD_BUILD_NUMBER = $newBuild"
    
    # Actualizar build timestamp
    $content = $content -replace "window\.DASHBOARD_BUILD\s*=\s*'[^']+'", "window.DASHBOARD_BUILD = '$currentTimestamp'"
    
    # Guardar archivo
    Set-Content -Path $DASHBOARD_PATH -Value $content -Encoding UTF8 -NoNewline
    
    # Re-agregar al staging
    git add $DASHBOARD_PATH
    
    Write-Host "✅ Build incrementado a #$newBuild" -ForegroundColor Green
}

exit 0
