#!/bin/bash
# Eliminar servicio Swarm y usar solo el contenedor con labels

echo "=== 1. Eliminar servicio Swarm ==="
docker service rm checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio eliminado"
    
    echo ""
    echo "=== 2. Esperar 10 segundos para que Traefik actualice ==="
    sleep 10
    
    echo ""
    echo "=== 3. Verificar que el contenedor proxy tenga los labels correctos ==="
    docker inspect dashboard-nginx-proxy | grep -A 10 '"Labels"'
    
    echo ""
    echo "=== 4. Ver logs de Traefik para ver si detecta el contenedor ==="
    docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 20 | grep -i dashboard || echo "No hay logs recientes"
    
    echo ""
    echo "=== 5. Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    
    echo ""
    echo "✅ Si funciona, el dashboard debería estar accesible!"
else
    echo "❌ Error al eliminar el servicio"
fi

