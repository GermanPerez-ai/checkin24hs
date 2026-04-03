#!/bin/bash
# Script para aplicar logging mejorado de creación de chats
# Ejecutar en el servidor después de subir el archivo

ARCHIVO_SERVIDOR="/tmp/whatsapp-server-baileys.js"

echo "=========================================="
echo "APLICAR LOGGING MEJORADO DE CHATS"
echo "=========================================="
echo ""

# Buscar contenedor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"

# Verificar que el archivo existe
if [ ! -f "$ARCHIVO_SERVIDOR" ]; then
    echo "❌ Archivo no encontrado: $ARCHIVO_SERVIDOR"
    echo "   Primero sube el archivo con:"
    echo "   scp whatsapp-server/whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js"
    exit 1
fi

# Crear backup
BACKUP_FILE="/tmp/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)"
docker cp $CONTAINER_ID:/app/whatsapp-server-baileys.js $BACKUP_FILE
echo "✅ Backup creado: $BACKUP_FILE"

# Copiar archivo al contenedor
docker cp $ARCHIVO_SERVIDOR $CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"

# Verificar que el cambio se aplicó
echo ""
echo "Verificando cambio aplicado..."
docker exec $CONTAINER_ID grep -A 2 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js | head -5
echo ""

# Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart $CONTAINER_ID
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
