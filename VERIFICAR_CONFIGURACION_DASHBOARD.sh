#!/bin/bash
echo "=== VERIFICACIÓN DE CONFIGURACIÓN DEL DASHBOARD ==="
echo ""
echo "📦 Estado del servicio:"
docker service ps checkin24hs_dashboard --no-trunc | head -5
echo ""
echo "🔧 Labels de Traefik:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""
echo "🌍 Probando acceso HTTPS:"
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
