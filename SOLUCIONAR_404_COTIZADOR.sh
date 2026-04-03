#!/bin/bash
# Solucionar error 404 del cotizador después del deploy

SERVICE_NAME="checkin24hs_cotizador"
DOMAIN="cotizar.checkin24hs.com"

echo "=========================================="
echo "🔧 SOLUCIONAR 404 DEL COTIZADOR"
echo "=========================================="
echo ""

# 1. Verificar que el servicio existe
echo "=== 1. Verificar servicio ==="
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: El servicio $SERVICE_NAME no existe"
    echo "   Buscando servicios similares..."
    docker service ls | grep -i cotizador
    exit 1
fi
echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Verificar estado del servicio
echo "=== 2. Estado del servicio ==="
docker service ls | grep "$SERVICE_NAME"
echo ""

# 3. Verificar que está en la red easypanel
echo "=== 3. Verificar red easypanel ==="
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "✅ Servicio está en la red 'easypanel'"
else
    echo "⚠️  Servicio NO está en la red 'easypanel'"
    echo "   Agregando red 'easypanel'..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 5
    echo "✅ Red agregada"
fi
echo ""

# 4. Obtener puerto del servicio
echo "=== 4. Obtener puerto ==="
PORT=$(docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' | head -1)
if [ -z "$PORT" ]; then
    # Puerto por defecto del cotizador (nginx)
    PORT=80
    echo "⚠️  No se encontró puerto expuesto, usando puerto por defecto: $PORT"
else
    echo "✅ Puerto encontrado: $PORT"
fi
echo ""

# 5. Verificar labels de Traefik actuales
echo "=== 5. Labels de Traefik actuales ==="
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -i "traefik")
if [ -n "$TRAEFIK_LABELS" ]; then
    echo "Labels actuales:"
    echo "$TRAEFIK_LABELS"
else
    echo "⚠️  No se encontraron labels de Traefik"
fi
echo ""

# 6. Agregar/actualizar labels de Traefik
echo "=== 6. Agregar/actualizar labels de Traefik ==="
echo "Agregando labels..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.cotizador.loadbalancer.server.port=$PORT" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

# 7. Esperar a que el servicio se actualice
echo "=== 7. Esperando actualización del servicio ==="
sleep 10

# 8. Verificar que las labels se aplicaron
echo "=== 8. Verificar labels aplicadas ==="
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -i "traefik")
if [ -n "$TRAEFIK_LABELS" ]; then
    echo "✅ Labels de Traefik aplicadas:"
    echo "$TRAEFIK_LABELS"
else
    echo "❌ Error: Las labels no se aplicaron"
    exit 1
fi
echo ""

# 9. Reiniciar Traefik para que recargue la configuración
echo "=== 9. Reiniciar Traefik ==="
TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "Reiniciando Traefik ($TRAEFIK_SERVICE)..."
    docker service update --force "$TRAEFIK_SERVICE"
    echo "✅ Traefik reiniciado"
    echo "   Esperando 15 segundos para que Traefik recargue la configuración..."
    sleep 15
else
    echo "⚠️  No se encontró servicio de Traefik"
fi
echo ""

# 10. Verificar logs del contenedor
echo "=== 10. Verificar logs del cotizador ==="
CONTAINER_ID=$(docker service ps "$SERVICE_NAME" --no-trunc -q | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "Últimas 10 líneas de logs:"
    docker logs "$CONTAINER_ID" --tail 10 2>&1 | tail -10
else
    echo "⚠️  No se pudo obtener el ID del contenedor"
fi
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Espera 10-30 segundos adicionales"
echo "2. Prueba acceder a: https://$DOMAIN"
echo "3. Si aún hay problemas, verifica los logs de Traefik:"
echo "   docker service logs $TRAEFIK_SERVICE --tail 50"
echo ""
