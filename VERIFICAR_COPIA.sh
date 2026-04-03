#!/bin/bash

echo "=== VERIFICACIÓN RÁPIDA DEL CONTENEDOR ==="
echo ""

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"
echo ""

echo "1. Verificando si existe header-left:"
docker exec "$CONTAINER" grep -c "header-left" /app/dashboard.html 2>/dev/null
echo ""

echo "2. Verificando estructura del header (primeras 10 líneas después de 'class=\"header\"'):"
docker exec "$CONTAINER" grep -A 10 'class="header"' /app/dashboard.html 2>/dev/null | head -12
echo ""

echo "3. Verificando si existe serve-dashboard.js:"
docker exec "$CONTAINER" test -f /app/serve-dashboard.js && echo "✅ Existe" || echo "❌ No existe"
echo ""

echo "4. Verificando charset en serve-dashboard.js:"
docker exec "$CONTAINER" grep -n "charset=utf-8" /app/serve-dashboard.js 2>/dev/null | head -3
echo ""

echo "5. Estado del contenedor:"
docker ps --filter "name=dashboard" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
