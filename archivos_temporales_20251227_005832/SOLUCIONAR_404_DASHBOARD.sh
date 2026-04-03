#!/bin/bash

echo "=========================================="
echo "Solucionar Error 404 Dashboard"
echo "=========================================="
echo ""

# 1. Verificar que el servicio existe y está corriendo
echo "=== PASO 1: Verificar servicio ==="
SERVICE_EXISTS=$(docker service ls | grep checkin24hs_dashboard | wc -l)
if [ "$SERVICE_EXISTS" -eq 0 ]; then
    echo "❌ El servicio checkin24hs_dashboard no existe"
    echo "Necesitas crearlo primero en EasyPanel"
    exit 1
fi

docker service ps checkin24hs_dashboard --no-trunc | head -5
echo ""

# 2. Verificar etiquetas de Traefik
echo "=== PASO 2: Verificar etiquetas Traefik ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

# 3. Verificar que Traefik está en la misma red
echo "=== PASO 3: Verificar redes ==="
DASHBOARD_NETWORKS=$(docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}')
TRAEFIK_NETWORKS=$(docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}')

echo "Redes del dashboard: $DASHBOARD_NETWORKS"
echo "Redes de Traefik: $TRAEFIK_NETWORKS"

# Verificar si están en la misma red
COMMON_NETWORK=$(echo "$DASHBOARD_NETWORKS $TRAEFIK_NETWORKS" | tr ' ' '\n' | sort | uniq -d)
if [ -z "$COMMON_NETWORK" ]; then
    echo "⚠️  No están en la misma red"
    echo "Agregando dashboard a la red de Traefik..."
    EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
    if [ ! -z "$EASYPANEL_NET" ]; then
        docker service update --network-add $EASYPANEL_NET checkin24hs_dashboard
        echo "✅ Red agregada"
    fi
else
    echo "✅ Están en la misma red: $COMMON_NETWORK"
fi
echo ""

# 4. Verificar que el servicio tiene las etiquetas correctas
echo "=== PASO 4: Agregar/Verificar etiquetas Traefik ==="
HAS_TRAEFIK_ENABLE=$(docker service inspect checkin24hs_dashboard --format '{{.Spec.Labels.traefik.enable}}')
if [ -z "$HAS_TRAEFIK_ENABLE" ] || [ "$HAS_TRAEFIK_ENABLE" != "true" ]; then
    echo "Agregando etiquetas Traefik..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard.entrypoints=web" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
      checkin24hs_dashboard
    echo "✅ Etiquetas agregadas"
else
    echo "✅ Etiquetas ya configuradas"
fi
echo ""

# 5. Verificar que el servicio está respondiendo
echo "=== PASO 5: Verificar que el servicio responde ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Probando http://localhost:3000 desde el contenedor:"
    docker exec $CONTAINER_ID wget -qO- http://localhost:3000 2>&1 | head -3
    echo ""
    
    # Obtener IP del contenedor
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
    echo "IP del contenedor: $CONTAINER_IP"
    echo "Probando desde el host:"
    curl -I http://$CONTAINER_IP:3000 2>&1 | head -5
else
    echo "⚠️  No se encontró contenedor corriendo"
fi
echo ""

# 6. Esperar a que Traefik detecte los cambios
echo "=== PASO 6: Esperar detección de Traefik ==="
echo "Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 7. Verificar logs de Traefik
echo ""
echo "=== PASO 7: Verificar logs de Traefik ==="
docker service logs traefik --tail 20 2>&1 | grep -i dashboard | tail -5 || echo "No hay logs recientes de dashboard"
echo ""

# 8. Probar acceso
echo "=== PASO 8: Probar acceso ==="
echo "Probando http://dashboard.checkin24hs.com:"
curl -I http://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Si sigue dando 404, verifica:"
echo "1. Que el DNS apunta correctamente: dig dashboard.checkin24hs.com"
echo "2. Que Traefik está corriendo: docker service ps traefik"
echo "3. Que el servicio está corriendo: docker service ps checkin24hs_dashboard"
echo ""




