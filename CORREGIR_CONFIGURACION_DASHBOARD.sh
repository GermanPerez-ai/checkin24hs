#!/bin/bash
# Corregir configuración del dashboard en Traefik

echo "=== CORRIGIENDO CONFIGURACIÓN DEL DASHBOARD ==="
echo ""

# 1. Verificar configuración actual
echo "📋 1. Configuración actual:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -E "traefik|router|service" | head -20
echo ""

# 2. Obtener VIP del servicio en la red easypanel
echo "🔍 2. Obteniendo VIP del servicio..."
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}' 2>/dev/null)
VIP=$(docker service inspect checkin24hs_dashboard --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)
echo "   VIP: $VIP"
echo ""

# 3. Verificar puerto del servicio
PORT=$(docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null)
if [ -z "$PORT" ]; then
    PORT=3000
    echo "   Usando puerto por defecto: $PORT"
else
    echo "   Puerto del servicio: $PORT"
fi
echo ""

# 4. Aplicar configuración correcta de Traefik
echo "🔧 3. Aplicando configuración de Traefik..."

# Remover labels antiguos que puedan causar conflictos
docker service update \
  --label-rm "traefik.http.routers.dashboard.rule" \
  --label-rm "traefik.http.routers.dashboard.entrypoints" \
  --label-rm "traefik.http.routers.dashboard.tls" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

sleep 3

# Agregar configuración correcta
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://checkin24hs_dashboard:${PORT}" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=${PORT}" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate, proxy-revalidate" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Pragma=no-cache" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Expires=0" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Surrogate-Control=no-store" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-nocache" \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "⏳ Esperando 20 segundos para que Traefik se reconfigure..."
sleep 20

# 5. Verificar configuración aplicada
echo ""
echo "✅ 4. Verificando configuración aplicada:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -15
echo ""

# 6. Probar acceso
echo "🌍 5. Probando acceso HTTPS:"
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=== COMPLETADO ==="
echo ""
echo "Si aún ves 404, verifica:"
echo "1. Que el DNS dashboard.checkin24hs.com apunte a 72.61.58.240"
echo "2. Que el servicio dashboard esté corriendo: docker service ps checkin24hs_dashboard"
echo "3. Que Traefik pueda acceder al servicio: docker exec <traefik_container> wget -qO- http://checkin24hs_dashboard:${PORT}/"
echo ""





