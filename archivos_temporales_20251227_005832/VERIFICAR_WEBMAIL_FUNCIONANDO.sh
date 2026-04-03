#!/bin/bash

# Script para verificar que el webmail está funcionando correctamente

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== Verificación Final del Webmail ==="

# 1. Verificar etiquetas de Traefik
echo ""
echo "1. Etiquetas de Traefik configuradas:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

# 2. Ver logs de Traefik
echo ""
echo "2. Logs de Traefik relacionados con webmail:"
docker service logs traefik --tail 200 2>&1 | grep -i webmail | tail -10 || echo "No se encontraron referencias aún (puede tardar unos segundos)"

# 3. Verificar estado del servicio
echo ""
echo "3. Estado del servicio webmail:"
docker service ps $SERVICE_NAME --no-trunc | head -3

# 4. Verificar contenedor corriendo
echo ""
echo "4. Contenedor corriendo:"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Verificando respuesta del servidor interno:"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:80 2>&1 | head -5 || echo "No se pudo conectar internamente"
else
    echo "No se encontró contenedor corriendo"
fi

# 5. Verificar resolución DNS
echo ""
echo "5. Verificando resolución DNS:"
nslookup $DOMAIN 2>&1 | head -5 || echo "DNS no configurado aún"

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si las etiquetas de Traefik están configuradas, el webmail debería estar accesible en:"
echo "  http://$DOMAIN"
echo ""
echo "Si aún no funciona:"
echo "  1. Espera 1-2 minutos para que Traefik detecte los cambios"
echo "  2. Verifica el DNS: nslookup $DOMAIN"
echo "  3. Verifica los logs: docker service logs traefik --tail 200 | grep -i webmail"






