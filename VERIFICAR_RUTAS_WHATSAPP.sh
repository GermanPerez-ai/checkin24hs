#!/bin/bash
# Verificar rutas disponibles en los servicios de WhatsApp

echo "=== VERIFICANDO RUTAS DE SERVICIOS WHATSAPP ==="
echo ""

# Obtener IP o nombre del servicio en la red
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME (api${i}.checkin24hs.com) ==="
    
    # Obtener contenedor del servicio
    CONTAINER=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.Names}}" | head -n 1)
    
    if [ -n "$CONTAINER" ]; then
        echo "Contenedor: $CONTAINER"
        
        # Obtener IP del contenedor
        CONTAINER_IP=$(docker inspect $CONTAINER --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -n 1)
        
        if [ -n "$CONTAINER_IP" ]; then
            echo "IP: $CONTAINER_IP"
            PORT="300${i}"
            echo "Probando http://${CONTAINER_IP}:${PORT}/api/qr?card=${i}..."
            
            # Probar directamente al contenedor
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://${CONTAINER_IP}:${PORT}/api/qr?card=${i} 2>&1)
            echo "Respuesta: HTTP $RESPONSE"
            
            if [ "$RESPONSE" = "200" ]; then
                echo "✅ El servicio responde correctamente"
            elif [ "$RESPONSE" = "404" ]; then
                echo "⚠️ Ruta no encontrada - probando otras rutas..."
                
                # Probar rutas comunes
                for route in "/" "/api" "/api/status" "/health" "/api/health"; do
                    ROUTE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 http://${CONTAINER_IP}:${PORT}${route} 2>&1)
                    if [ "$ROUTE_RESPONSE" != "000" ] && [ "$ROUTE_RESPONSE" != "404" ]; then
                        echo "   ✅ $route -> HTTP $ROUTE_RESPONSE"
                    fi
                done
            fi
        else
            echo "⚠️ No se pudo obtener IP del contenedor"
        fi
    else
        echo "⚠️ No se encontró contenedor activo"
    fi
    
    echo ""
done

# Verificar configuración de Traefik
echo "=== CONFIGURACIÓN DE TRAEFIK ==="
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
    echo ""
done

echo "=== VERIFICANDO ACCESO A TRAVÉS DE TRAEFIK ==="
for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    echo "Respuesta: HTTP $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Funciona correctamente"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ Ruta no encontrada - puede necesitar configuración de path en Traefik"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






