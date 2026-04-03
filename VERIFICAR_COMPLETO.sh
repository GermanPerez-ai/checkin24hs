#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR SERVICIO COMPLETO"
echo "=========================================="
echo ""

echo "=== 1. Estado del servicio ==="
docker service ls | grep "$SERVICE_NAME"
echo ""

echo "=== 2. Tareas del servicio ==="
docker service ps "$SERVICE_NAME" --no-trunc | head -3
echo ""

echo "=== 3. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor"
    docker ps | head -5
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 4. Verificar archivo ==="
if docker exec "$CONTAINER" test -f /app/dashboard.html; then
    echo "OK: Archivo encontrado"
else
    echo "ERROR: Archivo no encontrado"
    exit 1
fi
echo ""

echo "=== 5. Extraer version ==="
docker exec "$CONTAINER" cat /app/dashboard.html | grep -E "DASHBOARD_VERSION|DASHBOARD_BUILD_NUMBER|DASHBOARD_BUILD" | head -3
echo ""

echo "=== 6. Verificar display de version ==="
docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "version-display" && echo "OK: Display encontrado" || echo "ERROR: Display no encontrado"
echo ""

echo "=== 7. Verificar correcciones ==="
docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "Mes/Año" && echo "OK: Correcciones aplicadas" || echo "ERROR: Correcciones no encontradas"
echo ""

echo "=== 8. Verificar labels de Traefik ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== 9. Probar HTTP/HTTPS ==="
echo "HTTP: $(curl -s -o /dev/null -w '%{http_code}' http://$DOMAIN)"
echo "HTTPS: $(curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN)"
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
