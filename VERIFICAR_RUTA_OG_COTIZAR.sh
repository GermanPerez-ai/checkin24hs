#!/bin/bash
# Script para verificar que la ruta /og-cotizar.jpg funciona

echo "=========================================="
echo "🔍 VERIFICANDO RUTA /og-cotizar.jpg"
echo "=========================================="
echo ""

# 1. Verificar desde el servidor
echo "1️⃣ Probando desde el servidor..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://dashboard.checkin24hs.com/og-cotizar.jpg)
CONTENT_TYPE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg | grep -i "content-type" | cut -d' ' -f2 | tr -d '\r')

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ HTTP 200 - La ruta funciona"
    if echo "$CONTENT_TYPE" | grep -qi "image"; then
        echo "   ✅ Content-Type correcto: $CONTENT_TYPE"
    else
        echo "   ⚠️  Content-Type: $CONTENT_TYPE (esperado: image/jpeg)"
    fi
else
    echo "   ❌ HTTP $HTTP_CODE - La ruta no funciona"
fi
echo ""

# 2. Verificar tamaño del archivo
echo "2️⃣ Verificando tamaño del archivo..."
SIZE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg | grep -i "content-length" | cut -d' ' -f2 | tr -d '\r')
if [ ! -z "$SIZE" ] && [ "$SIZE" != "0" ]; then
    echo "   ✅ Tamaño: $SIZE bytes"
else
    echo "   ⚠️  Tamaño no disponible o es 0"
fi
echo ""

# 3. Verificar en el contenedor
echo "3️⃣ Verificando en el contenedor..."
SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$CONTAINER_ID" ]; then
    if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "   ✅ Ruta confirmada en server.js"
    else
        echo "   ⚠️  Ruta no encontrada en server.js"
    fi
    
    # Verificar que el proceso está escuchando en el puerto correcto
    if docker exec "$CONTAINER_ID" netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        echo "   ✅ Servidor escuchando en puerto 3000"
    else
        echo "   ⚠️  No se pudo verificar el puerto"
    fi
else
    echo "   ⚠️  No se encontró contenedor"
fi
echo ""

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🌐 Prueba manual:"
echo "   curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
echo "📱 Próximo paso:"
echo "   Envía un mensaje de WhatsApp con el enlace:"
echo "   https://cotizar.checkin24hs.com/"
echo "   Debería aparecer con la imagen de preview"
echo ""
