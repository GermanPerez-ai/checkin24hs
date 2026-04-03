#!/bin/bash

# Script para aplicar cambios del CRM en el servidor
# Este script se ejecuta en el servidor después de subir el archivo

echo "=== Aplicar cambios del CRM ==="

# 1. Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/deploy/crm.js" ]; then
    echo "❌ Error: No se encuentra el archivo crm.js"
    exit 1
fi

echo ""
echo "1. Verificando archivo..."
ls -lh /root/checkin24hs/deploy/crm.js

# 2. Obtener contenedor del CRM
echo ""
echo "2. Buscando contenedor del CRM..."
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor del CRM corriendo"
    echo "Los cambios se aplicarán cuando se reinicie el servicio"
    exit 0
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# 3. Copiar archivo al contenedor
echo ""
echo "3. Copiando archivo al contenedor..."
docker cp /root/checkin24hs/deploy/crm.js $CONTAINER_ID:/app/crm.js

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error al copiar el archivo"
    exit 1
fi

# 4. Verificar que se copió
echo ""
echo "4. Verificando que se copió correctamente..."
docker exec $CONTAINER_ID ls -lh /app/crm.js

# 5. Verificar tamaño del archivo
echo ""
echo "5. Comparando tamaños..."
LOCAL_SIZE=$(stat -f%z /root/checkin24hs/deploy/crm.js 2>/dev/null || stat -c%s /root/checkin24hs/deploy/crm.js 2>/dev/null)
CONTAINER_SIZE=$(docker exec $CONTAINER_ID stat -f%z /app/crm.js 2>/dev/null || docker exec $CONTAINER_ID stat -c%s /app/crm.js 2>/dev/null)

if [ "$LOCAL_SIZE" = "$CONTAINER_SIZE" ]; then
    echo "✅ Tamaños coinciden: $LOCAL_SIZE bytes"
else
    echo "⚠️ Tamaños diferentes:"
    echo "   Local: $LOCAL_SIZE bytes"
    echo "   Contenedor: $CONTAINER_SIZE bytes"
fi

echo ""
echo "=== Proceso completado ==="
echo ""
echo "✅ Cambios aplicados al contenedor del CRM"
echo ""
echo "Próximos pasos:"
echo "1. Abre https://crm.checkin24hs.com"
echo "2. Recarga la página (Ctrl+F5 o Cmd+Shift+R)"
echo "3. Abre la consola del navegador (F12)"
echo "4. Verifica que aparezcan los mensajes de suscripciones en tiempo real"






