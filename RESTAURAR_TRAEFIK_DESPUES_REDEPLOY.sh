#!/bin/bash
# Script para restaurar labels de Traefik después de redeploy

echo "🔧 Restaurando labels de Traefik para dashboard..."
echo ""

SERVICE="checkin24hs_dashboard"

# Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE"; then
    echo "❌ Servicio $SERVICE no encontrado"
    echo "Servicios disponibles:"
    docker service ls | grep -i dashboard
    exit 1
fi

echo "📋 Verificando labels actuales..."
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik || echo "⚠️  No hay labels de Traefik"

echo ""
echo "🔧 Agregando labels de Traefik..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  $SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi

echo ""
echo "📋 Verificando labels después de agregar..."
sleep 5
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""
echo "⏳ Espera 30-60 segundos para que Traefik detecte los cambios..."
echo ""
echo "✅ Configuración completada. Prueba acceder a:"
echo "   https://dashboard.checkin24hs.com"
echo ""
echo "🧪 Para verificar logs de Traefik:"
echo "   docker service logs traefik --tail 50 | grep dashboard"
