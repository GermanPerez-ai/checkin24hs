#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO PROBLEMA DE RED TRAEFIK-WEBMAIL"
echo "=========================================="
echo ""

# 1. Obtener la red de EasyPanel
echo "=== 1. Obteniendo red EasyPanel ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ ERROR: No se encontró la red easypanel"
    exit 1
fi
EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
echo "Red EasyPanel: $EASYPANEL_NET ($EASYPANEL_NET_NAME)"
echo ""

# 2. Verificar redes actuales del webmail
echo "=== 2. Redes actuales del webmail ==="
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $WEBMAIL_NETS"
echo ""

# 3. Verificar redes actuales de Traefik
echo "=== 3. Redes actuales de Traefik ==="
TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes de Traefik: $TRAEFIK_NETS"
echo ""

# 4. Verificar si webmail está en la red EasyPanel
echo "=== 4. Verificando si webmail está en la red EasyPanel ==="
if echo "$WEBMAIL_NETS" | grep -q "$EASYPANEL_NET"; then
    echo "✅ Webmail ya está en la red EasyPanel"
else
    echo "❌ Webmail NO está en la red EasyPanel"
    echo "Agregando webmail a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
    echo "✅ Webmail agregado a la red EasyPanel"
    echo "⏳ Esperando 15 segundos para que se aplique el cambio..."
    sleep 15
fi
echo ""

# 5. Verificar si Traefik está en la red EasyPanel
echo "=== 5. Verificando si Traefik está en la red EasyPanel ==="
if echo "$TRAEFIK_NETS" | grep -q "$EASYPANEL_NET"; then
    echo "✅ Traefik ya está en la red EasyPanel"
else
    echo "❌ Traefik NO está en la red EasyPanel"
    echo "Agregando Traefik a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET traefik
    echo "✅ Traefik agregado a la red EasyPanel"
    echo "⏳ Esperando 15 segundos para que se aplique el cambio..."
    sleep 15
fi
echo ""

# 6. Verificar que ambos estén en la misma red
echo "=== 6. Verificando redes después de los cambios ==="
NEW_WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
NEW_TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $NEW_WEBMAIL_NETS"
echo "Redes de Traefik: $NEW_TRAEFIK_NETS"
echo ""

# Verificar si hay red en común
COMMON_NET_FOUND=false
for webmail_net in $NEW_WEBMAIL_NETS; do
    for traefik_net in $NEW_TRAEFIK_NETS; do
        if [ "$webmail_net" = "$traefik_net" ]; then
            echo "✅ Hay una red en común: $webmail_net"
            COMMON_NET_FOUND=true
        fi
    done
done

if [ "$COMMON_NET_FOUND" = false ]; then
    echo "❌ Aún NO hay redes en común"
    echo "Esto es un problema grave de configuración"
    exit 1
fi
echo ""

# 7. Esperar a que los contenedores se reinicien
echo "⏳ Esperando 20 segundos adicionales para que los contenedores se reinicien..."
sleep 20
echo ""

# 8. Probar conectividad
echo "=== 7. Probando conectividad ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Probando conexión desde Traefik al webmail..."
    RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://checkin24hs_webmail:80 2>&1 | head -5)
    if [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q "can't connect\|unreachable\|timeout"; then
        echo "✅ Traefik PUEDE conectarse al webmail ahora"
        echo "Respuesta (primeras 3 líneas):"
        echo "$RESPONSE" | head -3
    else
        echo "⚠️ Traefik aún no puede conectarse"
        echo "Esto puede tardar unos minutos más mientras los contenedores se reinician"
        echo "Respuesta: $RESPONSE"
    fi
else
    echo "⚠️ No se encontró contenedor de Traefik (puede estar reiniciando)"
fi
echo ""

# 9. Verificar configuración de Traefik
echo "=== 8. Verificando configuración de Traefik ==="
echo "Asegurando que las etiquetas estén correctas..."
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
  checkin24hs_webmail 2>&1 | grep -v "overall progress" | tail -3

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Cambios realizados:"
echo "  ✅ Webmail agregado a la red EasyPanel (si no estaba)"
echo "  ✅ Traefik agregado a la red EasyPanel (si no estaba)"
echo "  ✅ Etiquetas de Traefik actualizadas"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""
echo "Si aún no funciona, los contenedores pueden estar reiniciando."
echo "Espera unos minutos más y vuelve a intentar."
echo ""





