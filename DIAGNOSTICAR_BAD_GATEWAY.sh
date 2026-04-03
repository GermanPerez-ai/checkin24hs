#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE BAD GATEWAY"
echo "=========================================="
echo ""

# 1. Verificar contenedores de WhatsApp
echo "=== 1. Estado de contenedores de WhatsApp ==="
WHATSAPP_CONTAINERS=($(docker ps -a --filter "name=whatsapp" --format "{{.Names}}"))
for container in "${WHATSAPP_CONTAINERS[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "no encontrado")
    echo "  $container: $STATUS"
done
echo ""

# 2. Ver logs recientes de cada contenedor
echo "=== 2. Logs recientes (últimas 20 líneas) ==="
for container in "${WHATSAPP_CONTAINERS[@]}"; do
    echo ""
    echo "--- Logs de $container ---"
    docker logs "$container" --tail 20 2>&1 | tail -20
done
echo ""

# 3. Verificar si hay errores de sintaxis en el archivo
echo "=== 3. Verificando sintaxis del archivo ==="
for container in "${WHATSAPP_CONTAINERS[@]}"; do
    echo ""
    echo "--- Verificando $container ---"
    # Intentar ejecutar node con check de sintaxis
    docker exec "$container" node -c /app/whatsapp-server.js 2>&1 || echo "⚠️ Error de sintaxis detectado"
done
echo ""

# 4. Verificar puertos
echo "=== 4. Puertos en uso ==="
docker ps --filter "name=whatsapp" --format "table {{.Names}}\t{{.Ports}}"
echo ""

# 5. Verificar si los servicios responden localmente
echo "=== 5. Probando respuesta local de los servicios ==="
for container in "${WHATSAPP_CONTAINERS[@]}"; do
    PORT=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostPort}}{{end}}' "$container" 2>/dev/null | head -1)
    if [ ! -z "$PORT" ]; then
        echo "Probando contenedor $container en puerto $PORT..."
        timeout 3 docker exec "$container" wget -q -O- http://localhost:3001/health 2>/dev/null || echo "  ⚠️ No responde en /health"
        timeout 3 docker exec "$container" wget -q -O- http://localhost:3001/api/status 2>/dev/null || echo "  ⚠️ No responde en /api/status"
    fi
done
echo ""

# 6. Verificar contenedor del dashboard
echo "=== 6. Estado del contenedor del dashboard ==="
DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "  Dashboard: $DASHBOARD_CONTAINER"
    STATUS=$(docker inspect --format='{{.State.Status}}' "$DASHBOARD_CONTAINER" 2>/dev/null || echo "no encontrado")
    echo "  Estado: $STATUS"
    echo ""
    echo "  Últimas 10 líneas de logs:"
    docker logs "$DASHBOARD_CONTAINER" --tail 10 2>&1 | tail -10
else
    echo "  ⚠️ No se encontró contenedor del dashboard"
fi
echo ""

# 7. Verificar Traefik
echo "=== 7. Estado de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "  Traefik: $TRAEFIK_CONTAINER"
    echo "  Últimas 10 líneas de logs:"
    docker logs "$TRAEFIK_CONTAINER" --tail 10 2>&1 | tail -10
else
    echo "  ⚠️ No se encontró contenedor de Traefik"
fi
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Si algún contenedor está 'Exited' o 'Restarting', necesita atención."
echo "Si hay errores de sintaxis, el archivo necesita corrección."
echo ""
