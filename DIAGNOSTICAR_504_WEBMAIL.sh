#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO: 504 GATEWAY TIMEOUT"
echo "=========================================="
echo ""

# 1. Verificar que el webmail esté respondiendo
echo "=== 1. VERIFICANDO QUE EL WEBMAIL RESPONDE ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Contenedor encontrado: $WEBMAIL_CONTAINER"
    echo "Probando respuesta HTTP desde dentro del contenedor..."
    docker exec $WEBMAIL_CONTAINER wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -5 || echo "❌ El webmail NO responde en el puerto 80"
else
    echo "❌ No se encontró contenedor del webmail"
fi
echo ""

# 2. Verificar puerto expuesto
echo "=== 2. VERIFICANDO PUERTO DEL WEBMAIL ==="
echo "Puerto publicado:"
docker service inspect checkin24hs_webmail --format='{{range .Spec.EndpointSpec.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{"\n"}}{{end}}' 2>&1
echo ""

# 3. Verificar puerto configurado en Traefik
echo "=== 3. PUERTO CONFIGURADO EN TRAEFIK ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i "port\|server" | grep traefik
echo ""

# 4. Verificar redes y conectividad
echo "=== 4. VERIFICANDO REDES Y CONECTIVIDAD ==="
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
TRAEFIK_NETS=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1)
echo "Redes del webmail: $WEBMAIL_NETS"
echo "Redes de Traefik: $TRAEFIK_NETS"
echo ""

# Verificar si hay red en común
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -n "$EASYPANEL_NET" ]; then
    echo "Red EasyPanel: $EASYPANEL_NET"
    echo "Verificando si webmail está en esta red..."
    docker network inspect $EASYPANEL_NET --format='{{range .Containers}}{{.Name}} {{end}}' 2>&1 | grep -q webmail && echo "✅ Webmail está en la red EasyPanel" || echo "❌ Webmail NO está en la red EasyPanel"
fi
echo ""

# 5. Probar conectividad desde Traefik
echo "=== 5. PROBANDO CONECTIVIDAD DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ] && [ -n "$WEBMAIL_CONTAINER" ]; then
    # Obtener IP del webmail en la red compartida
    WEBMAIL_IP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$conf.IPAddress}}{{end}}' 2>&1 | head -1)
    if [ -n "$WEBMAIL_IP" ]; then
        echo "IP del webmail: $WEBMAIL_IP"
        echo "Probando conexión desde Traefik..."
        docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://$WEBMAIL_IP:80 2>&1 | head -5 || echo "❌ Traefik NO puede conectarse al webmail por IP"
        
        # También probar por nombre de servicio
        echo "Probando por nombre de servicio (checkin24hs_webmail)..."
        docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 http://checkin24hs_webmail:80 2>&1 | head -5 || echo "❌ Traefik NO puede conectarse por nombre de servicio"
    else
        echo "⚠️ No se pudo obtener la IP del webmail"
    fi
else
    echo "⚠️ No se encontraron contenedores necesarios"
fi
echo ""

# 6. Verificar logs de Traefik para errores específicos
echo "=== 6. LOGS DE TRAEFIK (errores relacionados con webmail) ==="
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs $TRAEFIK_CONTAINER --tail 100 2>&1 | grep -i "webmail\|504\|timeout\|connection refused" | tail -10 || echo "No se encontraron errores específicos"
fi
echo ""

# 7. Verificar logs del webmail
echo "=== 7. LOGS DEL WEBMAIL (últimas 20 líneas) ==="
if [ -n "$WEBMAIL_CONTAINER" ]; then
    docker logs $WEBMAIL_CONTAINER --tail 20 2>&1 | tail -15
fi
echo ""

# 8. Resumen y recomendaciones
echo "=========================================="
echo "📊 RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Un error 504 significa que:"
echo "  - Traefik está recibiendo las peticiones ✅"
echo "  - Traefik está intentando conectarse al webmail ❌"
echo "  - Pero el webmail no responde o no es accesible ❌"
echo ""
echo "Posibles causas:"
echo "  1. El webmail no está en la misma red que Traefik"
echo "  2. El puerto configurado es incorrecto"
echo "  3. El webmail no está respondiendo correctamente"
echo "  4. Hay un problema de firewall o red"
echo ""





