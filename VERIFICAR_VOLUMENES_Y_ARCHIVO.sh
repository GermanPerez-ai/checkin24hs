#!/bin/bash
# Script para verificar volúmenes y el archivo en el contenedor

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "VERIFICAR VOLUMENES Y ARCHIVO"
echo "=========================================="
echo ""

echo "=== 1. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 2. Verificar si el archivo existe ==="
if docker exec "$CONTAINER" test -f /app/dashboard.html; then
    echo "✅ Archivo existe"
    SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
    echo "   Tamaño: $SIZE bytes"
    if [ "$SIZE" -eq 0 ]; then
        echo "   ⚠️ ADVERTENCIA: Archivo está vacío (0 bytes)"
    fi
else
    echo "❌ Archivo NO existe"
fi
echo ""

echo "=== 3. Verificar volúmenes montados en el servicio ==="
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}}:{{.Destination}} ({{.Type}}){{"\n"}}{{end}}'
echo ""

echo "=== 4. Verificar volúmenes en el contenedor ==="
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Source}}:{{.Destination}} ({{.Type}}){{"\n"}}{{end}}'
echo ""

echo "=== 5. Listar archivos en /app ==="
docker exec "$CONTAINER" ls -lah /app/ | head -10
echo ""

echo "=== 6. Verificar imagen Docker usada ==="
docker inspect "$CONTAINER" --format '{{.Config.Image}}'
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
