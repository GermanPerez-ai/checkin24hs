#!/bin/bash
# Corregir 404 de Traefik para webmail: falta router o IP desactualizada

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== DIAGNOSTICO TRAEFIK WEBMAIL ==="
echo ""

# IP actual del contenedor (red easypanel)
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
CURRENT_IP=$(docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' 2>/dev/null | awk '{print $1}')

# IP configurada en Traefik
LABEL_IP=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null | cut -d: -f1)

echo "1. IP actual del contenedor (easypanel): $CURRENT_IP"
echo "2. IP en label de Traefik:              ${LABEL_IP:- (no encontrada)}"
echo ""

# Todas las labels del servicio
echo "3. Todas las labels del servicio:"
docker service inspect "$SERVICE_NAME" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

if [ -z "$LABEL_IP" ]; then
  echo "PROBLEMA: No hay label traefik.http.services.webmail.loadbalancer.server"
  echo "SOLUCION: En EasyPanel, en el servicio webmail, agrega el dominio: $DOMAIN"
  exit 1
fi

if [ -n "$CURRENT_IP" ] && [ "$CURRENT_IP" != "$LABEL_IP" ]; then
  echo "PROBLEMA: La IP del contenedor ($CURRENT_IP) no coincide con la de Traefik ($LABEL_IP)."
  echo "Traefik esta enviando trafico a una IP vieja."
  echo ""
  echo "SOLUCION: Actualizar el servicio con la IP correcta y asegurar que hay router."
  echo "Ejecuta (reemplaza ROUTER_LABELS si faltan):"
  echo "  docker service update \\"
  echo "    --label-add \"traefik.http.routers.webmail.rule=Host(\\\`$DOMAIN\\\`)\" \\"
  echo "    --label-add \"traefik.http.routers.webmail.service=webmail\" \\"
  echo "    --label-add \"traefik.http.routers.webmail.entrypoints=websecure\" \\"
  echo "    --label-add \"traefik.http.services.webmail.loadbalancer.server=$CURRENT_IP:80\" \\"
  echo "    $SERVICE_NAME"
  exit 1
fi

# Comprobar si existe router
ROUTER_RULE=$(docker service inspect "$SERVICE_NAME" --format '{{range $k,$v := .Spec.Labels}}{{if eq $k "traefik.http.routers.webmail.rule"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
if [ -z "$ROUTER_RULE" ]; then
  echo "PROBLEMA: No hay router de Traefik para webmail (falta traefik.http.routers.webmail.rule)."
  echo "Por eso Traefik devuelve 404: no sabe que las peticiones a $DOMAIN van a este servicio."
  echo ""
  echo "SOLUCION 1 (recomendada): En EasyPanel -> Servicio webmail -> Dominios: agrega $DOMAIN y guarda/implementa."
  echo ""
  echo "SOLUCION 2 (manual): Anade las labels del router:"
  echo "  docker service update \\"
  echo "    --label-add \"traefik.http.routers.webmail.rule=Host(\\\`$DOMAIN\\\`)\" \\"
  echo "    --label-add \"traefik.http.routers.webmail.service=webmail\" \\"
  echo "    --label-add \"traefik.http.routers.webmail.entrypoints=websecure\" \\"
  echo "    $SERVICE_NAME"
  exit 1
fi

echo "Router encontrado: $ROUTER_RULE"
echo "Si aun ves 404, reinicia Traefik o el servicio webmail: docker service update --force $SERVICE_NAME"
