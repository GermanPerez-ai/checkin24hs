#!/bin/bash
# Corregir IP del backend webmail en Traefik (10.0.1.42 -> IP actual del contenedor)

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
# IP en la red easypanel (la que comparte con Traefik)
CURRENT_IP=$(docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' 2>/dev/null | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
  echo "No se pudo obtener IP del contenedor."
  exit 1
fi

echo "IP actual del contenedor (easypanel): $CURRENT_IP"
echo "Actualizando label loadbalancer.server a $CURRENT_IP:80 ..."
echo ""

# Actualizar solo la IP del backend (las demas labels se mantienen)
docker service update \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80" \
  "$SERVICE_NAME"

echo ""
echo "Listo. Espera 15-30 segundos y prueba: https://$DOMAIN/"
echo ""
echo "NOTA: Si el contenedor se recrea, la IP puede cambiar de nuevo."
echo "Para evitar eso, en EasyPanel asegurate de que el dominio webmail este configurado"
echo "y que el servicio se redespliegue para que EasyPanel actualice la IP."
