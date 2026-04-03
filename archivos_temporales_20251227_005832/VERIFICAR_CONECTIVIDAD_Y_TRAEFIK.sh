#!/bin/bash
# Verificar conectividad y configuración de Traefik

echo "=== PROBANDO CONECTIVIDAD ==="
echo ""

EASYPANEL_ID=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')
echo "Red easypanel ID: $EASYPANEL_ID"
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Probar con wget desde un contenedor existente
    CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        echo "   Probando desde contenedor Traefik:"
        docker exec $CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -5 || echo "   ❌ No responde"
    fi
    
    # Probar directamente desde el contenedor del servicio
    SERVICE_CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$SERVICE_CONTAINER" ]; then
        echo "   Probando localhost desde el contenedor del servicio:"
        docker exec $SERVICE_CONTAINER wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -5 || echo "   ❌ No responde en localhost:$PORT"
    fi
    
    echo ""
done

echo "=== LOGS COMPLETOS DE TRAEFIK (últimas 50 líneas) ==="
docker service logs traefik --tail 50 2>&1 | tail -30
echo ""

echo "=== VERIFICANDO CONFIGURACIÓN DE TRAEFIK PARA WHATSAPP ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Routers de Traefik:"
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp || echo "   No se encontraron routers de WhatsApp"
    echo ""
    echo "Services de Traefik:"
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/services 2>/dev/null | grep -i whatsapp || echo "   No se encontraron services de WhatsApp"
fi






