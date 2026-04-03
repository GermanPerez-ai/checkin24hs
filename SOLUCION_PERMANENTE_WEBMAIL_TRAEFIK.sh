#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIÓN PERMANENTE: WEBMAIL-TRAEFIK"
echo "=========================================="
echo ""

# 1. Obtener VIP/IP del webmail
echo "=== 1. Obteniendo VIP/IP del webmail ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
WEBMAIL_VIP=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' 2>&1 | awk '{print $1}' | cut -d'/' -f1)

if [ -z "$WEBMAIL_VIP" ]; then
    WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
    if [ -n "$WEBMAIL_CONTAINER" ]; then
        EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
        WEBMAIL_VIP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "'$EASYPANEL_NET_NAME'"}}{{$conf.IPAddress}}{{end}}{{end}}' 2>&1)
    fi
fi

if [ -z "$WEBMAIL_VIP" ]; then
    echo "❌ No se pudo obtener VIP ni IP del webmail"
    exit 1
fi

echo "VIP/IP del webmail: $WEBMAIL_VIP"
echo ""

# 2. Actualizar configuración
echo "=== 2. Actualizando configuración de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$WEBMAIL_VIP:80" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.routers.webmail-secure.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-secure.service=webmail" \
  --label-add "traefik.http.routers.webmail-secure.tls=true" \
  --label-add "traefik.http.routers.webmail-secure.tls.certresolver=letsencrypt" \
  checkin24hs_webmail

if [ $? -eq 0 ]; then
    echo "✅ Configuración actualizada con VIP: $WEBMAIL_VIP:80"
else
    echo "❌ Error actualizando configuración"
    exit 1
fi
echo ""

# 3. Reiniciar Traefik
echo "=== 3. Reiniciando Traefik ==="
docker service update --force traefik
echo "✅ Traefik reiniciado"
echo "⏳ Esperando 20 segundos..."
sleep 20
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN ACTUALIZADA"
echo "=========================================="
echo ""
echo "VIP configurado: $WEBMAIL_VIP:80"
echo ""
echo "Espera 1-2 minutos y prueba: https://webmail.checkin24hs.com"
echo ""
