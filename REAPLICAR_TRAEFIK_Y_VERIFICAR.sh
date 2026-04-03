#!/bin/bash
# Reaplicar labels de Traefik y verificar

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "REAPLICAR TRAEFIK Y VERIFICAR"
echo "=========================================="
echo ""

echo "=== Paso 1: Agregar labels de Traefik ==="
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

if [ $? -eq 0 ]; then
    echo "OK: Labels agregadas"
else
    echo "ERROR: Error al agregar labels"
    exit 1
fi
echo ""

echo "=== Paso 2: Verificar labels aplicadas ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Paso 3: Esperar 20 segundos para Traefik ==="
sleep 20
echo ""

echo "=== Paso 4: Probar HTTP ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "OK: HTTP funciona!"
elif [ "$HTTP_STATUS" = "404" ]; then
    echo "ADVERTENCIA: HTTP aun da 404. Esperando mas tiempo..."
    sleep 20
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
    echo "HTTP Status despues de esperar: $HTTP_STATUS"
else
    echo "ADVERTENCIA: HTTP Status: $HTTP_STATUS"
fi
echo ""

echo "=== Paso 5: Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "OK: HTTPS funciona!"
elif [ "$HTTPS_STATUS" = "404" ]; then
    echo "ADVERTENCIA: HTTPS aun da 404. Let's Encrypt puede estar generando el certificado."
    echo "   Espera 1-2 minutos y prueba de nuevo."
else
    echo "ADVERTENCIA: HTTPS Status: $HTTPS_STATUS"
fi
echo ""

echo "=========================================="
echo "OK: Proceso completado"
echo "=========================================="
echo ""
echo "NOTA: Si aun da 404 despues de 1-2 minutos:"
echo "1. Verifica que el servicio este corriendo: docker service ps $SERVICE_NAME"
echo "2. Verifica los logs: docker service logs $SERVICE_NAME --tail 20"
echo "3. Recarga la pagina con Ctrl+F5"
echo ""
