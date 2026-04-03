# Script para aplicar logging mejorado de creación de chats
# Esto ayudará a detectar si Supabase está bloqueando la creación

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR LOGGING MEJORADO DE CHATS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Subir archivo al servidor
Write-Host "1. Subiendo archivo al servidor..." -ForegroundColor Yellow
scp $ARCHIVO_LOCAL "${SERVER_USER}@${SERVER_IP}:${ARCHIVO_SERVIDOR}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error subiendo archivo" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

# 2. Conectar y aplicar cambios
Write-Host "2. Aplicando cambios en el servidor..." -ForegroundColor Yellow

# Crear script temporal bash
$scriptBash = @"
#!/bin/bash
# Buscar contenedor
CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1)

if [ -z "`$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: `$CONTAINER_ID"

# Crear backup
BACKUP_FILE="/tmp/whatsapp-server-baileys.js.backup.`$(date +%Y%m%d_%H%M%S)"
docker cp `$CONTAINER_ID:/app/whatsapp-server-baileys.js `$BACKUP_FILE
echo "✅ Backup creado: `$BACKUP_FILE"

# Copiar archivo al contenedor
docker cp $ARCHIVO_SERVIDOR `$CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"

# Verificar que el cambio se aplicó
echo ""
echo "Verificando cambio aplicado..."
docker exec `$CONTAINER_ID grep -A 2 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js | head -5
echo ""

# Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart `$CONTAINER_ID
echo "✅ Contenedor reiniciado"

echo ""
echo "=========================================="
echo "CAMBIO APLICADO"
echo "=========================================="
echo ""
echo "Ahora los logs mostrarán errores detallados al crear chats."
echo "Busca mensajes como:"
echo "  ❌ Error creando chat en whatsapp_chats"
echo "  ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida"
echo ""
"@

# Guardar script temporal
$scriptTemp = [System.IO.Path]::GetTempFileName() + ".sh"
$scriptBash | Out-File -FilePath $scriptTemp -Encoding UTF8 -NoNewline

# Subir script y ejecutar
scp $scriptTemp "${SERVER_USER}@${SERVER_IP}:/tmp/aplicar_logging.sh"
ssh "${SERVER_USER}@${SERVER_IP}" "chmod +x /tmp/aplicar_logging.sh && bash /tmp/aplicar_logging.sh"

# Limpiar archivo temporal
Remove-Item $scriptTemp -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error aplicando cambios" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Cambio aplicado correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora envía un mensaje de prueba y verifica los logs:" -ForegroundColor Yellow
Write-Host "  docker logs \$CONTAINER_ID --tail 50 | grep -E 'Error creando chat|Nuevo chat creado|PROBLEMA.*cuota'" -ForegroundColor Gray
Write-Host ""
