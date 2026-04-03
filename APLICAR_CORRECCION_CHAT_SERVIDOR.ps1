# Script PowerShell para aplicar corrección de guardado de chats en el servidor

$SERVER = "root@72.61.58.240"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR CORRECCIÓN DE GUARDADO DE CHAT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $ARCHIVO_LOCAL)) {
    Write-Host "ERROR: No se encuentra el archivo $ARCHIVO_LOCAL" -ForegroundColor Red
    exit 1
}

Write-Host "1. Subiendo archivo corregido al servidor..." -ForegroundColor Yellow
scp $ARCHIVO_LOCAL "${SERVER}:${ARCHIVO_SERVIDOR}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

Write-Host "2. Aplicando corrección en el servidor..." -ForegroundColor Yellow
Write-Host ""

# Script para aplicar en el servidor
$SCRIPT_SERVIDOR = @"
#!/bin/bash
# Buscar contenedor de WhatsApp
CONTAINER_ID=\$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: \$CONTAINER_ID"
echo ""

# Crear backup
echo "Creando backup del archivo actual..."
docker exec \$CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.\$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

# Copiar archivo corregido al contenedor
echo "Copiando archivo corregido al contenedor..."
docker cp ${ARCHIVO_SERVIDOR} \$CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"
echo ""

# Verificar que se actualizó correctamente
echo "Verificando que la corrección se aplicó..."
PRIORIDAD=\$(docker exec \$CONTAINER_ID grep -A 3 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "PRIMERO.*whatsapp_chats")
if [ -n "\$PRIORIDAD" ]; then
    echo "✅ Corrección aplicada correctamente:"
    echo "\$PRIORIDAD"
else
    echo "⚠️ No se encontró la corrección. Verifica el archivo."
fi
echo ""

# Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart \$CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

echo "Esperando 5 segundos para que el contenedor inicie..."
sleep 5

# Verificar que está corriendo
echo "Verificando estado del contenedor..."
docker ps | grep \$CONTAINER_ID
echo ""

echo "=========================================="
echo "CORRECCIÓN APLICADA"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Envía un mensaje de prueba a Flor por WhatsApp"
echo "2. Verifica que aparezca en la sección Chat del dashboard"
echo "3. Verifica los logs: docker logs \$CONTAINER_ID -f"
echo ""
"@

# Ejecutar script en el servidor
ssh $SERVER "bash -s" <<< $SCRIPT_SERVIDOR

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Corrección aplicada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Envía un mensaje de prueba a Flor por WhatsApp"
    Write-Host "2. Verifica que aparezca en la sección Chat del dashboard"
    Write-Host "3. Verifica los logs en el servidor"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Hubo un problema al aplicar la corrección" -ForegroundColor Red
    Write-Host ""
}
