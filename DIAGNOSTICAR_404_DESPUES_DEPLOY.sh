#!/bin/bash
# Diagnosticar errores 404 después del deploy

echo "=========================================="
echo "🔍 Diagnosticando errores 404 después del deploy"
echo "=========================================="
echo ""

# 1. Verificar que el servicio está corriendo
echo "1️⃣ Verificando estado del servicio dashboard..."
docker service ps checkin24hs_dashboard --no-trunc | head -5

echo ""
echo "2️⃣ Verificando contenedores del dashboard..."
docker ps --filter "name=dashboard" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "3️⃣ Verificando logs del dashboard (últimas 20 líneas)..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    docker logs "$DASHBOARD_CONTAINER" --tail 20
else
    echo "⚠️  No se encontró contenedor del dashboard"
fi

echo ""
echo "4️⃣ Verificando si el endpoint /api/version existe en server.js..."
if [ -f "/root/checkin24hs/server.js" ]; then
    if grep -q "/api/version" /root/checkin24hs/server.js; then
        echo "✅ El endpoint /api/version existe en server.js"
        echo "   Líneas relevantes:"
        grep -A 10 "/api/version" /root/checkin24hs/server.js | head -15
    else
        echo "❌ El endpoint /api/version NO existe en server.js"
    fi
else
    echo "⚠️  No se encontró server.js en /root/checkin24hs/"
    echo "   Buscando en otros lugares..."
    find /root -name "server.js" -type f 2>/dev/null | head -3
fi

echo ""
echo "5️⃣ Verificando archivos en el contenedor del dashboard..."
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Archivos en /app del contenedor:"
    docker exec "$DASHBOARD_CONTAINER" ls -la /app 2>/dev/null | head -20 || echo "No se puede acceder al contenedor"
    
    echo ""
    echo "Verificando si server.js existe en el contenedor:"
    docker exec "$DASHBOARD_CONTAINER" test -f /app/server.js && echo "✅ server.js existe" || echo "❌ server.js NO existe"
    
    echo ""
    echo "Verificando si /api/version está en server.js del contenedor:"
    docker exec "$DASHBOARD_CONTAINER" grep -q "/api/version" /app/server.js 2>/dev/null && echo "✅ /api/version existe en server.js del contenedor" || echo "❌ /api/version NO existe en server.js del contenedor"
fi

echo ""
echo "6️⃣ Probando acceso directo al endpoint /api/version..."
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo "IP del servidor: $SERVER_IP"

# Intentar acceder directamente al contenedor
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Probando desde dentro del contenedor..."
    docker exec "$DASHBOARD_CONTAINER" wget -qO- http://localhost:3000/api/version 2>/dev/null && echo "✅ El endpoint responde" || echo "❌ El endpoint NO responde"
fi

echo ""
echo "7️⃣ Verificando configuración de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Logs recientes de Traefik relacionados con dashboard:"
    docker service logs traefik --tail 30 | grep -iE "dashboard|404|error" | tail -10
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si el endpoint /api/version no existe en el contenedor,"
echo "necesitas hacer un nuevo deploy para que los cambios se apliquen."
echo ""
echo "Si el endpoint existe pero sigue dando 404, puede ser:"
echo "  1. Traefik no está enrutando correctamente"
echo "  2. El servidor no está escuchando en el puerto correcto"
echo "  3. Hay un problema con la ruta en express"
echo ""
