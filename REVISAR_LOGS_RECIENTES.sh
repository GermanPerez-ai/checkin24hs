#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO LOGS MÁS RECIENTES"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "📋 Logs completos de los últimos 3 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 3m 2>&1
echo ""

echo "🔍 Buscando eventos específicos:"
echo "----------------------------------------"
echo "1. Pairing y conexión:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -E "(pairing configured|logging in|WhatsApp conectado|Teléfono conectado)" | tail -10
echo ""

echo "2. Errores:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -E "(Error|error|device_removed|515|428|401)" | tail -10
echo ""

echo "3. Sincronización (puede estar causando el problema):"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -E "(syncing|resyncing|app state|history)" | tail -10
echo ""

echo "4. Tiempo transcurrido:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -E "(tiempo transcurrido|esperando autenticación)" | tail -5
echo ""
