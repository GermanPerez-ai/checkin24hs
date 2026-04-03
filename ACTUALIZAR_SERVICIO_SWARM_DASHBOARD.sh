#!/bin/bash
# Actualizar servicio Swarm para que use el contenedor proxy

echo "=== Opción 1: Actualizar el servicio para que apunte al puerto 3000 del host ==="
echo "Esto actualizará el servicio para que Traefik apunte directamente al puerto 3000"

# Obtener la IP del host
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

echo "IP del host: $HOST_IP"

# Actualizar el servicio con labels de Traefik que apunten al puerto 3000
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=80" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$HOST_IP:3000" \
  checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 10 segundos para que se propague..."
    sleep 10
    
    echo ""
    echo "=== Verificar ==="
    docker service ps checkin24hs_dashboard
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Error al actualizar el servicio"
    echo ""
    echo "=== Opción 2: Eliminar el servicio y usar solo el contenedor ==="
    echo "docker service rm checkin24hs_dashboard"
fi

