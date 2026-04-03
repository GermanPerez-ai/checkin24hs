#!/bin/bash
# Verificar si el servidor está procesando mensajes

echo "=========================================="
echo "VERIFICAR SERVIDOR PROCESANDO MENSAJES"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver si hay mensajes siendo procesados
echo "=== 1. MENSAJES PROCESADOS (ÚLTIMOS 10 MIN) ==="
echo ""
echo "Buscando mensajes recibidos:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Mensaje recibido|procesando.*mensaje|mensaje.*recibido" | tail -10
echo ""

echo "Buscando actividad de Flor IA:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Flor respondió|procesando.*Flor|Flor.*respondió" | tail -10
echo ""

# 2. Ver actividad general del servidor
echo "=== 2. ACTIVIDAD GENERAL (ÚLTIMOS 10 MIN) ==="
echo ""
echo "Últimas 20 líneas de logs:"
docker logs $CONTAINER_ID --since 10m 2>&1 | tail -20
echo ""

# 3. Verificar estado de conexión
echo "=== 3. ESTADO DE CONEXIÓN ==="
echo ""
echo "Estado de WhatsApp:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "WhatsApp conectado|Conexión|QR|conectado" | tail -5
echo ""

# 4. Ver errores
echo "=== 4. ERRORES (ÚLTIMOS 10 MIN) ==="
echo ""
ERRORES=$(docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Error|❌|⚠️" | tail -10)
if [ -n "$ERRORES" ]; then
    echo "❌ Errores encontrados:"
    echo "$ERRORES"
else
    echo "✅ No se encontraron errores"
fi
echo ""

echo "=========================================="
echo "INSTRUCCIONES"
echo "=========================================="
echo ""
echo "Si no hay actividad:"
echo "1. Envía un mensaje de WhatsApp al bot desde tu teléfono"
echo "2. Espera unos segundos"
echo "3. Ejecuta este script nuevamente"
echo ""
