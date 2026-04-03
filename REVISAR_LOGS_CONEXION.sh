#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO LOGS DE CONEXIÓN WHATSAPP"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Logs completos de los últimos 5 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 5m 2>&1
echo ""

echo "2️⃣ Buscando eventos de QR y conexión:"
echo "----------------------------------------"
echo "📱 QR Codes generados:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code recibido|QR Code generado|QR escaneado)" | tail -10
echo ""

echo "🔄 Estados de conexión:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Conectando|WhatsApp conectado|Teléfono conectado|Estado:)" | tail -10
echo ""

echo "⏳ Tiempos de autenticación:"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(tiempo transcurrido|esperando autenticación)" | tail -10
echo ""

echo "3️⃣ Errores y desconexiones:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Error|error|Conexión cerrada|Connection Terminated|timeout|Timeout|428|401)" | tail -20
echo ""

echo "4️⃣ Detalles de errores (últimos 3):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -A 5 "Detalles del error" | tail -30
echo ""

echo "5️⃣ Eventos de Baileys (últimos 20):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(baileys|connected to WA|not logged in|attempting registration)" | tail -20
echo ""

echo "6️⃣ Logs completos en orden cronológico (últimas 50 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 50 2>&1
echo ""

echo "=========================================="
echo "💡 ANÁLISIS"
echo "=========================================="
echo ""
echo "Busca en los logs:"
echo "  1. Si aparece 'QR escaneado, esperando autenticación...'"
echo "  2. Cuánto tiempo transcurre antes del error"
echo "  3. Qué tipo de error aparece (428, 401, timeout, etc.)"
echo "  4. Si hay mensajes de 'Connection Terminated by Server'"
echo ""
