#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR SERVIDOR DIRECTO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Ver cómo server.js está sirviendo el dashboard
echo "=== 1. CÓMO SERVE EL DASHBOARD ==="
docker exec "$CONTAINER" grep -A 10 "app.get('/'" /app/server.js 2>/dev/null | head -15
echo ""

# 2. Verificar el archivo directamente con curl desde el servidor
echo "=== 2. CURL DESDE HOST (IP del contenedor) ==="
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "IP: $CONTAINER_IP"
if [ -n "$CONTAINER_IP" ]; then
    curl -s "http://$CONTAINER_IP:3000" 2>/dev/null | grep -A 12 'class="header"' | head -13
else
    echo "❌ No se pudo obtener IP del contenedor"
fi
echo ""

# 3. Verificar directamente el archivo que está en el contenedor
echo "=== 3. ARCHIVO EN /app/dashboard.html ==="
docker exec "$CONTAINER" grep -A 12 'class="header"' /app/dashboard.html 2>/dev/null | head -13
echo ""

# 4. Verificar si hay algún proceso que esté modificando el archivo
echo "=== 4. VERIFICAR PROCESOS ==="
docker exec "$CONTAINER" ps aux
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
