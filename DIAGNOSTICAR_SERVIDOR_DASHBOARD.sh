#!/bin/bash
# Diagnosticar qué archivo está sirviendo el servidor Node.js

echo "=== DIAGNÓSTICO DEL SERVIDOR DASHBOARD ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar server.js
echo "🔍 1. Verificando server.js..."
SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -n "$SERVER_PATH" ]; then
    echo "   Ruta: $SERVER_PATH"
    echo ""
    echo "   Contenido relevante (ruta del dashboard):"
    docker exec "$CONTAINER" grep -A 2 -B 2 "dashboard.html\|sendFile\|__dirname" "$SERVER_PATH" 2>/dev/null | head -20
else
    echo "   ⚠️  No se encontró server.js"
fi
echo ""

# 2. Buscar todos los dashboard.html
echo "🔍 2. Buscando todos los archivos dashboard.html:"
docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules
echo ""

# 3. Verificar el directorio de trabajo de Node.js
echo "🔍 3. Verificando directorio de trabajo y proceso Node.js:"
docker exec "$CONTAINER" ps aux | grep node | head -3
echo ""
docker exec "$CONTAINER" pwd 2>/dev/null
echo ""

# 4. Verificar variables de entorno
echo "🔍 4. Verificando variables de entorno:"
docker exec "$CONTAINER" env | grep -iE "dir|path|home|app" | head -10
echo ""

# 5. Listar archivos en directorios comunes
echo "🔍 5. Listando archivos en directorios comunes:"
for dir in "/app" "/usr/src/app" "/root" "/root/checkin24hs"; do
    if docker exec "$CONTAINER" test -d "$dir" 2>/dev/null; then
        echo "   $dir:"
        docker exec "$CONTAINER" ls -lah "$dir" 2>/dev/null | grep -E "dashboard|server" | head -5
    fi
done
echo ""

# 6. Verificar logs del servidor
echo "🔍 6. Últimos logs del servidor:"
docker logs "$CONTAINER" --tail 30 2>&1 | grep -iE "dashboard|error|serving|file" | tail -10
echo ""

# 7. Probar acceso directo al contenedor
echo "🔍 7. Probando acceso directo al contenedor (puerto 3000):"
docker exec "$CONTAINER" curl -s http://localhost:3000/ 2>/dev/null | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="





