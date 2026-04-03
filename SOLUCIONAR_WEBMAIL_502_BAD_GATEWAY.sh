#!/bin/bash
#
# Soluciona Bad Gateway (502) en webmail.checkin24hs.com
# Solo modifica el servicio checkin24hs_webmail. NO afecta dashboard, whatsapp ni cotizador.
# Basado en la solución documentada para WhatsApp en docs/WHATSAPP_TRAEFIK_EASYPANEL_BAD_GATEWAY.md
#
# Ejecutar EN EL SERVIDOR (SSH), en la carpeta del repo: bash SOLUCIONAR_WEBMAIL_502_BAD_GATEWAY.sh

set -e
cd /root/checkin24hs 2>/dev/null || cd "$(dirname "$0")"

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"
WEBMAIL_PORT=80

echo "=========================================="
echo "🔧 SOLUCIONANDO 502 BAD GATEWAY - WEBMAIL"
echo "=========================================="
echo ""
echo "⚠️  Solo se modifica el servicio webmail. Dashboard, WhatsApp y Cotizador no se tocan."
echo ""

# 0. Verificar que el servicio existe
echo "=== 0. Verificando que webmail existe ==="
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ ERROR: Servicio $SERVICE_NAME no encontrado."
    echo "   El webmail puede estar creado con otro nombre en EasyPanel."
    exit 1
fi
echo "✅ Servicio encontrado"
echo ""

# 1. Verificar puerto publicado (debe quitarse para usar dnsrr)
echo "=== 1. Comprobando puertos publicados del webmail ==="
ENDPOINT_SPEC=$(docker service inspect $SERVICE_NAME --format '{{json .Spec.EndpointSpec}}' 2>/dev/null)
echo "EndpointSpec actual: $ENDPOINT_SPEC"

if echo "$ENDPOINT_SPEC" | grep -q '"Ports"'; then
    echo "⚠️  Hay puertos publicados. Quitando puerto destino $WEBMAIL_PORT para permitir dnsrr..."
    docker service update --publish-rm $WEBMAIL_PORT $SERVICE_NAME
    echo "⏳ Esperando 15 segundos para que converja..."
    sleep 15
    ENDPOINT_SPEC=$(docker service inspect $SERVICE_NAME --format '{{json .Spec.EndpointSpec}}')
    echo "EndpointSpec después: $ENDPOINT_SPEC"
fi

if echo "$ENDPOINT_SPEC" | grep -q '"Ports"'; then
    echo "❌ No se pudo quitar el puerto. En EasyPanel → webmail → Puertos: elimina cualquier regla y vuelve a ejecutar este script."
    exit 1
fi
echo "✅ Sin puertos publicados"
echo ""

# 2. Activar endpoint-mode dnsrr
echo "=== 2. Activando endpoint-mode dnsrr ==="
CURRENT_MODE=$(docker service inspect $SERVICE_NAME --format '{{.Spec.EndpointSpec.Mode}}' 2>/dev/null)
if [ "$CURRENT_MODE" != "dnsrr" ]; then
    docker service update --endpoint-mode dnsrr $SERVICE_NAME
    echo "⏳ Esperando 15 segundos para que converja..."
    sleep 15
else
    echo "   Ya está en modo dnsrr"
fi
echo "✅ Modo: $(docker service inspect $SERVICE_NAME --format '{{.Spec.EndpointSpec.Mode}}')"
echo ""

# 3. Red EasyPanel
echo "=== 3. Verificando red EasyPanel ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ No se encontró la red easypanel"
    exit 1
fi

WEBMAIL_NETS=$(docker service inspect $SERVICE_NAME --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null)
if ! echo "$WEBMAIL_NETS" | grep -q "easypanel"; then
    echo "Agregando webmail a la red $EASYPANEL_NET..."
    docker service update --network-add $EASYPANEL_NET $SERVICE_NAME
    sleep 10
fi
echo "✅ Webmail en red easypanel"
echo ""

# 4. Etiquetas de Traefik
echo "=== 4. Configurando etiquetas de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.tls=true" \
  --label-add "traefik.http.routers.webmail.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=$WEBMAIL_PORT" \
  $SERVICE_NAME 2>/dev/null | tail -3 || true
echo "✅ Etiquetas aplicadas"
echo ""

# 5. Reiniciar Traefik para que use las nuevas IPs
echo "=== 5. Reiniciando Traefik ==="
docker service update --force traefik 2>/dev/null | tail -2 || true
echo "✅ Reinicio solicitado"
echo "⏳ Esperando 30 segundos..."
sleep 30
echo ""

# 6. Probar conectividad
echo "=== 6. Probando conectividad desde la red easypanel ==="
RESP=$(docker run --rm --network easypanel curlimages/curl:latest curl -sI --connect-timeout 5 http://$SERVICE_NAME:$WEBMAIL_PORT/ 2>&1 | head -3)
if echo "$RESP" | grep -q "200\|301\|302"; then
    echo "✅ El backend webmail responde correctamente"
    echo "$RESP"
else
    echo "⚠️  Respuesta del backend:"
    echo "$RESP"
    echo ""
    echo "   Si aún ves Bad Gateway, espera 1-2 minutos y prueba de nuevo en el navegador."
fi
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Prueba: https://$DOMAIN"
echo ""
echo "Si sigue 502: espera 1-2 minutos (Traefik tarda en actualizar) y vuelve a intentar."
echo "Para ver logs: docker service logs $SERVICE_NAME --tail 50"
echo ""
