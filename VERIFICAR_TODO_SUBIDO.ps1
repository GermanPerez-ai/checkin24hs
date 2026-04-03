# Script completo para verificar que todo está subido correctamente
$server = "root@72.61.58.240"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICACION COMPLETA DE ARCHIVOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$errores = 0
$exitos = 0

# 1. Verificar archivo principal
Write-Host "1. Verificando flor-ai-service.js..." -ForegroundColor Yellow
$result1 = ssh $server "if [ -f /root/checkin24hs/flor-ai-service.js ]; then echo 'EXISTE'; grep -n 'TU MISION PRINCIPAL' /root/checkin24hs/flor-ai-service.js | head -1; else echo 'NO_EXISTE'; fi" 2>&1

if ($result1 -match "EXISTE" -and $result1 -match "TU MISION PRINCIPAL") {
    Write-Host "   OK: Archivo existe y contiene mejoras" -ForegroundColor Green
    $linea = ($result1 | Select-String "TU MISION PRINCIPAL").ToString()
    Write-Host "   Linea encontrada: $linea" -ForegroundColor Gray
    $exitos++
} else {
    Write-Host "   ERROR: Archivo no existe o no tiene mejoras" -ForegroundColor Red
    $errores++
}

Write-Host ""

# 2. Verificar archivo de deploy
Write-Host "2. Verificando deploy/flor-ai-service.js..." -ForegroundColor Yellow
$result2 = ssh $server "if [ -f /root/checkin24hs/deploy/flor-ai-service.js ]; then echo 'EXISTE'; grep -n 'TU MISION PRINCIPAL' /root/checkin24hs/deploy/flor-ai-service.js | head -1; else echo 'NO_EXISTE'; fi" 2>&1

if ($result2 -match "EXISTE" -and $result2 -match "TU MISION PRINCIPAL") {
    Write-Host "   OK: Archivo existe y contiene mejoras" -ForegroundColor Green
    $linea = ($result2 | Select-String "TU MISION PRINCIPAL").ToString()
    Write-Host "   Linea encontrada: $linea" -ForegroundColor Gray
    $exitos++
} else {
    Write-Host "   ERROR: Archivo no existe o no tiene mejoras" -ForegroundColor Red
    $errores++
}

Write-Host ""

# 3. Verificar tamaño de archivos (deben ser similares)
Write-Host "3. Verificando tamaños de archivos..." -ForegroundColor Yellow
$size1 = ssh $server "ls -lh /root/checkin24hs/flor-ai-service.js 2>/dev/null | awk '{print `$5}'" 2>&1
$size2 = ssh $server "ls -lh /root/checkin24hs/deploy/flor-ai-service.js 2>/dev/null | awk '{print `$5}'" 2>&1

if ($size1 -and $size2) {
    Write-Host "   Tamaño archivo principal: $size1" -ForegroundColor Gray
    Write-Host "   Tamaño archivo deploy: $size2" -ForegroundColor Gray
    if ($size1 -eq $size2) {
        Write-Host "   OK: Tamaños coinciden" -ForegroundColor Green
        $exitos++
    } else {
        Write-Host "   ADVERTENCIA: Tamaños diferentes (puede ser normal)" -ForegroundColor Yellow
        $exitos++
    }
} else {
    Write-Host "   ERROR: No se pudieron obtener los tamaños" -ForegroundColor Red
    $errores++
}

Write-Host ""

# 4. Verificar que el servicio esté corriendo
Write-Host "4. Verificando servicio de WhatsApp..." -ForegroundColor Yellow
$container = ssh $server "docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1" 2>&1

if ($container -and $container -notmatch "error|Error|ERROR") {
    Write-Host "   OK: Contenedor activo: $container" -ForegroundColor Green
    $status = ssh $server "docker ps --filter 'name=whatsapp.1' --format '{{.Status}}' | head -1" 2>&1
    Write-Host "   Estado: $status" -ForegroundColor Gray
    $exitos++
} else {
    Write-Host "   ERROR: Contenedor no encontrado o no está corriendo" -ForegroundColor Red
    $errores++
}

Write-Host ""

# 5. Verificar que los archivos locales existen
Write-Host "5. Verificando archivos locales..." -ForegroundColor Yellow
if (Test-Path "flor-ai-service.js") {
    $localSize1 = (Get-Item "flor-ai-service.js").Length
    Write-Host "   OK: flor-ai-service.js existe localmente ($localSize1 bytes)" -ForegroundColor Green
    $exitos++
} else {
    Write-Host "   ADVERTENCIA: flor-ai-service.js no existe localmente" -ForegroundColor Yellow
}

if (Test-Path "deploy\flor-ai-service.js") {
    $localSize2 = (Get-Item "deploy\flor-ai-service.js").Length
    Write-Host "   OK: deploy\flor-ai-service.js existe localmente ($localSize2 bytes)" -ForegroundColor Green
    $exitos++
} else {
    Write-Host "   ADVERTENCIA: deploy\flor-ai-service.js no existe localmente" -ForegroundColor Yellow
}

Write-Host ""

# 6. Verificar mejoras específicas en el código
Write-Host "6. Verificando mejoras específicas en el codigo..." -ForegroundColor Yellow
$mejoras = @(
    "TU MISION PRINCIPAL",
    "EDUCACION Y UTILIDAD",
    "Tecnicas de Ensenanza",
    "Explica el"
)

$mejorasEncontradas = 0
foreach ($mejora in $mejoras) {
    $check = ssh $server "grep -c '$mejora' /root/checkin24hs/flor-ai-service.js 2>/dev/null" 2>&1
    if ($check -match "^\d+$" -and [int]$check -gt 0) {
        Write-Host "   OK: '$mejora' encontrada" -ForegroundColor Green
        $mejorasEncontradas++
    } else {
        Write-Host "   ADVERTENCIA: '$mejora' no encontrada" -ForegroundColor Yellow
    }
}

if ($mejorasEncontradas -eq $mejoras.Count) {
    Write-Host "   OK: Todas las mejoras están presentes" -ForegroundColor Green
    $exitos++
} else {
    Write-Host "   ADVERTENCIA: Algunas mejoras no se encontraron" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE VERIFICACION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Verificaciones exitosas: $exitos" -ForegroundColor Green
if ($errores -gt 0) {
    Write-Host "Errores encontrados: $errores" -ForegroundColor Red
} else {
    Write-Host "Errores encontrados: 0" -ForegroundColor Green
}

Write-Host ""
if ($errores -eq 0) {
    Write-Host "TODO ESTA CORRECTO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Configura la API Key de Gemini en el dashboard" -ForegroundColor White
    Write-Host "2. Prueba enviando un mensaje por WhatsApp" -ForegroundColor White
} else {
    Write-Host "HAY ERRORES QUE CORREGIR" -ForegroundColor Red
    Write-Host ""
    Write-Host "Revisa los errores arriba y vuelve a subir los archivos si es necesario" -ForegroundColor Yellow
}

Write-Host ""

