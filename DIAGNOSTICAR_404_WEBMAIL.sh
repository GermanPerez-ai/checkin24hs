#!/bin/bash
# Diagnosticar 404 en webmail: si es Traefik o el contenedor

echo "=== DIAGNOSTICO 404 WEBMAIL ==="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Contenedor activo
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
  echo "ERROR: No hay contenedor webmail corriendo."
  exit 1
fi
echo "1. Contenedor webmail: $CONTAINER_ID"

# 2. Respuesta directa del contenedor (sin Traefik)
echo ""
echo "2. Respuesta HTTP directa al contenedor (puerto 80 interno):"
docker exec "$CONTAINER_ID" curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost/ 2>/dev/null || echo "   No se pudo conectar"

# 3. Headers de respuesta desde el servidor (pasando por Traefik)
echo ""
echo "3. Respuesta desde el servidor (via Traefik) a https://$DOMAIN/ :"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -H "Host: $DOMAIN" https://$DOMAIN/ -k 2>/dev/null || echo "   Fallo al conectar"

echo ""
echo "4. Headers completos (primeras lineas) desde https://$DOMAIN/ :"
curl -sI -k "https://$DOMAIN/" 2>/dev/null | head -15

# 4. Logs recientes Traefik (buscar webmail o 404)
echo ""
echo "5. Logs Traefik recientes (webmail / 404):"
docker service logs traefik --tail 50 2>&1 | grep -iE "webmail|$DOMAIN|404" | tail -15 || echo "   (ninguno)"

# 5. Logs webmail recientes
echo ""
echo "6. Logs webmail recientes:"
docker service logs "$SERVICE_NAME" --tail 20 2>&1 | tail -15

echo ""
echo "=== INTERPRETACION ==="
echo "- Si el contenedor responde 200 pero Traefik da 404: problema de ruta/backend en Traefik."
echo "- Si el contenedor da 404: problema dentro de Roundcube o la URL que usas."
echo "- Si Traefik no encuentra el servicio: revisar labels del servicio webmail y que este en la red de Traefik."
