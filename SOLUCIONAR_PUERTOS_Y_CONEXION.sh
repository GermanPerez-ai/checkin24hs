#!/bin/bash
# Solucionar problemas de puertos y conexión

echo "=== DIAGNÓSTICO DE PUERTOS ==="
echo ""

# Verificar qué está usando los puertos
for port in 3001 3002 3003 3004; do
    echo "Puerto $port:"
    netstat -tuln | grep ":$port " || ss -tuln | grep ":$port " || echo "   No se pudo verificar"
done

echo ""
echo "=== VERIFICANDO CONTENEDORES EN PUERTOS ==="
echo ""

for port in 3001 3002 3003 3004; do
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep ":$port->" | awk '{print $1}' | head -n 1)
    if [ -n "$CONTAINER" ]; then
        echo "Puerto $port usado por: $CONTAINER"
    fi
done

echo ""
echo "=== SOLUCIÓN: REMOVER PUERTOS PUBLICADOS ==="
echo ""
echo "Los servicios de WhatsApp no necesitan puertos publicados si usan Traefik."
echo "Vamos a remover los puertos publicados para evitar conflictos:"
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "Removiendo puerto publicado ${PORT} de $SERVICE_NAME..."
    
    # Obtener configuración actual de puertos
    CURRENT_PORTS=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}/{{.TargetPort}}/{{.Protocol}}{{","}}{{end}}' 2>/dev/null)
    
    if [ -n "$CURRENT_PORTS" ]; then
        echo "   Puertos actuales: $CURRENT_PORTS"
        
        # Remover puerto publicado (esto requiere recrear el servicio sin puertos)
        echo "   ⚠️ Para remover puertos publicados, necesitas recrear el servicio desde EasyPanel"
        echo "   O usar: docker service update --publish-rm ${PORT}:${PORT} $SERVICE_NAME"
    else
        echo "   ✅ No tiene puertos publicados"
    fi
    
    echo ""
done

echo "=== ALTERNATIVA: USAR VIP DEL SERVICIO ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "=== $SERVICE_NAME ==="
    
    # Obtener VIP del servicio en la red easypanel
    EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}' 2>/dev/null)
    VIP=$(docker service inspect $SERVICE_NAME --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)
    
    if [ -n "$VIP" ]; then
        echo "VIP en easypanel: $VIP"
        echo "Configurando Traefik para usar VIP..."
        
        docker service update \
            --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
            --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${VIP}:${PORT}" \
            $SERVICE_NAME 2>&1 | head -3
        
        echo "   ✅ Configurado para usar VIP ${VIP}:${PORT}"
    else
        echo "   ⚠️ No se encontró VIP en la red easypanel"
    fi
    
    echo ""
done

echo "⏳ Espera 10 segundos..."
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
        echo "❌ HTTP 502 - Bad Gateway"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






