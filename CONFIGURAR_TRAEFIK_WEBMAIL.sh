#!/bin/bash

# Script para configurar Traefik para webmail

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== Configurando Traefik para webmail ==="

# 1. Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "ERROR: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

# 2. Obtener red de Traefik
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "ERROR: No se encontró la red easypanel"
    exit 1
fi

echo "Red de EasyPanel: $EASYPANEL_NET"

# 3. Agregar webmail a la red de Traefik
echo ""
echo "Agregando webmail a la red de Traefik..."
docker service update --network-add $EASYPANEL_NET $SERVICE_NAME

# 4. Agregar etiquetas de Traefik
echo ""
echo "Agregando etiquetas de Traefik..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  $SERVICE_NAME

echo ""
echo "Esperando 10 segundos para que se apliquen los cambios..."
sleep 10

# 5. Verificar configuración
echo ""
echo "Verificando configuración aplicada:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Verifica los logs de Traefik:"
echo "  docker service logs traefik --tail 50 | grep -i webmail"
echo ""
echo "Intenta acceder a: http://$DOMAIN"


















