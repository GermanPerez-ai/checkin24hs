#!/bin/bash
# Solucionar conexión de Traefik a servicios de WhatsApp

echo "=== SOLUCIONANDO CONEXIÓN DE TRAEFIK ==="
echo ""

# Verificar redes de los servicios
echo "=== REDES DE SERVICIOS ==="
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    echo "Redes:"
    docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
    
    # Obtener VIP del servicio
    echo "VIPs:"
    docker service inspect $SERVICE_NAME --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{"\n"}}{{end}}'
    echo ""
done

# Verificar red de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
echo "=== RED DE TRAEFIK ==="
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Redes de Traefik:"
    docker inspect $TRAEFIK_CONTAINER --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
fi

echo ""
echo "=== SOLUCIÓN: USAR NOMBRE DEL SERVICIO ==="
echo ""
echo "En Docker Swarm, Traefik puede conectarse a los servicios usando su nombre"
echo "si están en la misma red. Vamos a configurarlo:"
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "Configurando $SERVICE_NAME para usar nombre del servicio..."
    
    # Remover label anterior si existe y agregar nuevo
    docker service update \
        --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
        --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${SERVICE_NAME}:${PORT}" \
        $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    echo "   ✅ Configurado para http://${SERVICE_NAME}:${PORT}"
    echo ""
done

echo "⏳ Espera 10 segundos para que Traefik recargue..."
sleep 10

echo ""
echo "=== PROBANDO CONEXIÓN ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - ¡Funciona!"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Traefik no puede conectar (verificar redes)"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






