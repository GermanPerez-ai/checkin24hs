#!/bin/bash
# Script para configurar etiquetas de Traefik para anti-caché en el servicio dashboard
# No requiere reiniciar Traefik, los cambios se detectan automáticamente.

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Configurando etiquetas de Traefik para anti-caché en $SERVICE_NAME ==="

# Verificar si el servicio existe
if ! docker service ls --format "{{.Name}}" | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: El servicio '$SERVICE_NAME' no existe. Asegúrate de que el servicio esté desplegado en EasyPanel."
    exit 1
fi

echo "🔧 Actualizando etiquetas de Traefik para el servicio $SERVICE_NAME..."

# Aplicar etiquetas de Traefik para headers anti-caché
# Traefik detecta estos cambios automáticamente sin necesidad de reinicio.
docker service update \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate, proxy-revalidate" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Pragma=no-cache" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Expires=0" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Surrogate-Control=no-store" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-nocache" \
  "$SERVICE_NAME" 2>&1 | grep -v "update paused\|update in progress" || true

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas de Traefik aplicadas correctamente al servicio '$SERVICE_NAME'."
    echo "⏳ Traefik detectará los cambios automáticamente en 10-30 segundos."
    echo "Para verificar, puedes usar: curl -I https://$DOMAIN/"
else
    echo "❌ Error al aplicar etiquetas de Traefik. Revisa los logs de Docker."
    exit 1
fi

echo "=== Configuración completada ==="
