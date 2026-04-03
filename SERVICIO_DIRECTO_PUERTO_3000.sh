#!/bin/bash
# Hacer que el servicio Swarm apunte directamente al puerto 3000

echo "=== Obtener IP del host en la red Docker ==="
# Usar la IP del gateway que sabemos que funciona
GATEWAY_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
echo "Gateway IP: $GATEWAY_IP"

# Obtener IP del host
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Host IP: $HOST_IP"

echo ""
echo "=== Actualizar servicio para que apunte directamente al puerto 3000 ==="
# Probar primero con el gateway
docker service update \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$GATEWAY_IP:3000" \
  dashboard-proxy-service

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado con gateway IP"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    
    # Si no funciona, probar con host.docker.internal
    if curl -I https://dashboard.checkin24hs.com 2>&1 | grep -q "502"; then
        echo ""
        echo "⚠️  No funcionó con gateway. Probando con host.docker.internal..."
        docker service update \
          --label-add "traefik.http.services.dashboard.loadbalancer.server=http://host.docker.internal:3000" \
          dashboard-proxy-service
        
        sleep 10
        curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    fi
else
    echo "❌ Error al actualizar el servicio"
fi

