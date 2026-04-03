# Script para aplicar mejor logging de actualización de chats
# Esto ayudará a detectar si Supabase está bloqueando las actualizaciones

$SERVER_IP = "72.61.58.240"
$SERVER_USER = "root"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"
$ARCHIVO_BACKUP = "/tmp/whatsapp-server-baileys.js.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR MEJOR LOGGING DE CHATS" -ForegroundColor Cyan
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
ssh "${SERVER_USER}@${SERVER_IP}" @"
# Buscar contenedor
CONTAINER_ID=\$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: \$CONTAINER_ID"

# Crear backup
echo "Creando backup..."
docker cp \$CONTAINER_ID:/app/whatsapp-server-baileys.js $ARCHIVO_BACKUP
echo "✅ Backup creado: $ARCHIVO_BACKUP"

# Copiar archivo al contenedor
echo "Copiando archivo al contenedor..."
docker cp $ARCHIVO_SERVIDOR \$CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"

# Verificar que el cambio se aplicó
echo ""
echo "Verificando cambio aplicado..."
docker exec \$CONTAINER_ID grep -A 2 ".select()" /app/whatsapp-server-baileys.js | head -5
echo ""

# Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart \$CONTAINER_ID
echo "✅ Contenedor reiniciado"

echo ""
echo "=========================================="
echo "CAMBIO APLICADO"
echo "=========================================="
echo ""
echo "Ahora los logs mostrarán si Supabase está bloqueando las actualizaciones."
echo "Busca mensajes como:"
echo "  ⚠️ Actualización de whatsapp_chats no devolvió datos"
echo "  ❌ Error actualizando whatsapp_chats"
echo ""
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error aplicando cambios" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Cambio aplicado correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora verifica los logs para ver si hay errores:" -ForegroundColor Yellow
Write-Host "  docker logs \$CONTAINER_ID --tail 50 | grep -E 'Error actualizando|Actualización.*no devolvió|Chat actualizado'" -ForegroundColor Gray
Write-Host ""
