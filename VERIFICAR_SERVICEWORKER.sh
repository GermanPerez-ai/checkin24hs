#!/bin/bash

echo "🔍 Verificando cómo se sirve el dashboard..."
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

echo "Contenedor: $CONTAINER"
echo ""

# Verificar el archivo en el contenedor
echo "=== Verificando window.buildServerURL en el contenedor ==="
docker exec $CONTAINER grep -n "window.buildServerURL" /app/dashboard.html | head -1

echo ""
echo "=== Verificando cómo se sirve el archivo ==="
echo "Probando acceso HTTP directo al contenedor..."
docker exec $CONTAINER curl -s http://localhost:3000/dashboard.html 2>/dev/null | grep -o "window.buildServerURL" | head -1 || echo "No se encontró en la respuesta HTTP"

echo ""
echo "=== Verificando si hay un volumen montado ==="
docker inspect $CONTAINER --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{"\n"}}{{end}}' | grep -i dashboard || echo "No hay volúmenes relacionados con dashboard"

echo ""
echo "✅ Verificación completada"








