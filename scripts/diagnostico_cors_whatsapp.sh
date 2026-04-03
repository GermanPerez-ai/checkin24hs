#!/bin/bash
# Diagnóstico CORS para WhatsApp: comprueba si OPTIONS a whatsapp.checkin24hs.com
# devuelve las cabeceras que el navegador necesita. Ejecutar en el SERVIDOR.
# Si desde el servidor no hay Access-Control-Allow-Origin, el preflight no llega
# al backend o el proxy (Traefik/EasyPanel) no está aplicando CORS.

set -e
URL="${1:-https://whatsapp.checkin24hs.com/api/send}"
ORIGIN="${2:-https://dashboard.checkin24hs.com}"
SERVICE="${3:-checkin24hs_whatsapp}"

echo "=== Diagnóstico CORS WhatsApp ==="
echo "URL: $URL"
echo "Origin: $ORIGIN"
echo ""

echo "--- 1. Respuesta a OPTIONS (preflight) ---"
RESP=$(curl -s -D - -o /dev/null -X OPTIONS "$URL" \
  -H "Origin: $ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -w "\n%{http_code}" 2>/dev/null || true)
HTTP_CODE=$(echo "$RESP" | tail -n1)
HEADERS=$(echo "$RESP" | sed '$d')

echo "$HEADERS"
echo "HTTP status: $HTTP_CODE"
if echo "$HEADERS" | grep -qi "Access-Control-Allow-Origin"; then
  echo "✅ Access-Control-Allow-Origin presente (CORS debería funcionar desde el navegador)."
else
  echo "❌ Access-Control-Allow-Origin NO presente."
  echo "   El preflight no llega al backend o el proxy no añade CORS."
  echo "   Acciones: ejecutar bash scripts/aplicar_cors_whatsapp_servidor.sh"
  echo "   Si ya lo hiciste: en EasyPanel, comprobá que whatsapp.checkin24hs.com"
  echo "   use el servicio de este stack (Traefik con estos labels), no otro proxy."
fi
echo ""

echo "--- 2. Labels del servicio (CORS) ---"
docker service inspect "$SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null | tr ',' '\n' | grep -E "cors|accesscontrol|Access-Control" || echo "(ningún label CORS o servicio no encontrado)"
echo ""

echo "=== Fin diagnóstico ==="
