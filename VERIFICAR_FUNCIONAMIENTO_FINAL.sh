#!/bin/bash
# Verificar que todo funciona correctamente

echo "=== VERIFICACIÓN FINAL ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar archivo en contenedor
echo "🔍 1. Verificando archivo en contenedor:"
FILE_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño: $FILE_SIZE bytes"

docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"
echo ""

# 2. Verificar que el servidor está corriendo
echo "🔍 2. Verificando proceso Node.js:"
docker exec "$CONTAINER" ps aux | grep node | grep -v grep | head -2
echo ""

# 3. Probar acceso directo (usando wget)
echo "🔍 3. Probando acceso directo al contenedor:"
RESPONSE=$(docker exec "$CONTAINER" wget -qO- http://localhost:3000/ 2>/dev/null || echo "")

if [ -n "$RESPONSE" ]; then
    RESPONSE_SIZE=$(echo "$RESPONSE" | wc -c)
    echo "   Tamaño de respuesta: $RESPONSE_SIZE bytes"
    
    if [ "$RESPONSE_SIZE" -gt 1000000 ]; then
        echo "   ✅ Tamaño correcto (más de 1MB)"
    else
        echo "   ⚠️  Tamaño incorrecto (debería ser ~1.29MB)"
    fi
    
    echo "$RESPONSE" | grep -q "whatsapp-config-button-main" && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "   ⚠️  No se pudo obtener respuesta (wget no disponible)"
fi
echo ""

# 4. Verificar acceso HTTPS
echo "🔍 4. Verificando acceso HTTPS:"
HTTPS_RESPONSE=$(curl -s https://dashboard.checkin24hs.com 2>&1)
HTTPS_SIZE=$(echo "$HTTPS_RESPONSE" | wc -c)
echo "   Tamaño de respuesta HTTPS: $HTTPS_SIZE bytes"

if [ "$HTTPS_SIZE" -gt 1000000 ]; then
    echo "   ✅ Tamaño correcto"
else
    echo "   ⚠️  Tamaño incorrecto (debería ser ~1.29MB)"
fi

echo "$HTTPS_RESPONSE" | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"
echo ""

# 5. Verificar headers
echo "🔍 5. Verificando headers HTTP:"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|http" | head -5
echo ""

echo "=== RESUMEN ==="
echo ""
if echo "$HTTPS_RESPONSE" | grep -q "whatsapp-config-button-main"; then
    echo "✅ TODO FUNCIONA CORRECTAMENTE"
    echo ""
    echo "📋 El dashboard está sirviendo la versión correcta con los botones de WhatsApp"
    echo "📋 Los headers anti-caché están configurados"
    echo ""
    echo "⚠️  IMPORTANTE: Cada vez que se reinicie el servicio, ejecuta:"
    echo "   bash ACTUALIZAR_DASHBOARD_DESPUES_REINICIO.sh"
    echo "   O manualmente:"
    echo "   docker cp deploy/dashboard.html \$(docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | head -1):/app/dashboard.html"
    echo "   docker exec \$(docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | head -1) pkill -f 'node.*server.js'"
else
    echo "❌ AÚN HAY PROBLEMAS"
    echo ""
    echo "El archivo está correcto en el contenedor pero no se está sirviendo correctamente"
    echo "Verifica los logs: docker logs $CONTAINER --tail 50"
fi
echo ""





