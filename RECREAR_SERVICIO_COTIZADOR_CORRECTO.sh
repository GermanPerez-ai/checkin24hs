#!/bin/bash
# Recrear servicio cotizador desde cero con configuración correcta

echo "=== Recrear servicio cotizador desde cero ==="

# 1. Obtener la IP actual del contenedor
COTIZADOR_CONTAINER=$(docker ps | grep cotizador | head -1 | awk '{print $1}')
COTIZADOR_IP=$(docker inspect $COTIZADOR_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$conf.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor cotizador: $COTIZADOR_IP"

# 2. Eliminar el servicio actual
echo ""
echo "1. Eliminando servicio cotizador actual..."
docker service rm cotizador
sleep 5

# 3. Crear el servicio desde cero con todas las etiquetas correctas
echo ""
echo "2. Creando servicio cotizador con configuración correcta..."
docker service create \
  --name cotizador \
  --network easypanel \
  --replicas 1 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label "traefik.http.routers.cotizador.entrypoints=web" \
  --label "traefik.http.routers.cotizador.service=cotizador-service" \
  --label "traefik.http.routers.cotizador-secure.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label "traefik.http.routers.cotizador-secure.entrypoints=websecure" \
  --label "traefik.http.routers.cotizador-secure.service=cotizador-service" \
  --label "traefik.http.routers.cotizador-secure.tls=true" \
  --label "traefik.http.routers.cotizador-secure.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.cotizador-service.loadbalancer.server=${COTIZADOR_IP}:80" \
  --label "traefik.docker.network=easypanel" \
  cotizador:latest

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Servicio recreado correctamente"
    
    # 4. Esperar a que se inicie
    echo ""
    echo "3. Esperando 30 segundos para que el servicio se inicie..."
    sleep 30
    
    # 5. Obtener la nueva IP (puede ser diferente)
    NEW_CONTAINER=$(docker ps | grep cotizador | head -1 | awk '{print $1}')
    NEW_IP=$(docker inspect $NEW_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$conf.IPAddress}}{{end}}' | head -1)
    echo "Nueva IP del contenedor: $NEW_IP"
    
    # 6. Actualizar con la IP correcta si cambió
    if [ "$NEW_IP" != "$COTIZADOR_IP" ] && [ -n "$NEW_IP" ]; then
        echo ""
        echo "4. Actualizando con la nueva IP..."
        docker service update \
          --label-rm "traefik.http.services.cotizador-service.loadbalancer.server" \
          --label-add "traefik.http.services.cotizador-service.loadbalancer.server=${NEW_IP}:80" \
          cotizador
        
        sleep 10
    fi
    
    # 7. Verificar logs
    echo ""
    echo "5. Verificando logs de Traefik..."
    docker service logs traefik --since 30s 2>&1 | grep -i cotizar | tail -10
    
    # 8. Verificar etiquetas finales
    echo ""
    echo "6. Etiquetas finales:"
    docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort
    
    echo ""
    echo "✅ Servicio recreado. Prueba acceder a:"
    echo "   - http://cotizar.checkin24hs.com"
    echo "   - https://cotizar.checkin24hs.com"
else
    echo "❌ Error al recrear el servicio"
    exit 1
fi
