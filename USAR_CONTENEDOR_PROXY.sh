#!/bin/bash
# Hacer que Traefik use el contenedor proxy

echo "=== 1. Obtener IP del contenedor proxy ==="
PROXY_IP=$(docker inspect dashboard-nginx-proxy --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor proxy: $PROXY_IP"

echo ""
echo "=== 2. Actualizar servicio para que apunte al contenedor proxy ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$PROXY_IP:80" \
  checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Error. Intentando otra solución..."
    echo ""
    echo "=== Opción alternativa: Usar el nombre del contenedor ==="
    docker service update \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://dashboard-nginx-proxy:80" \
      checkin24hs_dashboard
fi

