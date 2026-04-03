#!/bin/bash
echo "=== VERIFICACIÓN DE WHATSAPP1 DESPUÉS DEL DEPLOY ==="
echo ""

echo "1. Estado del servicio checkin24hs_whatsapp1:"
docker service ps checkin24hs_whatsapp1 --no-trunc | head -5
echo ""

echo "2. Logs recientes de checkin24hs_whatsapp1:"
docker service logs checkin24hs_whatsapp1 --tail 30
echo ""

echo "3. Verificando si el contenedor está escuchando en el puerto 3001:"
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp1" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "  Contenedor ID: $CONTAINER_ID"
    docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep ":3001 " || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep ":3001 " || echo "  ⚠️  No escucha en puerto 3001"
else
    echo "  ❌ Contenedor de checkin24hs_whatsapp1 no encontrado."
fi
echo ""

echo "4. Verificando errores de librerías en los logs:"
docker service logs checkin24hs_whatsapp1 --tail 50 | grep -iE "libnss3|error|failed|troubleshooting"
echo ""

echo "5. Verificando conectividad desde el contenedor de Traefik a whatsapp1:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "  Contenedor Traefik ID: $TRAEFIK_CONTAINER"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.checkin24hs_whatsapp1:3001 2>&1 | head -5 || echo "  ❌ Traefik no puede conectar a whatsapp1:3001"
else
    echo "  ❌ Contenedor de Traefik no encontrado."
fi
echo ""

echo "6. Verificando la respuesta del dominio whatsapp1.checkin24hs.com:"
curl -I --max-time 10 https://whatsapp1.checkin24hs.com 2>&1 | head -5 || echo "  ❌ El dominio no responde o hay un error de red/SSL."
echo ""

echo "=== VERIFICACIÓN COMPLETADA ==="
