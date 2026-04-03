#!/bin/bash
# Script para aplicar corrección de chats desde el servidor

echo "=========================================="
echo "APLICAR CORRECCIÓN DE CHATS"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
echo "Buscando contenedor de WhatsApp..."
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    echo ""
    echo "Contenedores disponibles:"
    docker ps | grep -E "(CONTAINER|whatsapp)"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar que el archivo existe
if [ ! -f "/tmp/whatsapp-server-baileys.js" ]; then
    echo "ERROR: No se encontro el archivo /tmp/whatsapp-server-baileys.js"
    echo ""
    echo "Primero sube el archivo desde tu máquina local:"
    echo "  scp whatsapp-server/whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js"
    exit 1
fi

echo "Archivo encontrado: /tmp/whatsapp-server-baileys.js"
echo ""

# Hacer backup
echo "Paso 1: Haciendo backup del archivo actual..."
BACKUP_FILE="/app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)"
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup creado: $BACKUP_FILE"
else
    echo "⚠️ Advertencia: No se pudo crear backup (continuando de todos modos)"
fi
echo ""

# Copiar archivo corregido
echo "Paso 2: Copiando archivo corregido al contenedor..."
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

if [ $? -ne 0 ]; then
    echo "ERROR: No se pudo copiar el archivo al contenedor"
    exit 1
fi

echo "✅ Archivo copiado correctamente"
echo ""

# Reiniciar contenedor
echo "Paso 3: Reiniciando contenedor..."
docker restart $CONTAINER_ID

if [ $? -ne 0 ]; then
    echo "ERROR: No se pudo reiniciar el contenedor"
    exit 1
fi

echo "✅ Contenedor reiniciado"
echo ""

# Esperar un poco
echo "Esperando 10 segundos para que el contenedor inicie..."
sleep 10
echo ""

# Verificar logs
echo "Paso 4: Verificando logs del contenedor..."
echo "=========================================="
docker logs $CONTAINER_ID --tail 30 | grep -E "(Iniciando|chat|conversation|error|✅|❌)" || docker logs $CONTAINER_ID --tail 20
echo "=========================================="
echo ""

echo "=========================================="
echo "CORRECCIÓN APLICADA EXITOSAMENTE"
echo "=========================================="
echo ""
echo "Ahora:"
echo "  1. Envia un mensaje de prueba a Flor por WhatsApp"
echo "  2. Espera 5-10 segundos"
echo "  3. Abre el dashboard: https://dashboard.checkin24hs.com/"
echo "  4. Ve a la seccion 'Chats'"
echo "  5. Haz clic en 'Actualizar'"
echo "  6. Debe aparecer el contacto y la conversacion"
echo ""
