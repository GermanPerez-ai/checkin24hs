#!/bin/bash
# Verificar si los servicios responden directamente a sus VIPs

echo "=== VERIFICANDO RESPUESTA DIRECTA A VIPs ==="
echo ""

# Obtener ID de la red easypanel
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}')

# Crear un contenedor temporal en la misma red para probar
echo "Creando contenedor temporal para probar conexión..."
docker run --rm --network easypanel --name test-connection alpine:latest sh -c "
    for i in 1 2 3 4; do
        SERVICE_NAME=\"checkin24hs_whatsapp\"
        if [ \$i -gt 1 ]; then
            SERVICE_NAME=\"\${SERVICE_NAME}\${i}\"
        fi
        
        PORT=\$((3000 + i))
        
        echo \"=== Probando \$SERVICE_NAME ===\"
        
        # Obtener VIP
        VIP=\$(docker service inspect \$SERVICE_NAME --format \"{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \\\"$EASYPANEL_NET_ID\\\"}}{{.Addr}}{{end}}{{end}}\" 2>/dev/null | cut -d/ -f1)
        
        if [ -n \"\$VIP\" ]; then
            echo \"VIP: \$VIP\"
            echo \"Probando http://\${VIP}:\${PORT}/api/qr?card=\${i}...\"
            
            wget -qO- --timeout=5 http://\${VIP}:\${PORT}/api/qr?card=\${i} 2>&1 | head -5 || echo \"Error de conexión\"
        fi
        
        echo \"\"
    done
" 2>&1 | grep -v "Unable to find image" || echo "Error ejecutando contenedor temporal"

echo ""
echo "=== PROBANDO DESDE TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)

if [ -n "$TRAEFIK_CONTAINER" ]; then
    for i in 1 2 3 4; do
        SERVICE_NAME="checkin24hs_whatsapp"
        if [ $i -gt 1 ]; then
            SERVICE_NAME="${SERVICE_NAME}${i}"
        fi
        
        PORT=$((3000 + i))
        
        # Obtener VIP
        VIP=$(docker service inspect $SERVICE_NAME --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)
        
        if [ -n "$VIP" ]; then
            echo "Probando http://${VIP}:${PORT}/api/qr?card=${i} desde Traefik..."
            RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${VIP}:${PORT}/api/qr?card=${i} 2>&1)
            
            if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
                echo "✅ Servicio responde correctamente"
                echo "Respuesta (primeros 100 caracteres):"
                echo "$RESPONSE" | head -c 100
                echo ""
            else
                echo "❌ Servicio no responde o error"
                echo "Error: $RESPONSE"
            fi
        fi
        
        echo ""
    done
fi

echo "✅ Verificación completada"
echo ""






