#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICANDO CONECTIVIDAD TRAEFIK -> WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar que Traefik puede resolver el nombre del servicio
echo "=== 1. VERIFICANDO RESOLUCIÓN DNS ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "Probando resolución DNS del servicio webmail..."
    docker exec $TRAEFIK_CONTAINER nslookup checkin24hs_webmail 2>&1 || docker exec $TRAEFIK_CONTAINER getent hosts checkin24hs_webmail 2>&1
    echo ""
    
    # 2. Probar conexión directa desde Traefik
    echo "=== 2. PROBANDO CONEXIÓN DESDE TRAEFIK ==="
    echo "Probando http://checkin24hs_webmail:80..."
    RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://checkin24hs_webmail:80 2>&1 | head -5)
    if [ -n "$RESPONSE" ]; then
        echo "✅ Traefik PUEDE conectarse al webmail"
        echo "Respuesta:"
        echo "$RESPONSE" | head -3
    else
        echo "❌ Traefik NO puede conectarse al webmail"
        echo "Esto explica el error 504"
    fi
    echo ""
    
    # 3. Verificar configuración de Traefik
    echo "=== 3. CONFIGURACIÓN DE TRAEFIK PARA WEBMAIL ==="
    docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
    echo ""
    
    # 4. Verificar logs de Traefik para errores específicos
    echo "=== 4. LOGS DE TRAEFIK (errores relacionados con webmail) ==="
    docker logs $TRAEFIK_CONTAINER --tail 100 2>&1 | grep -i "webmail\|504\|timeout\|connection refused\|no such host" | tail -10 || echo "No se encontraron errores específicos"
    echo ""
    
    # 5. Verificar que están en la misma red
    echo "=== 5. VERIFICANDO REDES ==="
    WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
    TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
    echo "Redes del webmail: $WEBMAIL_NETS"
    echo "Redes de Traefik: $TRAEFIK_NETS"
    
    # Verificar si hay red en común
    for webmail_net in $WEBMAIL_NETS; do
        for traefik_net in $TRAEFIK_NETS; do
            if [ "$webmail_net" = "$traefik_net" ]; then
                echo "✅ Hay una red en común: $webmail_net"
                COMMON_NET_FOUND=true
            fi
        done
    done
    
    if [ -z "$COMMON_NET_FOUND" ]; then
        echo "❌ NO hay redes en común - ESTE ES EL PROBLEMA"
    fi
    echo ""
    
else
    echo "❌ No se encontró contenedor de Traefik"
fi

echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo ""
echo "El webmail está funcionando correctamente (según los logs)."
echo "El problema es que Traefik no puede conectarse al webmail."
echo ""
echo "Si Traefik no puede conectarse, verifica:"
echo "  1. Que estén en la misma red Docker"
echo "  2. Que el nombre del servicio sea correcto (checkin24hs_webmail)"
echo "  3. Que el puerto configurado sea 80 (puerto interno)"
echo ""

