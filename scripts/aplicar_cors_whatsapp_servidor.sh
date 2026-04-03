#!/bin/bash
# Aplica labels CORS al servicio WhatsApp para que el dashboard pueda llamar a
# https://whatsapp.checkin24hs.com/api/send y el mensaje aparezca en Chats (Flor IA).
# Ejecutar en el SERVIDOR: bash scripts/aplicar_cors_whatsapp_servidor.sh
# Después: probar "Guardar y Enviar al Cliente" en el dashboard.

set -e
SERVICE="${1:-checkin24hs_whatsapp}"

echo "=== Aplicando CORS al servicio WhatsApp (${SERVICE}) ==="
echo "Así el dashboard puede llamar a la API y el mensaje se envía por Chats."
echo ""

# Middleware CORS (cabeceras que el navegador exige para cross-origin)
docker service update \
  --label-add "traefik.http.routers.whatsapp.middlewares=whatsapp-cors" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.middlewares=whatsapp-cors" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworiginlist=https://dashboard.checkin24hs.com" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Origin=https://dashboard.checkin24hs.com" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Methods=GET, POST, OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Headers=Content-Type, Authorization, Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Credentials=true" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolmaxage=86400" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.addvaryheader=true" \
  "$SERVICE"

echo ""
echo "=== Listo. Esperá unos segundos y probá 'Guardar y Enviar al Cliente' en el dashboard. ==="
echo "El mensaje debería enviarse por la API y aparecer en la sección Chats (Flor IA)."
