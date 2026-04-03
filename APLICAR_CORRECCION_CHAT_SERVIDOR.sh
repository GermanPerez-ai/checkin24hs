#!/bin/bash
# Script para aplicar corrección de guardado de chats en el servidor

echo "=========================================="
echo "APLICAR CORRECCIÓN DE GUARDADO DE CHAT"
echo "=========================================="
echo ""

# Buscar contenedor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Verificar que el archivo existe en /tmp
if [ ! -f "/tmp/whatsapp-server-baileys.js" ]; then
    echo "ERROR: No se encuentra /tmp/whatsapp-server-baileys.js"
    echo "Necesitas subir el archivo primero desde tu máquina local"
    exit 1
fi

# Crear backup
echo "1. Creando backup del archivo actual..."
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

# Copiar archivo corregido
echo "2. Copiando archivo corregido al contenedor..."
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"
echo ""

# Verificar que se actualizó correctamente
echo "3. Verificando que la corrección se aplicó..."
PRIORIDAD=$(docker exec $CONTAINER_ID grep -A 3 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "PRIMERO.*whatsapp_chats")
if [ -n "$PRIORIDAD" ]; then
    echo "✅ Corrección aplicada correctamente:"
    echo "$PRIORIDAD"
else
    echo "⚠️ No se encontró la corrección. Verifica el archivo."
fi
echo ""

# Reiniciar contenedor
echo "4. Reiniciando contenedor..."
docker restart $CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

echo "Esperando 5 segundos para que el contenedor inicie..."
sleep 5

# Verificar que está corriendo
echo "5. Verificando estado del contenedor..."
docker ps | grep $CONTAINER_ID
echo ""

echo "=========================================="
echo "CORRECCIÓN APLICADA"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Envía un mensaje de prueba a Flor por WhatsApp"
echo "2. Verifica que aparezca en la sección Chat del dashboard"
echo "3. Verifica los logs: docker logs $CONTAINER_ID -f"
echo ""
