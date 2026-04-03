#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICAR ERROR 404"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar si el servicio está corriendo
echo "=== 1. ESTADO DEL SERVICIO ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5
echo ""

# 2. Verificar contenedores corriendo
echo "=== 2. CONTENEDORES CORRIENDO ==="
docker ps --filter "name=dashboard" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 3. Verificar logs del servicio (últimas 30 líneas)
echo "=== 3. LOGS DEL SERVICIO (últimas 30 líneas) ==="
docker service logs checkin24hs_dashboard --tail 30 --no-trunc 2>&1 | tail -30
echo ""

# 4. Verificar si el contenedor está respondiendo
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "=== 4. VERIFICAR CONTENEDOR: $CONTAINER ==="
    
    # Ver logs del contenedor
    echo "Logs del contenedor:"
    docker logs "$CONTAINER" --tail 20 2>&1 | tail -20
    echo ""
    
    # Verificar proceso
    echo "Procesos en el contenedor:"
    docker exec "$CONTAINER" ps aux 2>/dev/null | head -5
    echo ""
    
    # Verificar puerto
    echo "Puerto del contenedor:"
    docker port "$CONTAINER" 2>/dev/null | head -3
    echo ""
    
    # Intentar curl desde dentro del contenedor
    echo "Prueba de conexión desde el contenedor:"
    docker exec "$CONTAINER" curl -s http://localhost:3000 2>&1 | head -5
    echo ""
else
    echo "❌ No hay contenedor corriendo"
fi
echo ""

# 5. Verificar Traefik
echo "=== 5. VERIFICAR TRAEFIK ==="
docker ps --filter "name=traefik" --format "table {{.Names}}\t{{.Status}}"
echo ""

# 6. Verificar bind mount (si está causando problemas)
if [ -n "$CONTAINER" ]; then
    echo "=== 6. VERIFICAR BIND MOUNT ==="
    docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null
    echo ""
    
    # Verificar si el archivo existe en el host
    if [ -f "/root/checkin24hs/dashboard.html" ]; then
        echo "✅ El archivo existe en el host"
        ls -lh /root/checkin24hs/dashboard.html | head -1
    else
        echo "❌ El archivo NO existe en el host"
    fi
    echo ""
fi

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
