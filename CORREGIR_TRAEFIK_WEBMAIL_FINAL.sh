#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRIGIENDO CONFIGURACIÓN DE TRAEFIK PARA WEBMAIL"
echo "=========================================="
echo ""

# El problema es que Traefik está usando una IP directa en lugar del nombre del servicio
# Necesitamos corregir las etiquetas para usar el nombre del servicio Docker Swarm

echo "=== 1. Eliminando etiquetas incorrectas ==="
# Primero eliminamos la etiqueta incorrecta que usa IP directa
docker service update \
  --label-rm "traefik.http.services.webmail.loadbalancer.server" \
  checkin24hs_webmail 2>/dev/null || echo "Etiqueta no encontrada o ya eliminada"

echo ""
echo "=== 2. Agregando etiquetas correctas ==="
# Agregamos las etiquetas correctas usando el nombre del servicio
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.routers.webmail-secure.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-secure.service=webmail" \
  --label-add "traefik.http.routers.webmail-secure.tls=true" \
  --label-add "traefik.http.routers.webmail-secure.tls.certresolver=letsencrypt" \
  checkin24hs_webmail

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas corregidas"
else
    echo "❌ Error corrigiendo etiquetas"
    exit 1
fi

echo ""
echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "=== 3. Verificando configuración ==="
echo ""
echo "Etiquetas de Traefik actuales:"
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
echo ""

echo "=== 4. Verificando redes ==="
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $WEBMAIL_NETS"
echo "Redes de Traefik: $TRAEFIK_NETS"
echo ""

# Verificar si hay alguna red en común
WEBMAIL_NET_LIST=$(echo $WEBMAIL_NETS | tr ' ' '\n')
TRAEFIK_NET_LIST=$(echo $TRAEFIK_NETS | tr ' ' '\n')
COMMON_NET=$(comm -12 <(echo "$WEBMAIL_NET_LIST" | sort) <(echo "$TRAEFIK_NET_LIST" | sort) | head -1)

if [ -n "$COMMON_NET" ]; then
    echo "✅ Hay al menos una red en común: $COMMON_NET"
else
    echo "❌ NO hay redes en común"
    echo ""
    echo "Agregando webmail a la red de Traefik..."
    EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
    if [ -n "$EASYPANEL_NET" ]; then
        docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
        echo "✅ Webmail agregado a la red EasyPanel"
    fi
fi

echo ""
echo "=== 5. Verificando logs de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Buscando referencias a webmail en los logs recientes..."
    docker logs $TRAEFIK_CONTAINER --tail 30 2>&1 | grep -i "webmail" | tail -5 || echo "No se encontraron referencias aún (puede tardar unos segundos más)"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN CORREGIDA"
echo "=========================================="
echo ""
echo "Cambios realizados:"
echo "  ✅ Eliminada etiqueta con IP directa"
echo "  ✅ Configurado para usar nombre de servicio Docker Swarm"
echo "  ✅ Puerto configurado correctamente (80)"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""
echo "Si aún no funciona, verifica los logs:"
echo "  docker service logs traefik --tail 50 | grep -i webmail"
echo ""





