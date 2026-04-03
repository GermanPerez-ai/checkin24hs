#!/bin/bash
# Añadir Traefik al webmail: red easypanel + labels (router + servicio), sin IP fija.
# Ejecutar en el servidor donde corre checkin24hs_webmail y Traefik.

set -e
SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== AÑADIR TRAEFIK AL WEBMAIL ==="
echo ""

# 1. Red easypanel (Traefik descubre servicios en esta red)
EASYPANEL_NET=$(docker network ls --format '{{.Name}}' | grep -E '^easypanel$' | head -1)
if [ -z "$EASYPANEL_NET" ]; then
  echo "❌ No se encontró red 'easypanel'. Listando redes:"
  docker network ls | grep -iE 'easypanel|traefik'
  exit 1
fi
echo "✅ Red: $EASYPANEL_NET"

echo "Añadiendo webmail a $EASYPANEL_NET (si no está ya)..."
if docker service update --network-add "$EASYPANEL_NET" "$SERVICE_NAME" 2>/dev/null; then
  echo "✅ Red añadida. Esperando 15 s..."
  sleep 15
else
  echo "✅ Webmail ya estaba en $EASYPANEL_NET (o se produjo otro cambio)."
fi
echo ""

# 2. Quitar IP fija (si existe) para que Traefik descubra las tareas
echo "Quitando label de IP fija (si existe)..."
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" "$SERVICE_NAME" 2>/dev/null || true
sleep 3
echo ""

# 3. Añadir labels Traefik (como dashboard/cotizador)
echo "Añadiendo labels Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=$EASYPANEL_NET" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail.tls=true" \
  --label-add "traefik.http.routers.webmail.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  "$SERVICE_NAME"

echo ""
echo "=== LISTO ==="
echo "Espera 20–30 s y prueba:"
echo "  curl -sI -k https://$DOMAIN/ | head -5"
echo "  o abre en el navegador: https://$DOMAIN/"
