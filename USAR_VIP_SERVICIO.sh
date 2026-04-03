#!/bin/bash
# Usar la Virtual IP del servicio Swarm

echo "=== 1. Obtener Virtual IP del servicio ==="
VIP=$(docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID "lvb2r5b5m4ls3y2jwaj9n2nne"}}{{.Addr}}{{end}}{{end}}' | cut -d/ -f1)
echo "VIP: $VIP"

# Si no funciona, obtener todas las VIPs
if [ -z "$VIP" ]; then
    echo "Obteniendo todas las VIPs..."
    docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.Addr}} en red {{.NetworkID}}{{"\n"}}{{end}}'
    VIP=$(docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' | head -1 | cut -d/ -f1)
fi

echo "VIP a usar: $VIP"

echo ""
echo "=== 2. Probar acceso desde Traefik usando VIP ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$VIP:80 2>&1 | head -5

echo ""
echo "=== 3. Si funciona, actualizar servicio para usar VIP ==="
if [ -n "$VIP" ]; then
    docker service update \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$VIP:80" \
      dashboard-proxy-service
    
    echo "✅ Servicio actualizado con VIP"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ No se pudo obtener VIP"
fi

