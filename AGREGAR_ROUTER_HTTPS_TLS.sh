#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔧 AGREGAR ROUTER HTTPS CON TLS"
echo "=========================================="
echo ""

# Verificar labels actuales
echo "=== Labels actuales ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Agregar router HTTPS con TLS
echo "=== Agregar router HTTPS con TLS ==="
echo "Agregando router 'dashboard-https' para HTTPS..."

docker service update \
  --label-add "traefik.http.routers.dashboard-https.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard-https.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-https.service=dashboard" \
  --label-add "traefik.http.routers.dashboard-https.tls=true" \
  --label-add "traefik.http.routers.dashboard-https.tls.certresolver=letsencrypt" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Router HTTPS con TLS agregado"
else
    echo "❌ Error al agregar router"
    exit 1
fi
echo ""

# Esperar actualización
echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

# Verificar labels después
echo "=== Labels después de agregar router HTTPS ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Esperar más tiempo para Let's Encrypt
echo "=== Esperando 30 segundos (Let's Encrypt puede tardar) ==="
sleep 30
echo ""

# Probar ambos
echo "=== Probar acceso ==="
echo "HTTP:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "  Status: $HTTP_STATUS"
echo ""

echo "HTTPS:"
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "  Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "  ✅ HTTPS funciona!"
elif [ "$HTTPS_STATUS" = "404" ]; then
    echo "  ⚠️  HTTPS aún da 404"
    echo "  Puede que Let's Encrypt esté generando el certificado (puede tardar 1-2 minutos)"
    echo "  Prueba de nuevo en unos minutos"
else
    echo "  ⚠️  HTTPS status: $HTTPS_STATUS"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
