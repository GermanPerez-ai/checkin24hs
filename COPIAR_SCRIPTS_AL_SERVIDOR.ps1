# Script para copiar SCRIPTS_WHATSAPP_SERVIDOR.sh al servidor
# Ajusta las variables según tu configuración

$Servidor = "srv1152402"  # Cambia por tu servidor o IP
$Usuario = "root"          # Cambia si usas otro usuario
$RutaLocal = "SCRIPTS_WHATSAPP_SERVIDOR.sh"
$RutaRemota = "~/SCRIPTS_WHATSAPP_SERVIDOR.sh"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📤 COPIANDO SCRIPTS AL SERVIDOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $RutaLocal)) {
    Write-Host "❌ Error: No se encuentra el archivo $RutaLocal" -ForegroundColor Red
    Write-Host "   Asegúrate de estar en el directorio correcto" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Archivo local: $RutaLocal" -ForegroundColor Green
Write-Host "📋 Destino remoto: ${Usuario}@${Servidor}:${RutaRemota}" -ForegroundColor Green
Write-Host ""

# Copiar usando SCP
Write-Host "🔄 Copiando archivo..." -ForegroundColor Yellow
scp $RutaLocal "${Usuario}@${Servidor}:${RutaRemota}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Archivo copiado exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Ahora en el servidor ejecuta:" -ForegroundColor Cyan
    Write-Host "   chmod +x SCRIPTS_WHATSAPP_SERVIDOR.sh" -ForegroundColor White
    Write-Host "   bash SCRIPTS_WHATSAPP_SERVIDOR.sh" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al copiar el archivo" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Alternativa manual:" -ForegroundColor Yellow
    Write-Host "   1. Abre el archivo SCRIPTS_WHATSAPP_SERVIDOR.sh" -ForegroundColor White
    Write-Host "   2. Copia todo su contenido" -ForegroundColor White
    Write-Host "   3. En el servidor ejecuta: nano ~/SCRIPTS_WHATSAPP_SERVIDOR.sh" -ForegroundColor White
    Write-Host "   4. Pega el contenido y guarda (Ctrl+O, Enter, Ctrl+X)" -ForegroundColor White
    Write-Host "   5. Ejecuta: chmod +x ~/SCRIPTS_WHATSAPP_SERVIDOR.sh" -ForegroundColor White
    Write-Host ""
}
