#!/bin/bash
# Aplicar TODAS las labels de Traefik para webmail (router + servicio + IP actual)

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
CURRENT_IP=$(docker inspect $CONTAINER_ID --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
  echo "No se pudo obtener IP del contenedor."
  exit 1
fi

echo "Dominio: $DOMAIN"
echo "IP:     $CURRENT_IP"
echo ""
echo "Aplicando todas las labels en un solo update..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80" \
  "$SERVICE_NAME"

echo ""
echo "Listo. Espera 15 segundos y prueba:"
echo "  curl -sI -k https://webmail.checkin24hs.com/ | head -3"
echo ""
echo "Si EasyPanel vuelve a quitar las labels, tendras que ejecutar este script"
echo "despues de cada cambio en el panel, o configurar el dominio solo desde EasyPanel."
