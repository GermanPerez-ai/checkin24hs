#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO PROBLEMA DE DNS/RED TRAEFIK-WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar resolución DNS
echo "=== 1. Verificando resolución DNS ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Probando resolución DNS del nombre del servicio..."
    docker exec $TRAEFIK_CONTAINER nslookup checkin24hs_webmail 2>&1 || \
    docker exec $TRAEFIK_CONTAINER getent hosts checkin24hs_webmail 2>&1 || \
    docker exec $TRAEFIK_CONTAINER ping -c 1 checkin24hs_webmail 2>&1 | head -3
    echo ""
fi

# 2. Obtener VIP (Virtual IP) del servicio webmail
echo "=== 2. Obteniendo VIP del servicio webmail ==="
WEBMAIL_VIP=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID (index (docker network ls --filter "name=easypanel" --format "{{.ID}}") 0)}}{{.Addr}}{{end}}{{end}}' 2>&1)
if [ -z "$WEBMAIL_VIP" ]; then
    # Método alternativo: obtener todas las VIPs
    WEBMAIL_VIPS=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' 2>&1)
    echo "VIPs del webmail: $WEBMAIL_VIPS"
    # Obtener la primera VIP y quitarle el /24
    WEBMAIL_VIP=$(echo $WEBMAIL_VIPS | awk '{print $1}' | cut -d'/' -f1)
fi
echo "VIP del webmail: $WEBMAIL_VIP"
echo ""

# 3. Obtener red EasyPanel
echo "=== 3. Obteniendo red EasyPanel ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
echo "Red EasyPanel: $EASYPANEL_NET ($EASYPANEL_NET_NAME)"
echo ""

# 4. Verificar que ambos servicios estén en la misma red
echo "=== 4. Verificando redes de los servicios ==="
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $WEBMAIL_NETS"
echo "Redes de Traefik: $TRAEFIK_NETS"
echo ""

# Verificar si están en la misma red EasyPanel
if echo "$WEBMAIL_NETS" | grep -q "$EASYPANEL_NET"; then
    echo "✅ Webmail está en la red EasyPanel"
else
    echo "❌ Webmail NO está en la red EasyPanel"
    echo "Agregando webmail a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
    sleep 15
fi

if echo "$TRAEFIK_NETS" | grep -q "$EASYPANEL_NET"; then
    echo "✅ Traefik está en la red EasyPanel"
else
    echo "❌ Traefik NO está en la red EasyPanel"
    echo "Agregando Traefik a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET traefik
    sleep 15
fi
echo ""

# 5. Reiniciar ambos servicios para forzar actualización de red
echo "=== 5. Reiniciando servicios para aplicar cambios de red ==="
echo "Reiniciando webmail..."
docker service update --force checkin24hs_webmail
echo "Reiniciando Traefik..."
docker service update --force traefik
echo "⏳ Esperando 30 segundos para que se reinicien..."
sleep 30
echo ""

# 6. Probar diferentes métodos de conexión
echo "=== 6. Probando diferentes métodos de conexión ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Método 1: Por nombre de servicio (checkin24hs_webmail:80)..."
    RESPONSE1=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://checkin24hs_webmail:80 2>&1 | head -3)
    if [ -n "$RESPONSE1" ] && ! echo "$RESPONSE1" | grep -q "can't connect\|unreachable\|timeout"; then
        echo "✅ Funciona por nombre de servicio"
    else
        echo "❌ No funciona por nombre de servicio"
        
        echo ""
        echo "Método 2: Por VIP ($WEBMAIL_VIP:80)..."
        if [ -n "$WEBMAIL_VIP" ]; then
            RESPONSE2=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://$WEBMAIL_VIP:80 2>&1 | head -3)
            if [ -n "$RESPONSE2" ] && ! echo "$RESPONSE2" | grep -q "can't connect\|unreachable\|timeout"; then
                echo "✅ Funciona por VIP"
                echo "El problema es la resolución DNS. Usaremos VIP en la configuración."
                # Actualizar Traefik para usar VIP
                docker service update \
                  --label-add "traefik.http.services.webmail.loadbalancer.server=$WEBMAIL_VIP:80" \
                  checkin24hs_webmail
            else
                echo "❌ Tampoco funciona por VIP"
            fi
        fi
        
        echo ""
        echo "Método 3: Por IP del contenedor..."
        WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
        if [ -n "$WEBMAIL_CONTAINER" ]; then
            # Obtener IP del contenedor en la red EasyPanel
            WEBMAIL_IP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "'$EASYPANEL_NET_NAME'"}}{{$conf.IPAddress}}{{end}}{{end}}' 2>&1)
            if [ -n "$WEBMAIL_IP" ]; then
                echo "IP del contenedor: $WEBMAIL_IP"
                RESPONSE3=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://$WEBMAIL_IP:80 2>&1 | head -3)
                if [ -n "$RESPONSE3" ] && ! echo "$RESPONSE3" | grep -q "can't connect\|unreachable\|timeout"; then
                    echo "✅ Funciona por IP del contenedor"
                    echo "El problema es la resolución DNS. Usaremos IP del contenedor en la configuración."
                    # Actualizar Traefik para usar IP del contenedor
                    docker service update \
                      --label-add "traefik.http.services.webmail.loadbalancer.server=$WEBMAIL_IP:80" \
                      checkin24hs_webmail
                else
                    echo "❌ Tampoco funciona por IP del contenedor"
                    echo "El problema es más profundo - no hay conectividad de red"
                fi
            fi
        fi
    fi
fi
echo ""

# 7. Verificar configuración final
echo "=== 7. Configuración final de Traefik ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "Si alguno de los métodos funcionó, el webmail debería estar accesible."
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""





