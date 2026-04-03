#!/bin/bash
# Conectar el servicio a la red easypanel donde está Traefik

echo "=== 1. Verificar red easypanel ==="
docker network inspect easypanel --format '{{.Id}}' && echo "✅ Red easypanel existe"

echo ""
echo "=== 2. Actualizar servicio para que esté en la red easypanel ==="
docker service update \
  --network-add easypanel \
  dashboard-proxy-service

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    
    echo ""
    echo "=== 3. Esperar 10 segundos para que se propague ==="
    sleep 10
    
    echo ""
    echo "=== 4. Verificar que ahora está en la red correcta ==="
    docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.NetworkID}} {{end}}'
    
    echo ""
    echo "=== 5. Obtener nueva VIP en la red easypanel ==="
    EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}')
    VIP=$(docker service inspect dashboard-proxy-service --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" | cut -d/ -f1)
    echo "VIP en easypanel: $VIP"
    
    echo ""
    echo "=== 6. Probar acceso desde Traefik ==="
    docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$VIP:80 2>&1 | head -5
    
    echo ""
    echo "=== 7. Si funciona, actualizar servicio con la nueva VIP ==="
    if [ -n "$VIP" ]; then
        docker service update \
          --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$VIP:80" \
          dashboard-proxy-service
        
        echo "✅ Servicio actualizado con nueva VIP"
        echo ""
        echo "Esperando 10 segundos..."
        sleep 10
        
        echo ""
        echo "=== 8. Probar acceso al dashboard ==="
        curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    fi
else
    echo "❌ Error al actualizar el servicio"
fi

