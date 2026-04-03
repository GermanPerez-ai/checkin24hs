#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR MOUNTS DEL SERVICIO"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar mounts en el servicio (método alternativo)
echo "=== 1. MOUNTS EN EL SERVICIO ==="
docker service inspect checkin24hs_dashboard --pretty 2>/dev/null | grep -A 20 -i "mount\|bind" | head -30
echo ""

# 2. Verificar en formato JSON (más fácil de parsear)
echo "=== 2. MOUNTS EN FORMATO JSON ==="
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}' 2>/dev/null | python3 -m json.tool 2>/dev/null || docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}' 2>/dev/null
echo ""

# 3. Verificar contenedor actual
echo "=== 3. VERIFICAR CONTENEDOR ACTUAL ==="
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo ""
    echo "Mounts del contenedor:"
    docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null
    echo ""
    
    if docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Source}}{{end}}' 2>/dev/null | grep -q "dashboard.html"; then
        echo "✅ El contenedor tiene un mount de dashboard.html"
    else
        echo "❌ El contenedor NO tiene mount de dashboard.html"
    fi
else
    echo "❌ No se encontró contenedor corriendo"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
