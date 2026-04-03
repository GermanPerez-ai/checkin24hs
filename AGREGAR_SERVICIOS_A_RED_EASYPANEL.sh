#!/bin/bash
# Agregar servicios de WhatsApp a la red easypanel donde está Traefik

echo "=== AGREGANDO SERVICIOS A RED EASYPANEL ==="
echo ""

# Verificar que la red easypanel existe
if ! docker network ls | grep -q easypanel; then
    echo "❌ Error: La red 'easypanel' no existe"
    exit 1
fi

echo "✅ Red 'easypanel' encontrada"
echo ""

# Agregar cada servicio a la red easypanel
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "Agregando $SERVICE_NAME a la red easypanel..."
    
    docker service update \
        --network-add easypanel \
        $SERVICE_NAME 2>&1 | head -5
    
    if [ $? -eq 0 ]; then
        echo "   ✅ $SERVICE_NAME agregado a easypanel"
    else
        echo "   ⚠️ Error agregando $SERVICE_NAME a easypanel"
    fi
    
    echo ""
done

echo "⏳ Espera 10 segundos para que los servicios se reconfiguren..."
sleep 10

echo ""
echo "=== VERIFICANDO REDES ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
    echo ""
done

echo "=== PROBANDO CONEXIÓN ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - ¡Funciona!"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada (pero Traefik se conecta)"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Traefik aún no puede conectar"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Proceso completado"
echo ""






