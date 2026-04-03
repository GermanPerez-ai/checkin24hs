#!/bin/bash
# Agregar router de Traefik para webmail (soluciona 404)

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# IP actual del contenedor
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
CURRENT_IP=$(docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' 2>/dev/null | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
  echo "No se pudo obtener IP del contenedor."
  exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo "IP actual:  $CURRENT_IP"
echo ""
echo "Agregando router Traefik y actualizando IP del backend..."
echo ""

# Agregar router y actualizar servicio (entrypoint websecure = HTTPS)
docker service update \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80" \
  "$SERVICE_NAME"

echo ""
echo "Listo. Espera 15-30 segundos y prueba: https://$DOMAIN/"
echo "Si aun 404, prueba tambien con entrypoint web (HTTP):"
echo "  docker service update --label-add 'traefik.http.routers.webmail.entrypoints=web' $SERVICE_NAME"
