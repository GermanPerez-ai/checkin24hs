#!/bin/bash
# Eliminar y recrear servicio cotizador con configuración correcta

echo "=== Eliminar y recrear servicio cotizador ==="

# 1. Eliminar el servicio actual
echo ""
echo "1. Eliminando servicio cotizador actual..."
docker service rm cotizador
sleep 5

# 2. Obtener la IP que funciona (tasks.cotizador resuelve a 10.0.1.143)
# Pero mejor, usar tasks.cotizador directamente si es posible, o usar la IP actual
# Primero crear el servicio, luego obtener su IP y actualizar

# 3. Crear el servicio desde cero con etiquetas correctas (sin IP todavía)
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
  --label "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  --label "traefik.docker.network=easypanel" \
  cotizador:latest

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Servicio creado"
    
    # 4. Esperar a que se inicie
    echo ""
    echo "3. Esperando 20 segundos para que el servicio se inicie..."
    sleep 20
    
    # 5. Obtener la IP del nuevo contenedor
    NEW_CONTAINER=$(docker ps | grep cotizador | head -1 | awk '{print $1}')
    NEW_IP=$(docker inspect $NEW_CONTAINER | grep -A 20 Networks | grep -A 5 '"easypanel"' | grep IPAddress | head -1 | awk '{print $2}' | tr -d '",')
    echo "IP del nuevo contenedor: $NEW_IP"
    
    # 6. Actualizar con la IP correcta (formato como webmail)
    if [ -n "$NEW_IP" ]; then
        echo ""
        echo "4. Actualizando con la IP: ${NEW_IP}:80"
        docker service update \
          --label-rm "traefik.http.services.cotizador-service.loadbalancer.server.port" \
          --label-add "traefik.http.services.cotizador-service.loadbalancer.server=${NEW_IP}:80" \
          cotizador
        
        sleep 10
    fi
    
    # 7. Verificar logs
    echo ""
    echo "5. Verificando logs de Traefik (esperando 20 segundos más)..."
    sleep 20
    docker service logs traefik --since 30s 2>&1 | grep -i cotizar | tail -10 || echo "No hay logs de cotizar aún"
    
    # 8. Verificar etiquetas finales
    echo ""
    echo "6. Etiquetas finales:"
    docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort
    
    echo ""
    echo "✅ Servicio recreado. Prueba acceder a:"
    echo "   - http://cotizar.checkin24hs.com"
    echo "   - https://cotizar.checkin24hs.com"
else
    echo "❌ Error al crear el servicio"
    exit 1
fi
