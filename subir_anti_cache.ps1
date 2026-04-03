# Script para subir archivos anti-caché al servidor
# Ejecutar desde PowerShell en: C:\Users\German\Downloads\Checkin24hs

Write-Host "=== SUBIR ARCHIVOS ANTI-CACHÉ ===" -ForegroundColor Green
Write-Host ""

# Verificar que los archivos existen
if (-not (Test-Path "server.js")) {
    Write-Host "ERROR: No se encuentra server.js" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "APLICAR_ANTI_CACHE_COMPLETO.sh")) {
    Write-Host "ERROR: No se encuentra APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor Red
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
Write-Host "  - server.js" -ForegroundColor White
Write-Host "  - APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
Write-Host ""

Write-Host "Subiendo archivos al servidor..." -ForegroundColor Yellow
scp server.js APLICAR_ANTI_CACHE_COMPLETO.sh root@72.61.58.240:/root/checkin24hs/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ARCHIVOS SUBIDOS EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta estos comandos en SSH:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host "bash APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al subir los archivos" -ForegroundColor Red
}


Write-Host "=== SUBIR ARCHIVOS ANTI-CACHÉ ===" -ForegroundColor Green
Write-Host ""

# Verificar que los archivos existen
if (-not (Test-Path "server.js")) {
    Write-Host "ERROR: No se encuentra server.js" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "APLICAR_ANTI_CACHE_COMPLETO.sh")) {
    Write-Host "ERROR: No se encuentra APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor Red
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
Write-Host "  - server.js" -ForegroundColor White
Write-Host "  - APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
Write-Host ""

Write-Host "Subiendo archivos al servidor..." -ForegroundColor Yellow
scp server.js APLICAR_ANTI_CACHE_COMPLETO.sh root@72.61.58.240:/root/checkin24hs/




Write-Host "=== SUBIR ARCHIVOS ANTI-CACHÉ ===" -ForegroundColor Green
Write-Host ""

# Verificar que los archivos existen
if (-not (Test-Path "server.js")) {
    Write-Host "ERROR: No se encuentra server.js" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "APLICAR_ANTI_CACHE_COMPLETO.sh")) {
    Write-Host "ERROR: No se encuentra APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor Red
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
Write-Host "  - server.js" -ForegroundColor White
Write-Host "  - APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
Write-Host ""

Write-Host "Subiendo archivos al servidor..." -ForegroundColor Yellow
scp server.js APLICAR_ANTI_CACHE_COMPLETO.sh root@72.61.58.240:/root/checkin24hs/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ARCHIVOS SUBIDOS EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta estos comandos en SSH:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "cd /root/checkin24hs" -ForegroundColor White
    Write-Host "bash APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al subir los archivos" -ForegroundColor Red
}


Write-Host "=== SUBIR ARCHIVOS ANTI-CACHÉ ===" -ForegroundColor Green
Write-Host ""

# Verificar que los archivos existen
if (-not (Test-Path "server.js")) {
    Write-Host "ERROR: No se encuentra server.js" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "APLICAR_ANTI_CACHE_COMPLETO.sh")) {
    Write-Host "ERROR: No se encuentra APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor Red
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
Write-Host "  - server.js" -ForegroundColor White
Write-Host "  - APLICAR_ANTI_CACHE_COMPLETO.sh" -ForegroundColor White
Write-Host ""

Write-Host "Subiendo archivos al servidor..." -ForegroundColor Yellow
scp server.js APLICAR_ANTI_CACHE_COMPLETO.sh root@72.61.58.240:/root/checkin24hs/





