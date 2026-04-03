#!/bin/bash
# Script para verificar que el cambio de imagen funcionó

echo "=========================================="
echo "🔍 VERIFICANDO CAMBIO DE IMAGEN"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que server.js tiene el hotel
echo "1️⃣ Verificando server.js en el contenedor..."
if docker exec "$CONTAINER_ID" grep -q "hotel-1-puyehue" /app/server.js 2>/dev/null; then
    echo "   ✅ Hotel hotel-1-puyehue encontrado en server.js"
    
    # Mostrar la línea relevante
    echo ""
    echo "   Línea relevante:"
    docker exec "$CONTAINER_ID" grep "selectedHotel" /app/server.js | head -1
else
    echo "   ⚠️  Hotel no encontrado (puede usar detección dinámica)"
fi
echo ""

# 2. Verificar que el proceso está corriendo
echo "2️⃣ Verificando proceso Node.js..."
if docker exec "$CONTAINER_ID" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Proceso Node.js está corriendo"
    PID=$(docker exec "$CONTAINER_ID" pgrep -f "node.*server.js" | head -1)
    echo "   PID: $PID"
else
    echo "   ❌ Proceso Node.js no está corriendo"
fi
echo ""

# 3. Probar la ruta HTTP
echo "3️⃣ Probando ruta HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://dashboard.checkin24hs.com/og-cotizar.jpg)
CONTENT_TYPE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg 2>/dev/null | grep -i "content-type" | cut -d' ' -f2 | tr -d '\r')
SIZE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg 2>/dev/null | grep -i "content-length" | cut -d' ' -f2 | tr -d '\r')

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ HTTP 200 - La ruta funciona"
    echo "   Content-Type: $CONTENT_TYPE"
    if [ ! -z "$SIZE" ]; then
        echo "   Tamaño: $SIZE bytes"
    fi
else
    echo "   ❌ HTTP $HTTP_CODE - La ruta no funciona"
fi
echo ""

# 4. Verificar logs recientes
echo "4️⃣ Logs recientes del servicio..."
docker service logs "$SERVICE_NAME" --tail 5 --no-trunc 2>&1 | grep -E "(Server running|error|Error)" | tail -3
echo ""

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🌐 Prueba manual:"
echo "   curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
echo "📱 Próximo paso:"
echo "   Envía un mensaje de WhatsApp con: https://cotizar.checkin24hs.com/"
echo "   Debería aparecer con la imagen de hotel-1-puyehue"
echo ""
