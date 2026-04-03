#!/bin/bash
# Actualizar servicio para que use el nombre del contenedor

echo "=== Actualizar servicio para usar el nombre del contenedor ==="
docker service update \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://dashboard-nginx-proxy:80" \
  dashboard-proxy-service

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 10 segundos para que Traefik actualice..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    
    echo ""
    echo "=== Probar acceso HTTP (debería redirigir) ==="
    curl -L http://dashboard.checkin24hs.com 2>&1 | head -5
else
    echo "❌ Error al actualizar el servicio"
fi

