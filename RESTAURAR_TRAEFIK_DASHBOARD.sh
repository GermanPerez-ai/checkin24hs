#!/bin/bash
# Script para restaurar labels de Traefik después de redeploy (soluciona 404 en dashboard.checkin24hs.com)

echo "🔧 Restaurando labels de Traefik para dashboard..."
echo ""

SERVICE="checkin24hs_dashboard"

# Verificar que el servicio existe (aceptar con guión bajo o guión)
if ! docker service ls --format '{{.Name}}' | grep -qE "checkin24hs.dashboard|dashboard"; then
    echo "❌ Servicio tipo dashboard no encontrado. Listando servicios:"
    docker service ls --format '{{.Name}}' | grep -iE "dashboard|checkin"
    exit 1
fi

# Asegurar red easypanel (Traefik descubre por red)
echo "📡 Asegurando red easypanel..."
docker service update --network-add easypanel "$SERVICE" 2>/dev/null || true

echo "📋 Verificando labels actuales..."
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik || echo "⚠️  No hay labels de Traefik"

echo ""
echo "🔧 Agregando labels de Traefik..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
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
echo "⏳ Espera 30-60 segundos para que Traefik detecte los cambios."
echo ""
echo "✅ Configuración completada. Prueba:"
echo "   https://dashboard.checkin24hs.com/"
echo "   curl -I https://dashboard.checkin24hs.com/"
echo ""
echo "   Si sigue 404, ver docs/TRAEFIK_DASHBOARD_404.md"
