#!/bin/bash
# Agregar labels de Traefik manualmente al servicio checkin24hs_dashboard

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔧 AGREGAR LABELS DE TRAEFIK"
echo "=========================================="
echo ""

# Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: El servicio $SERVICE_NAME no existe"
    exit 1
fi

echo "Servicio: $SERVICE_NAME"
echo "Dominio: $DOMAIN"
echo ""

# Verificar que el servicio está en la red easypanel
echo "=== 1. Verificar red ==="
if docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{"\n"}}{{end}}' | grep -q "easypanel"; then
    echo "✅ Servicio está en la red 'easypanel'"
else
    echo "⚠️  Servicio NO está en la red 'easypanel'"
    echo "   Agregando red 'easypanel'..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 5
fi
echo ""

# Obtener el puerto del servicio
echo "=== 2. Obtener puerto del servicio ==="
PORT=$(docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' | head -1)
if [ -z "$PORT" ]; then
    # Si no hay puerto expuesto, asumimos que es 3000 (puerto interno del dashboard)
    PORT=3000
    echo "⚠️  No se encontró puerto expuesto, usando puerto por defecto: $PORT"
else
    echo "✅ Puerto encontrado: $PORT"
fi
echo ""

# Agregar labels de Traefik
echo "=== 3. Agregar labels de Traefik ==="
echo "Agregando labels..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$PORT" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

# Esperar a que el servicio se actualice
echo "=== 4. Esperando actualización del servicio ==="
sleep 10

# Verificar que las labels se aplicaron
echo "=== 5. Verificar labels aplicadas ==="
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -i "traefik")
if [ -n "$TRAEFIK_LABELS" ]; then
    echo "✅ Labels de Traefik aplicadas:"
    echo "$TRAEFIK_LABELS"
else
    echo "❌ Error: Las labels no se aplicaron"
    exit 1
fi
echo ""

# Verificar que Traefik detectó el servicio
echo "=== 6. Verificar que Traefik detectó el servicio ==="
sleep 5
if docker service ls | grep -qi "traefik"; then
    TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
    echo "✅ Traefik está corriendo (servicio: $TRAEFIK_SERVICE)"
    echo ""
    echo "Espera 10-30 segundos para que Traefik detecte el nuevo servicio"
    echo "Luego prueba: curl -I https://$DOMAIN"
else
    echo "⚠️  Traefik no está corriendo como servicio"
    echo "   Verifica que Traefik esté instalado y corriendo"
fi
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Espera 10-30 segundos"
echo "2. Prueba: curl -I https://$DOMAIN"
echo "3. Si aún hay problemas, verifica los logs de Traefik:"
echo "   docker service logs $TRAEFIK_SERVICE --tail 50"
echo ""
