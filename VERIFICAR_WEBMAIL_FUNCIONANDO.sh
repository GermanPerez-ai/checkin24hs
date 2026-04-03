#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "✅ VERIFICANDO QUE WEBMAIL ESTÉ FUNCIONANDO"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "=== 1. Estado del servicio webmail ==="
docker service ps checkin24hs_webmail --no-trunc | head -3
echo ""

# 2. Verificar que responde
echo "=== 2. Verificando que el webmail responde ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Contenedor: $WEBMAIL_CONTAINER"
    RESPONSE=$(docker exec $WEBMAIL_CONTAINER wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -5)
    if [ -n "$RESPONSE" ]; then
        echo "✅ Webmail responde correctamente"
    else
        echo "⚠️ Webmail no responde (puede estar iniciando)"
    fi
else
    echo "⚠️ No se encontró contenedor del webmail"
fi
echo ""

# 3. Verificar conectividad desde Traefik
echo "=== 3. Verificando conectividad desde Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Probando conexión desde Traefik..."
    RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://checkin24hs_webmail:80 2>&1 | head -5)
    if [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q "can't connect\|unreachable\|timeout"; then
        echo "✅ Traefik PUEDE conectarse al webmail"
    else
        echo "⚠️ Traefik aún no puede conectarse (puede estar reiniciando)"
        echo "Respuesta: $RESPONSE"
    fi
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 4. Verificar configuración de Traefik
echo "=== 4. Configuración de Traefik ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
echo ""

# 5. Verificar redes
echo "=== 5. Verificando redes ==="
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $WEBMAIL_NETS"
echo "Redes de Traefik: $TRAEFIK_NETS"
echo ""

# Verificar si hay red en común
COMMON_NET_FOUND=false
for webmail_net in $WEBMAIL_NETS; do
    for traefik_net in $TRAEFIK_NETS; do
        if [ "$webmail_net" = "$traefik_net" ]; then
            echo "✅ Hay una red en común: $webmail_net"
            COMMON_NET_FOUND=true
        fi
    done
done

if [ "$COMMON_NET_FOUND" = false ]; then
    echo "❌ NO hay redes en común"
else
    echo "✅ Redes configuradas correctamente"
fi
echo ""

# 6. Verificar logs recientes
echo "=== 6. Logs recientes del webmail (últimas 5 líneas) ==="
if [ -n "$WEBMAIL_CONTAINER" ]; then
    docker logs $WEBMAIL_CONTAINER --tail 5 2>&1
fi
echo ""

echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo ""
echo "Si ves peticiones exitosas (200) en los logs, el webmail está funcionando."
echo ""
echo "Prueba acceder a:"
echo "  - https://webmail.checkin24hs.com"
echo ""
echo "Si aún ves error 504, espera 1-2 minutos más para que los contenedores"
echo "terminen de reiniciarse completamente."
echo ""





