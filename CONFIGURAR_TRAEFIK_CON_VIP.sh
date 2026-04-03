#!/bin/bash
# Configurar Traefik usando VIP de los servicios

echo "=== CONFIGURANDO TRAEFIK CON VIP ==="
echo ""

# Obtener ID de la red easypanel
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}')
echo "ID de red easypanel: $EASYPANEL_NET_ID"
echo ""

# Para cada servicio, obtener su VIP y configurar Traefik
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "=== Configurando $SERVICE_NAME ==="
    
    # Obtener VIP del servicio en la red easypanel
    VIP=$(docker service inspect $SERVICE_NAME --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)
    
    if [ -n "$VIP" ]; then
        echo "VIP encontrado: $VIP"
        echo "Configurando Traefik para usar http://${VIP}:${PORT}..."
        
        # Remover configuración anterior si existe
        docker service update \
            --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
            $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
        
        sleep 2
        
        # Agregar nueva configuración con VIP
        docker service update \
            --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${VIP}:${PORT}" \
            $SERVICE_NAME 2>&1 | head -5
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Configurado correctamente"
        else
            echo "   ⚠️ Error en la configuración"
        fi
    else
        echo "   ⚠️ No se encontró VIP en la red easypanel"
        echo "   El servicio puede no estar en la red easypanel o no tener VIP asignado"
    fi
    
    echo ""
done

echo "⏳ Espera 15 segundos para que Traefik recargue la configuración..."
sleep 15

echo ""
echo "=== VERIFICANDO CONFIGURACIÓN APLICADA ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep "loadbalancer.server"
    echo ""
done

echo "=== PROBANDO CONEXIÓN HTTPS ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - ¡Funciona correctamente!"
        echo "Respuesta:"
        curl -s https://${SUBDOMAIN}/api/qr?card=${i} | head -3
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Bad Gateway (Traefik no puede conectar)"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "❌ Sin respuesta"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






