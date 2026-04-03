#!/bin/bash
# Corregir configuración de Traefik para servicios de WhatsApp

echo "=== CORRIGIENDO CONFIGURACIÓN DE TRAEFIK ==="
echo ""

# Verificar red de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
echo "Contenedor Traefik: $TRAEFIK_CONTAINER"

if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Redes de Traefik:"
    docker inspect $TRAEFIK_CONTAINER --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
    echo ""
fi

# Verificar red de los servicios de WhatsApp
echo "=== REDES DE SERVICIOS WHATSAPP ==="
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "$SERVICE_NAME:"
    docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
done

echo ""
echo "=== OPCIONES DE CONFIGURACIÓN ==="
echo ""

# Opción 1: Usar nombre del servicio (si están en la misma red)
echo "Opción 1: Usar nombre del servicio (recomendado si están en la misma red)"
echo "  traefik.http.services.XXX.loadbalancer.server=http://checkin24hs_whatsapp:3001"
echo ""

# Opción 2: Usar gateway de la red
echo "Opción 2: Usar gateway de la red easypanel"
GATEWAY_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
if [ -n "$GATEWAY_IP" ]; then
    echo "  Gateway IP: $GATEWAY_IP"
    echo "  traefik.http.services.XXX.loadbalancer.server=http://${GATEWAY_IP}:3001"
else
    echo "  ⚠️ No se encontró gateway de la red easypanel"
fi
echo ""

# Opción 3: Usar IP del host
echo "Opción 3: Usar IP del host"
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$HOST_IP" ]; then
    echo "  Host IP: $HOST_IP"
    echo "  traefik.http.services.XXX.loadbalancer.server=http://${HOST_IP}:3001"
else
    echo "  ⚠️ No se pudo obtener IP del host"
fi
echo ""

# Aplicar configuración usando nombre del servicio (más confiable en Swarm)
echo "=== APLICANDO CONFIGURACIÓN ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "Configurando $SERVICE_NAME..."
    
    # Usar nombre del servicio (funciona si están en la misma red)
    docker service update \
        --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${SERVICE_NAME}:${PORT}" \
        $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    echo "   ✅ Configurado para usar http://${SERVICE_NAME}:${PORT}"
    echo ""
done

echo "✅ Configuración aplicada"
echo ""
echo "⏳ Espera unos segundos y verifica:"
echo "   curl -I https://api1.checkin24hs.com/api/qr?card=1"
echo ""






