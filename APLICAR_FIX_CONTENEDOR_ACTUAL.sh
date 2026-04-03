#!/bin/bash
# Script para aplicar fix al contenedor que está corriendo actualmente

echo "=========================================="
echo "APLICAR FIX AL CONTENEDOR ACTUAL"
echo "=========================================="
echo ""

# Buscar contenedor corriendo
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor corriendo"
    echo ""
    echo "Esperando 5 segundos y reintentando..."
    sleep 5
    CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ Aún no hay contenedor corriendo"
        exit 1
    fi
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar que el archivo existe
if [ ! -f "/tmp/whatsapp-server-baileys.js" ]; then
    echo "❌ ERROR: No se encuentra /tmp/whatsapp-server-baileys.js"
    echo "Necesitas subir el archivo primero desde tu máquina local"
    exit 1
fi

echo "Archivo encontrado en /tmp/whatsapp-server-baileys.js"
echo ""

# Crear backup
echo "1. Creando backup del archivo actual..."
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ No se pudo crear backup (puede estar iniciando)"
echo ""

# Copiar archivo corregido
echo "2. Copiando archivo corregido al contenedor..."
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error copiando archivo"
    exit 1
fi
echo ""

# Verificar que la corrección se aplicó
echo "3. Verificando que la corrección se aplicó..."
docker exec $CONTAINER_ID grep -A 1 "let isSyncingAppState" /app/whatsapp-server-baileys.js
if [ $? -eq 0 ]; then
    echo "✅ Corrección aplicada correctamente"
else
    echo "⚠️ No se encontró la variable. Verifica el archivo."
fi
echo ""

# Reiniciar el contenedor para que use el archivo corregido
echo "4. Reiniciando contenedor para aplicar cambios..."
docker restart $CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

echo "Esperando 5 segundos para que inicie..."
sleep 5

# Verificar que está corriendo
echo "5. Verificando estado del contenedor..."
NEW_CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
if [ -n "$NEW_CONTAINER_ID" ]; then
    echo "✅ Contenedor corriendo: $NEW_CONTAINER_ID"
    docker ps | grep $NEW_CONTAINER_ID
else
    echo "⚠️ Contenedor no está corriendo. Verificando estado del servicio..."
    docker service ps checkin24hs_whatsapp --no-trunc | head -3
fi
echo ""

# Ver logs recientes
echo "6. Últimos logs (verificando que no hay errores):"
if [ -n "$NEW_CONTAINER_ID" ]; then
    docker logs $NEW_CONTAINER_ID --tail 30 2>&1 | tail -10
    echo ""
    ERROR_CHECK=$(docker logs $NEW_CONTAINER_ID --tail 50 2>&1 | grep -iE "isSyncingAppState is not defined" | tail -1)
    if [ -z "$ERROR_CHECK" ]; then
        echo "✅ No se encontró el error de isSyncingAppState"
    else
        echo "❌ El error persiste:"
        echo "$ERROR_CHECK"
    fi
else
    echo "⚠️ No se puede verificar logs (contenedor no encontrado)"
fi
echo ""

echo "=========================================="
echo "FIX APLICADO"
echo "=========================================="
echo ""
if [ -n "$NEW_CONTAINER_ID" ]; then
    echo "Verifica los logs en tiempo real:"
    echo "docker logs -f $NEW_CONTAINER_ID"
else
    echo "El contenedor puede estar reiniciándose. Espera unos segundos y verifica:"
    echo "docker ps | grep whatsapp"
fi
echo ""
