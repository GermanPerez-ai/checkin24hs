#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"

echo "=== Estado del servicio ==="
docker service ps "$SERVICE_NAME" --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}" | head -5
echo ""

echo "=== Contenedor ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    if docker ps | grep -q "$CONTAINER"; then
        echo "✅ Contenedor está corriendo"
        echo ""
        echo "=== Logs recientes ==="
        docker logs "$CONTAINER" --tail 15 2>&1 | tail -15
    else
        echo "❌ Contenedor NO está corriendo"
    fi
else
    echo "❌ No se encontró contenedor"
fi
echo ""

echo "=== Esperar y probar acceso ==="
echo "Esperando 10 segundos..."
sleep 10
echo ""
echo "Probando acceso directo..."
if [ -n "$CONTAINER" ] && docker ps | grep -q "$CONTAINER"; then
    CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        timeout 5 curl -s -o /dev/null -w "Status: %{http_code}\n" http://$CONTAINER_IP:3000 || echo "No responde"
    fi
fi
echo ""
