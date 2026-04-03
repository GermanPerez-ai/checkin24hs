#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 FORZANDO TRAEFIK A USAR IP DEL WEBMAIL"
echo "=========================================="
echo ""

# 1. Obtener IP actual del webmail
echo "=== 1. Obteniendo IP actual del webmail ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -z "$WEBMAIL_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del webmail"
    exit 1
fi

# Obtener red EasyPanel
EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
WEBMAIL_IP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "'$EASYPANEL_NET_NAME'"}}{{$conf.IPAddress}}{{end}}{{end}}' 2>&1)

if [ -z "$WEBMAIL_IP" ]; then
    # Método alternativo: obtener todas las IPs y usar la primera
    WEBMAIL_IP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>&1 | head -1)
fi

if [ -z "$WEBMAIL_IP" ]; then
    echo "❌ No se pudo obtener IP del webmail"
    exit 1
fi

echo "IP del webmail: $WEBMAIL_IP"
echo ""

# 2. Verificar configuración actual
echo "=== 2. Configuración actual de Traefik ==="
CURRENT_SERVER=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>&1)
echo "Servidor configurado actualmente: ${CURRENT_SERVER:-no configurado}"
echo ""

# 3. Eliminar configuración antigua si existe
echo "=== 3. Limpiando configuración antigua ==="
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" checkin24hs_webmail 2>/dev/null
echo "✅ Configuración antigua eliminada"
echo ""

# 4. Agregar configuración con IP
echo "=== 4. Agregando configuración con IP ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$WEBMAIL_IP:80" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.routers.webmail-secure.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-secure.service=webmail" \
  --label-add "traefik.http.routers.webmail-secure.tls=true" \
  --label-add "traefik.http.routers.webmail-secure.tls.certresolver=letsencrypt" \
  checkin24hs_webmail

if [ $? -eq 0 ]; then
    echo "✅ Configuración actualizada"
else
    echo "❌ Error actualizando configuración"
    exit 1
fi
echo ""

# 5. Reiniciar Traefik para que tome los cambios
echo "=== 5. Reiniciando Traefik para aplicar cambios ==="
docker service update --force traefik
echo "✅ Traefik reiniciado"
echo "⏳ Esperando 30 segundos para que Traefik se reinicie..."
sleep 30
echo ""

# 6. Verificar configuración aplicada
echo "=== 6. Verificando configuración aplicada ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i "traefik.*server\|traefik.*port" | sort
echo ""

# 7. Probar conectividad
echo "=== 7. Probando conectividad ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Probando conexión desde Traefik a $WEBMAIL_IP:80..."
    RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://$WEBMAIL_IP:80 2>&1 | head -3)
    if [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q "can't connect\|unreachable\|timeout"; then
        echo "✅ Traefik puede conectarse al webmail"
    else
        echo "⚠️ Traefik aún no puede conectarse (puede estar reiniciando)"
    fi
fi
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Configuración aplicada:"
echo "  - IP del webmail: $WEBMAIL_IP"
echo "  - Traefik configurado para usar: $WEBMAIL_IP:80"
echo "  - Traefik reiniciado"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""
echo "Si aún no funciona, verifica los logs de Traefik:"
echo "  docker service logs traefik --tail 50 | grep -i webmail"
echo ""

