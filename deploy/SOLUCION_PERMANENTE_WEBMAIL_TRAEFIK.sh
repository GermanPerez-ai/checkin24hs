#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIÓN PERMANENTE: WEBMAIL-TRAEFIK"
echo "=========================================="
echo ""

# 1. Obtener VIP (Virtual IP) del servicio webmail
echo "=== 1. Obteniendo VIP del servicio webmail ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')

# Obtener VIP del servicio en la red EasyPanel
WEBMAIL_VIP=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{if eq (index (split .NetworkID "/") 0) "'$EASYPANEL_NET'"}}{{.Addr}}{{end}}{{end}}' 2>&1)

if [ -z "$WEBMAIL_VIP" ]; then
    # Método alternativo: obtener todas las VIPs y usar la primera
    WEBMAIL_VIP=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' 2>&1 | awk '{print $1}')
fi

# Si aún no hay VIP, obtener IP del contenedor como fallback
if [ -z "$WEBMAIL_VIP" ]; then
    echo "⚠️ No se encontró VIP, usando IP del contenedor..."
    WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
    if [ -n "$WEBMAIL_CONTAINER" ]; then
        EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
        WEBMAIL_VIP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "'$EASYPANEL_NET_NAME'"}}{{$conf.IPAddress}}{{end}}{{end}}' 2>&1)
    fi
fi

# Quitar /24 o /16 del VIP si existe
WEBMAIL_VIP=$(echo $WEBMAIL_VIP | cut -d'/' -f1)

if [ -z "$WEBMAIL_VIP" ]; then
    echo "❌ No se pudo obtener VIP ni IP del webmail"
    exit 1
fi

echo "VIP/IP del webmail: $WEBMAIL_VIP"
echo ""

# 2. Verificar configuración actual
echo "=== 2. Verificando configuración actual ==="
CURRENT_SERVER=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>&1)
echo "Servidor configurado: ${CURRENT_SERVER:-no configurado}"
echo ""

# 3. Actualizar configuración
echo "=== 3. Actualizando configuración de Traefik ==="
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

# 4. Reiniciar Traefik
echo "=== 4. Reiniciando Traefik ==="
docker service update --force traefik
echo "✅ Traefik reiniciado"
echo "⏳ Esperando 20 segundos..."
sleep 20
echo ""

# 5. Verificar conectividad
echo "=== 5. Verificando conectividad ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Probando conexión a $WEBMAIL_VIP:80..."
    RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://$WEBMAIL_VIP:80 2>&1 | head -3)
    if [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q "can't connect\|unreachable\|timeout"; then
        echo "✅ Traefik puede conectarse al webmail"
    else
        echo "⚠️ Traefik aún no puede conectarse (puede estar reiniciando)"
    fi
fi
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN ACTUALIZADA"
echo "=========================================="
echo ""
echo "VIP configurado: $WEBMAIL_VIP:80"
echo ""
echo "NOTA: Si el webmail se reinicia y cambia de IP, ejecuta este script nuevamente:"
echo "  bash SOLUCION_PERMANENTE_WEBMAIL_TRAEFIK.sh"
echo ""
echo "O crea un cron job para ejecutarlo automáticamente cada 5 minutos."
echo ""

