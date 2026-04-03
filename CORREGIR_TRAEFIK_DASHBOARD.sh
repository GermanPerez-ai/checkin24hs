#!/bin/bash
echo "=== CORRIGIENDO CONFIGURACIÓN DE TRAEFIK ==="
echo ""

PORT=3000
echo "Puerto: $PORT"
echo ""

echo "Removiendo configuración antigua (VIP)..."
docker service update \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

sleep 3

echo ""
echo "Agregando configuración con nombre del servicio..."
docker service update \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://checkin24hs_dashboard:${PORT}" \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "Esperando 20 segundos..."
sleep 20

echo ""
echo "Verificando configuración:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep "loadbalancer"

echo ""
echo "Probando acceso HTTPS:"
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
