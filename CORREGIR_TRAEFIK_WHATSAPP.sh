#!/bin/bash

echo "=========================================="
echo "🔧 CORRIGIENDO CONFIGURACIÓN TRAEFIK"
echo "=========================================="
echo ""

# Ver todos los servicios de WhatsApp
echo "1️⃣ Servicios de WhatsApp encontrados:"
echo "=========================================="
docker service ls | grep whatsapp
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# Primero, remover las etiquetas incorrectas y agregar las correctas
echo "2️⃣ Corrigiendo etiquetas de Traefik..."
echo "=========================================="
echo ""

# Remover etiquetas CORS incorrectas y agregar las correctas
docker service update \
  --label-rm 'traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowmethods' \
  --label-rm 'traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworigin' \
  --label-rm 'traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowheaders' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowMethods=GET,POST,OPTIONS' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowOrigin=*' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowHeaders=Content-Type,Authorization,Accept' \
  --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=3001' \
  "$SERVICE_NAME" 2>&1 | head -10

echo ""
echo "Esperando a que se actualice..."
sleep 5

# Verificar configuración
echo ""
echo "3️⃣ Verificando etiquetas actuales:"
echo "=========================================="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=========================================="
echo "📋 VERIFICAR LOGS DE TRAEFIK:"
echo "=========================================="
echo ""
echo "Espera 10 segundos y luego ejecuta:"
echo "  TRAEFIK=\$(docker ps --filter \"name=traefik\" --format \"{{.Names}}\" | head -1)"
echo "  docker logs \"\$TRAEFIK\" --tail 20 | grep -i \"api1\|whatsapp\|error\""
echo ""
echo "Si aún hay errores de múltiples servicios, necesitamos:"
echo "  1. Ver todos los servicios: docker service ls | grep whatsapp"
echo "  2. Especificar el servicio explícitamente en las etiquetas"
echo ""



