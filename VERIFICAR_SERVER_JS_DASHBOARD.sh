#!/bin/bash
# Script para verificar si server.js tiene la ruta /og-cotizar.jpg después del reinicio

echo "=========================================="
echo "🔍 VERIFICANDO SERVER.JS EN DASHBOARD"
echo "=========================================="
echo ""

# 1. Buscar servicio del dashboard
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    exit 1
fi

echo "✅ Servicio: $SERVICE_NAME"
echo ""

# 2. Esperar a que el servicio esté completamente iniciado
echo "⏳ Esperando 10 segundos para que el servicio se estabilice..."
sleep 10

# 3. Buscar contenedor
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --format "{{.ID}}\t{{.Names}}" | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 4. Verificar si server.js existe
echo "4️⃣ Verificando si server.js existe..."
if docker exec "$CONTAINER_ID" test -f /app/server.js 2>/dev/null; then
    echo "   ✅ server.js existe en /app/server.js"
else
    echo "   ❌ server.js NO existe en /app/server.js"
    echo ""
    echo "   Buscando server.js en otras ubicaciones..."
    docker exec "$CONTAINER_ID" find / -name "server.js" 2>/dev/null | head -5
    exit 1
fi
echo ""

# 5. Verificar si tiene la ruta /og-cotizar.jpg
echo "5️⃣ Verificando si server.js tiene la ruta /og-cotizar.jpg..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
    echo "   ✅ Ruta /og-cotizar.jpg ENCONTRADA en server.js"
    echo ""
    echo "   Mostrando líneas relevantes:"
    docker exec "$CONTAINER_ID" grep -n "og-cotizar" /app/server.js | head -5
else
    echo "   ❌ Ruta /og-cotizar.jpg NO encontrada en server.js"
    echo ""
    echo "   Mostrando primeras líneas de server.js para verificar:"
    docker exec "$CONTAINER_ID" head -30 /app/server.js
fi
echo ""

# 6. Probar acceso a la ruta
echo "6️⃣ Probando acceso a https://dashboard.checkin24hs.com/og-cotizar.jpg..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://dashboard.checkin24hs.com/og-cotizar.jpg)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ La ruta responde correctamente (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "   ❌ La ruta no existe (HTTP 404)"
else
    echo "   ⚠️  La ruta responde con código HTTP $HTTP_CODE"
fi
echo ""

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
