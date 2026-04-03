#!/bin/bash
# Hacer que Traefik use el nombre del servicio directamente

echo "=== 1. Probar acceso usando el nombre del servicio ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://dashboard-proxy-service:80 2>&1 | head -5

echo ""
echo "=== 2. Si funciona, actualizar servicio para que Traefik use el nombre ==="
if [ $? -eq 0 ] || docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g nslookup dashboard-proxy-service 2>/dev/null | grep -q "Name:"; then
    echo "✅ El nombre se puede resolver"
    
    # Actualizar para usar el nombre del servicio
    docker service update \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://dashboard-proxy-service:80" \
      dashboard-proxy-service
    
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== 3. Probar acceso al dashboard ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ El nombre no se puede resolver"
    echo ""
    echo "=== Alternativa: Verificar si Traefik puede acceder directamente al puerto 3000 ==="
    HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "Probando acceso directo a $HOST_IP:3000 desde Traefik..."
    docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$HOST_IP:3000 2>&1 | head -5
    
    if [ $? -eq 0 ]; then
        echo "✅ Traefik puede acceder directamente al puerto 3000"
        echo "Actualizando servicio para que apunte directamente al puerto 3000..."
        docker service update \
          --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$HOST_IP:3000" \
          dashboard-proxy-service
        
        sleep 10
        curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    fi
fi

