#!/bin/bash

# Script para forzar que Traefik detecte el webmail

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== Forzando detección de Traefik ==="

# 1. Verificar etiquetas actuales
echo ""
echo "1. Etiquetas actuales:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

# 2. Actualizar servicio para forzar detección
echo ""
echo "2. Actualizando servicio para forzar detección..."

# Primero, quitar todas las etiquetas de Traefik existentes
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.webmail.rule" \
  --label-rm "traefik.http.routers.webmail.entrypoints" \
  --label-rm "traefik.http.services.webmail.loadbalancer.server.port" \
  $SERVICE_NAME 2>/dev/null || echo "Algunas etiquetas no existían"

sleep 5

# Agregar etiquetas de nuevo con sintaxis correcta para Traefik v2
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  $SERVICE_NAME

echo "Esperando 10 segundos..."
sleep 10

# 3. Reiniciar Traefik para forzar re-detección
echo ""
echo "3. Reiniciando Traefik para forzar re-detección..."
docker service update --force traefik

echo "Esperando 30 segundos para que Traefik se reinicie..."
sleep 30

# 4. Verificar logs
echo ""
echo "4. Verificando logs de Traefik:"
docker service logs traefik --tail 50 2>&1 | grep -iE "webmail|docker|service" | tail -10

# 5. Verificar etiquetas finales
echo ""
echo "5. Etiquetas finales configuradas:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Espera 1-2 minutos y verifica:"
echo "  docker service logs traefik --tail 100 | grep -i webmail"
echo ""
echo "Intenta acceder a: http://$DOMAIN"






