#!/bin/bash
# Script para aplicar fix al servicio de WhatsApp

echo "=========================================="
echo "APLICAR FIX AL SERVICIO DE WHATSAPP"
echo "=========================================="
echo ""

# Verificar que el archivo existe
if [ ! -f "/tmp/whatsapp-server-baileys.js" ]; then
    echo "ERROR: No se encuentra /tmp/whatsapp-server-baileys.js"
    echo "Necesitas subir el archivo primero desde tu máquina local"
    exit 1
fi

echo "Archivo encontrado en /tmp/whatsapp-server-baileys.js"
echo ""

# Reiniciar servicio
echo "1. Reiniciando servicio..."
docker service update --force checkin24hs_whatsapp
echo "✅ Servicio reiniciado"
echo ""

# Esperar a que se cree el contenedor
echo "2. Esperando a que se cree el contenedor (máximo 30 segundos)..."
for i in {1..30}; do
    CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        echo "✅ Contenedor encontrado: $CONTAINER_ID"
        break
    fi
    echo "   Esperando... ($i/30)"
    sleep 1
done

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar contenedor corriendo"
    echo ""
    echo "Verificando estado del servicio:"
    docker service ps checkin24hs_whatsapp --no-trunc | head -3
    exit 1
fi

echo ""

# Copiar archivo corregido al contenedor
echo "3. Copiando archivo corregido al contenedor..."
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error copiando archivo"
    exit 1
fi
echo ""

# Verificar que la corrección se aplicó
echo "4. Verificando que la corrección se aplicó..."
docker exec $CONTAINER_ID grep -A 1 "let isSyncingAppState" /app/whatsapp-server-baileys.js
if [ $? -eq 0 ]; then
    echo "✅ Corrección aplicada correctamente"
else
    echo "⚠️ No se encontró la variable. Verifica el archivo."
fi
echo ""

# Reiniciar el contenedor para que use el archivo corregido
echo "5. Reiniciando contenedor para aplicar cambios..."
docker restart $CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

echo "Esperando 5 segundos..."
sleep 5

# Verificar que está corriendo
echo "6. Verificando estado del contenedor..."
docker ps | grep $CONTAINER_ID
echo ""

# Ver logs recientes
echo "7. Últimos logs (verificando que no hay errores):"
docker logs $CONTAINER_ID --tail 20 2>&1 | grep -iE "error|fatal|exception|isSyncingAppState" || echo "✅ No se encontraron errores relacionados"
echo ""

echo "=========================================="
echo "FIX APLICADO"
echo "=========================================="
echo ""
echo "Verifica los logs en tiempo real:"
echo "docker logs -f $CONTAINER_ID"
echo ""
