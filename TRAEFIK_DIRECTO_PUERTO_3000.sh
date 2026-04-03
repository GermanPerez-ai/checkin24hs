#!/bin/bash
# Hacer que Traefik apunte directamente al puerto 3000

echo "=== 1. Obtener IP del host ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Host IP: $HOST_IP"

echo ""
echo "=== 2. Eliminar servicio proxy (ya no es necesario) ==="
docker service rm dashboard-proxy-service
sleep 3

echo ""
echo "=== 3. Crear servicio simple que solo tenga los labels de Traefik ==="
echo "Este servicio no hará nada, solo servirá para que Traefik tenga los labels"
docker service create \
  --name dashboard-service \
  --network easypanel \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label "traefik.http.services.dashboard.loadbalancer.server=http://$HOST_IP:3000" \
  --replicas 1 \
  alpine:latest \
  sh -c "while true; do sleep 3600; done"

if [ $? -eq 0 ]; then
    echo "✅ Servicio creado"
    
    echo ""
    echo "=== 4. Esperar 10 segundos ==="
    sleep 10
    
    echo ""
    echo "=== 5. Probar acceso al dashboard ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    
    echo ""
    echo "=== 6. Probar acceso HTTP (debería redirigir) ==="
    curl -L http://dashboard.checkin24hs.com 2>&1 | head -5
else
    echo "❌ Error al crear el servicio"
fi

