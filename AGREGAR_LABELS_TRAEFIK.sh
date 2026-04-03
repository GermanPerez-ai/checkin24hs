#!/bin/bash
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

# Verificar red easypanel
echo "=== 1. Verificar red easypanel ==="
if docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{"\n"}}{{end}}' | grep -q "easypanel"; then
    echo "✅ Servicio está en la red 'easypanel'"
else
    echo "⚠️  Servicio NO está en la red 'easypanel'"
    echo "   Agregando red 'easypanel'..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 5
fi
echo ""

# Obtener puerto (asumimos 3000 si no hay puerto expuesto)
echo "=== 2. Obtener puerto ==="
PORT=$(docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' | head -1)
if [ -z "$PORT" ]; then
    PORT=3000
    echo "⚠️  No se encontró puerto expuesto, usando: $PORT"
else
    echo "✅ Puerto encontrado: $PORT"
fi
echo ""

# Agregar labels de Traefik
echo "=== 3. Agregar labels de Traefik ==="
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

# Esperar actualización
echo "=== 4. Esperando actualización (10 segundos) ==="
sleep 10

# Verificar labels aplicadas
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

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Espera 10-30 segundos para que Traefik detecte el cambio"
echo "2. Prueba: curl -I https://$DOMAIN"
echo "3. Si hay problemas, verifica logs de Traefik"
echo ""
