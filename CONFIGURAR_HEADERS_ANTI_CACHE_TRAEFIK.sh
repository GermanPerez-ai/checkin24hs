#!/bin/bash
# Configurar headers anti-caché en Traefik para el dashboard

echo "=== CONFIGURANDO HEADERS ANTI-CACHÉ EN TRAEFIK ==="
echo ""

# Verificar labels actuales
echo "Labels actuales del dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""
echo "Agregando middleware de headers anti-caché..."

# Crear middleware de headers anti-caché
docker service update \
  --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate" \
  --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Pragma=no-cache" \
  --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Expires=0" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-headers" \
  checkin24hs_dashboard

echo "✅ Headers anti-caché configurados"
echo "⏳ Esperando 10 segundos para que Traefik recargue..."
sleep 10

echo ""
echo "=== VERIFICANDO HEADERS ==="
echo "Headers enviados ahora:"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache|pragma|expires"

echo ""
echo "=== PRUEBA ==="
echo "Ahora prueba desde otra computadora:"
echo "1. Abre el navegador"
echo "2. Ve a: https://dashboard.checkin24hs.com/?v=$(date +%s)"
echo "3. O limpia el caché del navegador (Ctrl+Shift+R o Cmd+Shift+R)"
echo ""


