# Verifica si la web en producción (www.checkin24hs.com) tiene los cambios de Flor estilo WhatsApp.
# Uso: .\scripts\verificar_flor_web_servidor.ps1
# O: .\scripts\verificar_flor_web_servidor.ps1 -BaseUrl "https://www.checkin24hs.com"

param([string]$BaseUrl = "https://www.checkin24hs.com")

$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== Verificando Flor en: $BaseUrl ===" -ForegroundColor Cyan

$fail = 0

# flor-ai-service.js
try {
    $js = (Invoke-WebRequest -Uri "$BaseUrl/flor-ai-service.js" -UseBasicParsing).Content
    if ($js -match "FLOR_REGLAS_PRIORIDAD") { Write-Host "  flor-ai-service.js FLOR_REGLAS_PRIORIDAD: OK" -ForegroundColor Green }
    else { Write-Host "  flor-ai-service.js FLOR_REGLAS_PRIORIDAD: NO ENCONTRADO" -ForegroundColor Red; $fail++ }
    if ($js -match "buildHotelsBlockWhatsAppStyle") { Write-Host "  buildHotelsBlockWhatsAppStyle: OK" -ForegroundColor Green }
    else { Write-Host "  buildHotelsBlockWhatsAppStyle: NO ENCONTRADO" -ForegroundColor Red; $fail++ }
} catch {
    Write-Host "  No se pudo descargar flor-ai-service.js" -ForegroundColor Red
    $fail++
}

# flor-knowledge-base.js
try {
    $kb = (Invoke-WebRequest -Uri "$BaseUrl/flor-knowledge-base.js" -UseBasicParsing).Content
    if ($kb -match "promptGeneral") { Write-Host "  flor-knowledge-base.js promptGeneral: OK" -ForegroundColor Green }
    else { Write-Host "  flor-knowledge-base.js promptGeneral: NO ENCONTRADO" -ForegroundColor Red; $fail++ }
    if ($kb -match "flor_info") { Write-Host "  flor_info: OK" -ForegroundColor Green }
    else { Write-Host "  flor_info: NO ENCONTRADO" -ForegroundColor Red; $fail++ }
} catch {
    Write-Host "  No se pudo descargar flor-knowledge-base.js" -ForegroundColor Red
    $fail++
}

# flor-chatbot.html
try {
    $html = (Invoke-WebRequest -Uri "$BaseUrl/flor-chatbot.html" -UseBasicParsing).Content
    if ($html -match "florConfigReady") { Write-Host "  flor-chatbot.html florConfigReady: OK" -ForegroundColor Green }
    else { Write-Host "  flor-chatbot.html florConfigReady: NO ENCONTRADO" -ForegroundColor Red; $fail++ }
} catch {
    Write-Host "  No se pudo descargar flor-chatbot.html" -ForegroundColor Red
    $fail++
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "=== La web en el servidor SÍ tiene los cambios de Flor. ===" -ForegroundColor Green
    exit 0
} else {
    Write-Host "=== La web en el servidor NO tiene los cambios. Hay que desplegar. ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Pasos:" -ForegroundColor White
    Write-Host "  1) En tu PC: git add . ; git commit -m 'Flor web igual WhatsApp' ; git push origin main"
    Write-Host "  2) En el servidor (SSH): cd /root/checkin24hs && git pull origin main && bash scripts/deploy_web_servidor.sh"
    Write-Host "  3) Volver a ejecutar: .\scripts\verificar_flor_web_servidor.ps1"
    exit 1
}
