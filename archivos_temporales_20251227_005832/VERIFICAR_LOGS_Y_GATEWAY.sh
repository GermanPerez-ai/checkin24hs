#!/bin/bash
# Verificar logs de Traefik y probar con gateway

echo "=== 1. Ver logs recientes de Traefik ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 30 | grep -i "dashboard\|502\|error" | tail -10

echo ""
echo "=== 2. Obtener gateway de la red easypanel ==="
GATEWAY_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
echo "Gateway IP: $GATEWAY_IP"

echo ""
echo "=== 3. Probar acceso desde Traefik al gateway:3000 ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$GATEWAY_IP:3000 2>&1 | head -5

echo ""
echo "=== 4. Si funciona, actualizar servicio para usar gateway ==="
if [ $? -eq 0 ] || docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$GATEWAY_IP:3000 2>&1 | head -1 | grep -q "<!DOCTYPE"; then
    echo "✅ Gateway funciona"
    docker service update \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://$GATEWAY_IP:3000" \
      dashboard-service
    
    echo "✅ Servicio actualizado"
    sleep 10
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Gateway no funciona"
    echo ""
    echo "=== 5. Verificar configuración actual del servicio ==="
    docker service inspect dashboard-service --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik
fi

