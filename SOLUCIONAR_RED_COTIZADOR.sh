#!/bin/bash
# Solucionar problema de red del servicio cotizador

echo "=== Solucionando problema de red del servicio cotizador ==="

# 1. Verificar redes de Traefik
echo ""
echo "1. Redes de Traefik:"
docker service inspect traefik | grep -A 10 Networks

# 2. Verificar red del servicio cotizador
echo ""
echo "2. Red del servicio cotizador:"
docker service inspect cotizador | grep -A 5 Networks

# 3. Obtener ID de la red easypanel (donde está Traefik)
echo ""
echo "3. Obteniendo ID de la red easypanel:"
EASYPANEL_NETWORK=$(docker network ls | grep easypanel | grep -v checkin24hs | awk '{print $1}' | head -1)
echo "Red easypanel: $EASYPANEL_NETWORK"

# 4. Verificar si el servicio está en esa red
echo ""
echo "4. Verificando si cotizador está en la red easypanel:"
docker service inspect cotizador | grep -A 5 Networks | grep -q "$EASYPANEL_NETWORK" && echo "✅ Está en la red correcta" || echo "❌ NO está en la red correcta"

# 5. Si no está, agregar el servicio a la red correcta
echo ""
echo "5. Agregando servicio a la red easypanel (si no está):"
docker service update --network-add $EASYPANEL_NETWORK cotizador

# 6. Esperar a que se actualice
echo ""
echo "6. Esperando 10 segundos para que se actualice..."
sleep 10

# 7. Verificar conectividad
echo ""
echo "7. Verificando conectividad desde Traefik:"
TRAEFIK_CONTAINER=$(docker ps | grep traefik | head -1 | awk '{print $1}')
docker exec $TRAEFIK_CONTAINER wget -O- http://cotizador:80 2>&1 | head -10

echo ""
echo "✅ Proceso completado"
