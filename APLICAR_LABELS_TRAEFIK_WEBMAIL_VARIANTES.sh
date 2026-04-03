#!/bin/bash
# Aplicar labels de Traefik para webmail (varias variantes por si EasyPanel usa otro nombre)

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
CURRENT_IP=$(docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' 2>/dev/null | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
  echo "No se pudo obtener IP del contenedor."
  exit 1
fi

echo "Servicio: $SERVICE_NAME"
echo "Dominio:  $DOMAIN"
echo "IP:      $CURRENT_IP"
echo ""

# Variante 1: router "webmail" + entrypoints websecure y web (HTTPS y HTTP)
echo "Aplicando labels (router webmail, entrypoints websecure + web)..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-web.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail-web.service=webmail" \
  --label-add "traefik.http.routers.webmail-web.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80" \
  "$SERVICE_NAME"

echo ""
echo "Listo. Espera 20 segundos."
echo "Prueba: https://$DOMAIN/  y  http://$DOMAIN/"
echo ""
echo "Si sigue 404, ejecuta el diagnostico y pega la salida:"
echo "  bash DIAGNOSTICAR_404_TRAEFIK_COMPLETO.sh"
