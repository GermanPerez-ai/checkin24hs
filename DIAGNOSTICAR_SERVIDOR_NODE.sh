#!/bin/bash
# Diagnosticar por qué el servidor no está sirviendo el archivo correcto

echo "=== DIAGNÓSTICO DEL SERVIDOR NODE.JS ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar server.js completo
echo "🔍 1. Verificando server.js:"
SERVER_PATH="/app/server.js"
if docker exec "$CONTAINER" test -f "$SERVER_PATH" 2>/dev/null; then
    echo "   Ruta: $SERVER_PATH"
    echo ""
    echo "   Código relevante (ruta del dashboard):"
    docker exec "$CONTAINER" grep -A 5 -B 5 "dashboard.html\|sendFile\|__dirname" "$SERVER_PATH" 2>/dev/null | head -30
else
    echo "   ❌ No se encontró server.js"
fi
echo ""

# 2. Probar acceso directo al contenedor (puerto 3000)
echo "🔍 2. Probando acceso directo al contenedor (puerto 3000):"
DIRECT_RESPONSE=$(docker exec "$CONTAINER" curl -s http://localhost:3000/ 2>/dev/null)
DIRECT_SIZE=$(echo "$DIRECT_RESPONSE" | wc -c)
echo "   Tamaño de respuesta: $DIRECT_SIZE bytes"

echo "$DIRECT_RESPONSE" | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"

# Comparar con archivo en disco
FILE_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
if [ "$DIRECT_SIZE" = "$FILE_SIZE" ]; then
    echo "   ✅ Tamaño coincide con archivo en disco"
else
    echo "   ⚠️  Tamaño NO coincide (archivo: $FILE_SIZE, servido: $DIRECT_SIZE)"
fi
echo ""

# 3. Verificar si hay múltiples archivos dashboard.html
echo "🔍 3. Buscando TODOS los archivos dashboard.html:"
docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules
echo ""

# 4. Verificar variables de entorno y directorio de trabajo
echo "🔍 4. Verificando entorno del proceso Node.js:"
docker exec "$CONTAINER" ps aux | grep node | head -3
echo ""
docker exec "$CONTAINER" pwd 2>/dev/null
echo ""
docker exec "$CONTAINER" env | grep -iE "dir|path|home|app|node" | head -10
echo ""

# 5. Verificar logs del servidor para ver qué archivo está sirviendo
echo "🔍 5. Últimos logs del servidor:"
docker logs "$CONTAINER" --tail 50 2>&1 | grep -iE "dashboard|serving|file|error|warning" | tail -20
echo ""

# 6. Probar acceso a través de Traefik (HTTPS)
echo "🔍 6. Comparando acceso directo vs HTTPS:"
HTTPS_RESPONSE=$(curl -s https://dashboard.checkin24hs.com 2>&1)
HTTPS_SIZE=$(echo "$HTTPS_RESPONSE" | wc -c)
echo "   Tamaño HTTPS: $HTTPS_SIZE bytes"

echo "$HTTPS_RESPONSE" | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ HTTPS contiene botones" || \
    echo "   ❌ HTTPS NO contiene botones"

if [ "$DIRECT_SIZE" = "$HTTPS_SIZE" ]; then
    echo "   ✅ Tamaños coinciden (directo y HTTPS)"
else
    echo "   ⚠️  Tamaños NO coinciden (directo: $DIRECT_SIZE, HTTPS: $HTTPS_SIZE)"
    echo "   Esto sugiere que Traefik puede estar cacheando o modificando la respuesta"
fi
echo ""

# 7. Verificar headers de respuesta
echo "🔍 7. Headers de respuesta HTTPS:"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache|etag|last-modified|content-length" | head -10
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="





