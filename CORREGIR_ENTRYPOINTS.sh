#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Eliminar label de entrypoints actual ==="
docker service update --label-rm "traefik.http.routers.dashboard.entrypoints" "$SERVICE_NAME" 2>/dev/null || true
sleep 5
echo ""

echo "=== Agregar label con AMBOS entrypoints (web,websecure) ==="
docker service update --label-add "traefik.http.routers.dashboard.entrypoints=web,websecure" "$SERVICE_NAME"
echo "✅ Label agregada"
echo ""

echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

echo "=== Verificar labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Verificar entrypoints ==="
ENTRYPOINTS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.routers.dashboard.entrypoints"}}{{$value}}{{end}}{{end}}')
echo "Entrypoints: $ENTRYPOINTS"
echo ""

echo "=== Esperando 20 segundos adicionales ==="
sleep 20
echo ""

echo "=== Probar HTTP ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
echo ""

echo "=== Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
echo ""
