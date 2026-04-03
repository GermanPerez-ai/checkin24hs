#!/bin/bash
# Verificar estado actual del servicio y obtener contenedor correcto

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR SERVICIO ACTUAL"
echo "=========================================="
echo ""

echo "=== 1. Verificar estado del servicio ==="
docker service ls | grep "$SERVICE_NAME"
echo ""

echo "=== 2. Verificar tareas del servicio ==="
docker service ps "$SERVICE_NAME" --no-trunc | head -5
echo ""

echo "=== 3. Obtener contenedor activo (método 1) ==="
CONTAINER1=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
echo "Contenedor (método 1): $CONTAINER1"
echo ""

echo "=== 4. Obtener contenedor activo (método 2) ==="
CONTAINER2=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
echo "Contenedor (método 2): $CONTAINER2"
echo ""

echo "=== 5. Obtener contenedor activo (método 3) ==="
CONTAINER3=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
echo "Contenedor (método 3): $CONTAINER3"
echo ""

# Usar el primer contenedor que exista
CONTAINER=""
if [ -n "$CONTAINER1" ] && docker ps --format "{{.Names}}" | grep -q "$CONTAINER1"; then
    CONTAINER="$CONTAINER1"
elif [ -n "$CONTAINER2" ]; then
    CONTAINER="$CONTAINER2"
elif [ -n "$CONTAINER3" ]; then
    CONTAINER="$CONTAINER3"
fi

if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se pudo encontrar contenedor activo"
    echo ""
    echo "=== Listar todos los contenedores ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | head -10
    exit 1
fi

echo "=== 6. Usando contenedor: $CONTAINER ==="
echo ""

echo "=== 7. Verificar archivo dashboard.html ==="
if docker exec "$CONTAINER" test -f /app/dashboard.html; then
    echo "OK: Archivo encontrado"
else
    echo "ERROR: Archivo no encontrado en /app/dashboard.html"
    echo "Buscando en otras ubicaciones..."
    docker exec "$CONTAINER" find / -name "dashboard.html" 2>/dev/null | head -5
    exit 1
fi
echo ""

echo "=== 8. Extraer version del archivo ==="
VERSION=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -E "window\.DASHBOARD_VERSION\s*=" | head -1 | sed "s/.*'\([^']*\)'.*/\1/" || echo "No encontrada")
BUILD_NUMBER=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -E "window\.DASHBOARD_BUILD_NUMBER\s*=" | head -1 | sed "s/.*=\s*\([0-9]*\).*/\1/" || echo "No encontrada")
BUILD_TIMESTAMP=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -E "window\.DASHBOARD_BUILD\s*=" | head -1 | sed "s/.*'\([^']*\)'.*/\1/" || echo "No encontrada")

echo "Version: $VERSION"
echo "Build Number: #$BUILD_NUMBER"
echo "Build Timestamp: $BUILD_TIMESTAMP"
echo ""

echo "=== 9. Verificar display de version ==="
HAS_DISPLAY=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "version-display" || echo "0")
if [ "$HAS_DISPLAY" -gt "0" ]; then
    echo "OK: Display de version encontrado ($HAS_DISPLAY ocurrencias)"
else
    echo "ERROR: Display de version NO encontrado"
fi
echo ""

echo "=== 10. Verificar correcciones ==="
CORRECCIONES=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "Mes/Año\|Ubicación\|¿Cómo\|Confirmación\|Estadía" || echo "0")
echo "Correcciones encontradas: $CORRECCIONES"
if [ "$CORRECCIONES" -gt "0" ]; then
    echo "OK: Correcciones aplicadas"
else
    echo "ADVERTENCIA: No se encontraron correcciones"
fi
echo ""

echo "=== 11. Verificar labels de Traefik ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== 12. Probar HTTP ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
echo ""

echo "=== 13. Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER"
echo "Version: $VERSION"
echo "Build: #$BUILD_NUMBER"
echo "Display de version: $([ "$HAS_DISPLAY" -gt "0" ] && echo "OK" || echo "NO")"
echo "Correcciones: $([ "$CORRECCIONES" -gt "0" ] && echo "OK" || echo "NO")"
echo "HTTP: $HTTP_STATUS"
echo "HTTPS: $HTTPS_STATUS"
echo ""
