#!/bin/bash
# Corregir el puerto del dashboard en Traefik

echo "=== CORRIGIENDO PUERTO DEL DASHBOARD EN TRAEFIK ==="
echo ""

# Verificar qué puerto usa realmente el dashboard
echo "1. Verificando puerto del dashboard..."
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de dashboard"
    exit 1
fi

echo "   Contenedor: $CONTAINER"

# Verificar puerto en nginx
NGINX_PORT=$(docker exec $CONTAINER cat /etc/nginx/conf.d/default.conf 2>/dev/null | grep -i "listen" | head -1 | grep -oE "[0-9]+" | head -1)

if [ -z "$NGINX_PORT" ]; then
    # Intentar verificar con netstat/ss dentro del contenedor
    LISTENING_PORTS=$(docker exec $CONTAINER sh -c "netstat -tuln 2>/dev/null | grep LISTEN || ss -tuln 2>/dev/null | grep LISTEN" | grep -oE ":[0-9]+" | grep -oE "[0-9]+" | sort -u)
    if [ -n "$LISTENING_PORTS" ]; then
        echo "   Puertos en escucha dentro del contenedor: $LISTENING_PORTS"
        # El puerto más común para nginx es 80
        NGINX_PORT=80
    else
        echo "   ⚠️ No se pudo determinar el puerto, usando 80 por defecto"
        NGINX_PORT=80
    fi
else
    echo "   Puerto encontrado en nginx.conf: $NGINX_PORT"
fi

# Verificar puerto actual en Traefik
CURRENT_PORT=$(docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep "loadbalancer.server.port" | cut -d= -f2)

echo ""
echo "2. Puerto actual en Traefik: $CURRENT_PORT"
echo "   Puerto correcto debería ser: $NGINX_PORT"

if [ "$CURRENT_PORT" = "$NGINX_PORT" ]; then
    echo "   ✅ El puerto ya está configurado correctamente"
else
    echo "   ⚠️ El puerto está incorrecto, actualizando..."
    
    # Actualizar el puerto en Traefik
    docker service update \
      --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$NGINX_PORT" \
      checkin24hs_dashboard
    
    echo "   ✅ Puerto actualizado a $NGINX_PORT"
    echo "   ⏳ Esperando 10 segundos para que Traefik recargue..."
    sleep 10
fi

echo ""
echo "3. Verificando acceso HTTPS..."
HTTPS_TEST=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com 2>&1)

if [ "$HTTPS_TEST" = "200" ]; then
    echo "   ✅ HTTPS funciona correctamente (HTTP 200)"
elif [ "$HTTPS_TEST" = "502" ]; then
    echo "   ❌ HTTPS aún muestra 502 Bad Gateway"
    echo "   Verificando logs de Traefik..."
    docker logs traefik.1.zq6kinkkhdt9hdgelqs6ry942 --tail 20 2>&1 | grep -iE "dashboard|502|error" | tail -5
else
    echo "   ⚠️ HTTPS responde con HTTP $HTTPS_TEST"
fi

echo ""
echo "=== RESUMEN ==="
echo "Si aún hay problemas:"
echo "1. Verifica que el dashboard esté en la misma red que Traefik:"
echo "   docker network inspect easypanel | grep dashboard"
echo ""
echo "2. Verifica logs de Traefik:"
echo "   docker logs traefik --tail 50 | grep dashboard"
echo ""
echo "3. Prueba acceso directo al dashboard desde Traefik:"
echo "   docker exec traefik.1.zq6kinkkhdt9hdgelqs6ry942 wget -O- http://checkin24hs_dashboard/dashboard.html"
echo ""






