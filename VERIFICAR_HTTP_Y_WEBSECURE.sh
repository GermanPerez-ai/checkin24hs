#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Probar HTTP (status code) ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "✅ HTTP funciona!"
else
    echo "⚠️  HTTP status: $HTTP_STATUS"
fi
echo ""

echo "=== Agregar label 'websecure' ==="
docker service update --label-add "traefik.http.routers.dashboard.entrypoints=websecure" "$SERVICE_NAME"
echo "✅ Label agregada"
echo ""

echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

echo "=== Verificar todas las labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Verificar entrypoints ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.routers.dashboard.entrypoints"}}{{$value}}{"\n"}}{{end}}'
echo ""

echo "=== Esperando 20 segundos adicionales ==="
sleep 20
echo ""

echo "=== Probar HTTP ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$DOMAIN
echo ""

echo "=== Probar HTTPS ==="
curl -s -o /dev/null -w "HTTPS Status: %{http_code}\n" https://$DOMAIN
echo ""
