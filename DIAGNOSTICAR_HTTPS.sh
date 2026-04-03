#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
echo "Traefik: $TRAEFIK_SERVICE"
echo ""

echo "=== Logs de Traefik (últimas 30 líneas) ==="
docker service logs "$TRAEFIK_SERVICE" --tail 30 2>&1 | tail -15
echo ""

echo "=== Buscar errores sobre dashboard ==="
docker service logs "$TRAEFIK_SERVICE" --tail 200 2>&1 | grep -i "dashboard\|checkin24hs\|error\|warn" | tail -10 || echo "(no hay errores)"
echo ""

echo "=== Verificar si Traefik tiene TLS configurado ==="
docker service inspect "$TRAEFIK_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -i "tls\|ssl\|cert" | head -5 || echo "(no hay TLS visible)"
echo ""

echo "=== Probar acceso directo al servicio ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        echo "Probando http://$CONTAINER_IP:3000"
        curl -s -o /dev/null -w "Status: %{http_code}\n" http://$CONTAINER_IP:3000 || echo "No conecta"
    fi
fi
echo ""
