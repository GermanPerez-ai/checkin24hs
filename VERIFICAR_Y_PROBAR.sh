#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Verificar todas las labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Esperando 15 segundos para Traefik ==="
sleep 15
echo ""

echo "=== Probar HTTP ==="
curl -I http://$DOMAIN 2>&1 | head -5
echo ""

echo "=== Probar HTTPS ==="
curl -I https://$DOMAIN 2>&1 | head -5
echo ""
