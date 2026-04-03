#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO 504 GATEWAY TIMEOUT"
echo "=========================================="
echo ""

# 1. Asegurar que webmail esté en la red de Traefik
echo "=== 1. Asegurando que webmail esté en la red de Traefik ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ ERROR: No se encontró la red easypanel"
    exit 1
fi
echo "Red EasyPanel: $EASYPANEL_NET"

# Verificar si ya está en la red
docker network inspect $EASYPANEL_NET --format='{{range .Containers}}{{.Name}} {{end}}' 2>&1 | grep -q webmail
if [ $? -ne 0 ]; then
    echo "Agregando webmail a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
    echo "✅ Webmail agregado a la red"
    sleep 10
else
    echo "✅ Webmail ya está en la red EasyPanel"
fi
echo ""

# 2. Verificar y corregir puerto en Traefik
echo "=== 2. Verificando y corrigiendo puerto en Traefik ==="
CURRENT_PORT=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep "loadbalancer.server.port" | cut -d'=' -f2)
echo "Puerto actual configurado: ${CURRENT_PORT:-no configurado}"

# El puerto debe ser 80 (puerto interno del contenedor)
if [ "$CURRENT_PORT" != "80" ]; then
    echo "Corrigiendo puerto a 80..."
    docker service update \
      --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
      checkin24hs_webmail
    echo "✅ Puerto configurado a 80"
else
    echo "✅ Puerto ya está configurado correctamente (80)"
fi
echo ""

# 3. Eliminar cualquier configuración de IP directa
echo "=== 3. Eliminando configuraciones incorrectas ==="
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" checkin24hs_webmail 2>/dev/null
echo "✅ Configuraciones incorrectas eliminadas"
echo ""

# 4. Asegurar que las etiquetas estén correctas
echo "=== 4. Verificando etiquetas de Traefik ==="
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

echo "✅ Etiquetas actualizadas"
echo ""

# 5. Esperar a que se apliquen los cambios
echo "⏳ Esperando 20 segundos para que se apliquen los cambios..."
sleep 20
echo ""

# 6. Verificar que el webmail responda
echo "=== 5. Verificando que el webmail responda ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Probando respuesta del webmail..."
    RESPONSE=$(docker exec $WEBMAIL_CONTAINER wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -1)
    if [ -n "$RESPONSE" ]; then
        echo "✅ Webmail responde correctamente"
    else
        echo "⚠️ Webmail no responde, puede estar iniciando..."
    fi
else
    echo "⚠️ No se encontró contenedor del webmail"
fi
echo ""

# 7. Verificar configuración final
echo "=== 6. Configuración final ==="
echo "Etiquetas de Traefik:"
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
echo ""

echo "Redes del servicio:"
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Cambios realizados:"
echo "  ✅ Webmail agregado a la red de Traefik"
echo "  ✅ Puerto configurado correctamente (80)"
echo "  ✅ Eliminadas configuraciones con IP directa"
echo "  ✅ Etiquetas de Traefik actualizadas"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""
echo "Si aún no funciona, ejecuta el diagnóstico:"
echo "  bash DIAGNOSTICAR_504_WEBMAIL.sh"
echo ""

