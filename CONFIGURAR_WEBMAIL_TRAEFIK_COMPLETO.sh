#!/bin/bash

# Script completo para configurar Traefik para webmail

set -e

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== Configurando Traefik para webmail ==="

# 1. Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "ERROR: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

echo "Servicio encontrado: $SERVICE_NAME"

# 2. Obtener red de EasyPanel/Traefik
echo ""
echo "Buscando red de EasyPanel..."
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')

if [ -z "$EASYPANEL_NET" ]; then
    echo "ADVERTENCIA: No se encontró red 'easypanel', buscando red de Traefik..."
    TRAEFIK_NET=$(docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | head -1)
    if [ ! -z "$TRAEFIK_NET" ]; then
        EASYPANEL_NET=$TRAEFIK_NET
        echo "Usando red de Traefik: $EASYPANEL_NET"
    else
        echo "ERROR: No se pudo encontrar la red"
        exit 1
    fi
else
    echo "Red encontrada: $EASYPANEL_NET"
fi

# 3. Verificar si ya está en la red
echo ""
echo "Verificando redes del servicio webmail..."
CURRENT_NETS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}')

if echo "$CURRENT_NETS" | grep -q "$EASYPANEL_NET"; then
    echo "✅ El servicio ya está en la red $EASYPANEL_NET"
else
    echo "Agregando servicio a la red $EASYPANEL_NET..."
    docker service update --network-add $EASYPANEL_NET $SERVICE_NAME
    echo "Esperando 10 segundos..."
    sleep 10
fi

# 4. Agregar etiquetas de Traefik
echo ""
echo "Agregando etiquetas de Traefik..."

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  $SERVICE_NAME

echo "Esperando 15 segundos para que se apliquen los cambios..."
sleep 15

# 5. Verificar configuración
echo ""
echo "=== Verificando configuración aplicada ==="
echo ""
echo "Etiquetas de Traefik:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

echo ""
echo "Redes del servicio:"
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

echo ""
echo "=== Verificando logs de Traefik ==="
echo "Buscando referencias a webmail en los logs de Traefik..."
docker service logs traefik --tail 50 2>&1 | grep -i webmail | tail -5 || echo "No se encontraron referencias aún (puede tardar unos segundos)"

echo ""
echo "=== Configuración completada ==="
echo ""
echo "El webmail debería estar accesible en: http://$DOMAIN"
echo ""
echo "Si aún no funciona, espera 1-2 minutos y verifica:"
echo "  docker service logs traefik --tail 100 | grep -i webmail"


















