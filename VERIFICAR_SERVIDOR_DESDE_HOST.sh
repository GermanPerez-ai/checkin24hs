#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR SERVIDOR DESDE HOST"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar server.js para ver cómo está sirviendo
echo "=== 1. VERIFICAR server.js ==="
docker exec "$CONTAINER" cat /app/server.js 2>/dev/null | grep -A 5 -B 5 "dashboard.html" | head -20
echo ""

# 2. Verificar puerto del contenedor
echo "=== 2. VERIFICAR PUERTO ==="
docker port "$CONTAINER" 2>/dev/null | head -5
echo ""

# 3. Hacer curl desde el HOST (no desde dentro del contenedor)
echo "=== 3. HACER CURL DESDE HOST ==="
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "IP del contenedor: $CONTAINER_IP"
echo "Obteniendo dashboard desde el contenedor..."
curl -s "http://$CONTAINER_IP:3000" 2>/dev/null | grep -A 12 'class="header"' | head -13
echo ""

# 4. Alternativa: Verificar a través de la red del host
echo "=== 4. VERIFICAR A TRAVÉS DE LOCALHOST ==="
echo "Intentando desde localhost..."
curl -s http://localhost:3000 2>/dev/null | grep -A 12 'class="header"' | head -13 || echo "No accesible desde localhost"
echo ""

# 5. Verificar logs del contenedor
echo "=== 5. ÚLTIMOS LOGS DEL CONTENEDOR ==="
docker logs "$CONTAINER" --tail 20 2>/dev/null | tail -10
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
