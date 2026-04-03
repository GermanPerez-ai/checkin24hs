#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR ESTADO DEL SERVICIO"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar contenedores corriendo
echo "=== 1. CONTENEDORES CORRIENDO ==="
docker ps --filter "name=dashboard" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
echo ""

# 2. Verificar servicio de Docker Swarm
echo "=== 2. SERVICIO DOCKER SWARM ==="
docker service ps checkin24hs_dashboard --no-trunc | head -10
echo ""

# 3. Verificar mounts en el servicio
echo "=== 3. MOUNTS DEL SERVICIO ==="
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

# 4. Verificar contenedor actual (si existe)
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "=== 4. MOUNTS DEL CONTENEDOR ACTUAL ==="
    echo "Contenedor: $CONTAINER"
    docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null
    echo ""
    
    echo "=== 5. VERIFICAR ESTRUCTURA DEL HEADER ==="
    docker exec "$CONTAINER" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9
else
    echo "⚠️  No hay contenedores corriendo"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
