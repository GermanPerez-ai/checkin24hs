#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Agregar labels de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web,websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.http.routers.dashboard-https.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard-https.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-https.service=dashboard" \
  --label-add "traefik.http.routers.dashboard-https.tls=true" \
  --label-add "traefik.http.routers.dashboard-https.tls.certresolver=letsencrypt" \
  "$SERVICE_NAME"

echo "✅ Labels agregadas"
echo ""
echo "=== Esperando 20 segundos ==="
sleep 20
echo ""
echo "=== Verificar labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""
echo "=== Probar HTTP ==="
curl -I http://$DOMAIN 2>&1 | head -5
echo ""
echo "=== Probar HTTPS ==="
curl -I https://$DOMAIN 2>&1 | head -5
echo ""
echo "✅ Completado. Recarga la página con Ctrl+F5"
