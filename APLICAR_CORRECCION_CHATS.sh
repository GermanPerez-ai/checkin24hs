#!/bin/bash
# Script para aplicar corrección de guardado de chats en el servidor

echo "=========================================="
echo "APLICAR CORRECCIÓN DE CHATS"
echo "=========================================="
echo ""

# Buscar contenedor del servidor WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# Hacer backup del archivo
echo "Paso 1: Haciendo backup del archivo..."
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

# Copiar archivo corregido
echo "Paso 2: Copiando archivo corregido..."
echo "Archivo local: whatsapp-server/whatsapp-server-baileys.js"
echo "Archivo destino: /app/whatsapp-server-baileys.js"
echo ""
echo "Ejecuta desde tu máquina local (PowerShell):"
echo "  scp whatsapp-server/whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js"
echo ""
echo "Luego en el servidor:"
echo "  docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js"
echo "  docker restart $CONTAINER_ID"
echo ""

echo "=========================================="
echo "INSTRUCCIONES COMPLETAS"
echo "=========================================="
echo ""
echo "1. Desde tu máquina local (PowerShell):"
echo "   cd C:\\Users\\German\\Downloads\\Checkin24hs"
echo "   scp whatsapp-server/whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js"
echo ""
echo "2. En el servidor (SSH):"
echo "   docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js"
echo "   docker restart $CONTAINER_ID"
echo ""
echo "3. Verificar logs:"
echo "   docker logs $CONTAINER_ID --tail 50"
echo ""
