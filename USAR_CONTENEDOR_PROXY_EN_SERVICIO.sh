#!/bin/bash
# Hacer que el servicio apunte al contenedor proxy

echo "=== Obtener IP del contenedor proxy ==="
PROXY_IP=$(docker inspect dashboard-nginx-proxy --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor proxy: $PROXY_IP"

echo ""
echo "=== Actualizar servicio para que apunte al contenedor proxy ==="
docker service update \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$PROXY_IP:80" \
  dashboard-proxy-service

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Error. Intentando con el nombre del contenedor..."
    docker service update \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://dashboard-nginx-proxy:80" \
      dashboard-proxy-service
fi

