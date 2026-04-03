#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Agregar router HTTPS con TLS ==="
docker service update \
  --label-add "traefik.http.routers.dashboard-https.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard-https.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-https.service=dashboard" \
  --label-add "traefik.http.routers.dashboard-https.tls=true" \
  --label-add "traefik.http.routers.dashboard-https.tls.certresolver=letsencrypt" \
  "$SERVICE_NAME"

echo "✅ Router HTTPS agregado"
echo ""

echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

echo "=== Verificar labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Esperando 30 segundos (Let's Encrypt puede tardar) ==="
sleep 30
echo ""

echo "=== Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "✅ HTTPS funciona!"
elif [ "$HTTPS_STATUS" = "404" ]; then
    echo "⚠️  HTTPS aún da 404"
    echo "Let's Encrypt puede estar generando el certificado (puede tardar 1-2 minutos)"
    echo "Prueba de nuevo en unos minutos"
else
    echo "⚠️  Status: $HTTPS_STATUS"
fi
echo ""
