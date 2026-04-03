#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO WEBMAIL BAD GATEWAY"
echo "=========================================="
echo ""

# 1. Obtener red de EasyPanel (donde está Traefik)
echo "=== 1. Obteniendo red de EasyPanel ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ ERROR: No se encontró la red easypanel"
    exit 1
fi
echo "✅ Red encontrada: $EASYPANEL_NET"
echo ""

# 2. Agregar webmail a la red de Traefik
echo "=== 2. Agregando webmail a la red de Traefik ==="
docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
if [ $? -eq 0 ]; then
    echo "✅ Webmail agregado a la red de Traefik"
else
    echo "⚠️ Advertencia: Puede que ya esté en la red"
fi
echo ""

# 3. Esperar a que se aplique el cambio
echo "⏳ Esperando 10 segundos para que se apliquen los cambios de red..."
sleep 10
echo ""

# 4. Agregar etiquetas de Traefik
echo "=== 3. Agregando etiquetas de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  checkin24hs_webmail

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas de Traefik agregadas"
else
    echo "❌ Error agregando etiquetas"
    exit 1
fi
echo ""

# 5. Esperar a que Traefik detecte los cambios
echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15
echo ""

# 6. Verificar configuración aplicada
echo "=== 4. Verificando configuración aplicada ==="
echo ""
echo "Etiquetas de Traefik:"
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik
echo ""

echo "Redes del servicio:"
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1
echo ""

# 7. Verificar logs de Traefik
echo "=== 5. Verificando logs de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Buscando referencias a webmail en los logs de Traefik..."
    docker logs $TRAEFIK_CONTAINER --tail 30 2>&1 | grep -i "webmail" | tail -5 || echo "No se encontraron referencias aún (puede tardar unos segundos más)"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 8. Verificar estado del servicio
echo "=== 6. Estado del servicio webmail ==="
docker service ps checkin24hs_webmail --no-trunc | head -3
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "El webmail debería estar accesible en:"
echo "  - http://webmail.checkin24hs.com"
echo ""
echo "Si aún no funciona, espera 1-2 minutos y verifica:"
echo "  bash DIAGNOSTICAR_WEBMAIL_BAD_GATEWAY.sh"
echo ""
echo "Para ver logs en tiempo real:"
echo "  docker service logs checkin24hs_webmail -f"
echo ""

