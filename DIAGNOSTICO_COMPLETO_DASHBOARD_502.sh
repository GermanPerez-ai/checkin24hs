#!/bin/bash
# Diagnóstico completo del problema 502/504

echo "=== DIAGNÓSTICO COMPLETO DEL DASHBOARD ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de dashboard"
    exit 1
fi

echo "1. Verificando configuración de nginx dentro del contenedor..."
echo "   Contenedor: $CONTAINER"
echo ""
echo "   Configuración de nginx:"
docker exec $CONTAINER cat /etc/nginx/conf.d/default.conf 2>/dev/null || \
docker exec $CONTAINER cat /etc/nginx/nginx.conf 2>/dev/null | head -30

echo ""
echo "2. Verificando si nginx está corriendo dentro del contenedor..."
docker exec $CONTAINER ps aux | grep nginx || echo "   ⚠️ Nginx no encontrado en procesos"

echo ""
echo "3. Verificando puertos en escucha dentro del contenedor..."
docker exec $CONTAINER sh -c "netstat -tuln 2>/dev/null | grep LISTEN || ss -tuln 2>/dev/null | grep LISTEN" || echo "   ⚠️ No se pudieron verificar puertos"

echo ""
echo "4. Probando acceso directo al dashboard desde dentro del contenedor..."
docker exec $CONTAINER wget -O- --timeout=5 http://localhost/dashboard.html 2>&1 | head -10 || \
docker exec $CONTAINER curl -s http://localhost/dashboard.html 2>&1 | head -5

echo ""
echo "5. Verificando archivo dashboard.html existe..."
docker exec $CONTAINER ls -lh /app/dashboard.html 2>/dev/null || \
docker exec $CONTAINER ls -lh /usr/share/nginx/html/dashboard.html 2>/dev/null || \
docker exec $CONTAINER find / -name "dashboard.html" 2>/dev/null | head -3

echo ""
echo "6. Verificando logs de nginx dentro del contenedor..."
docker exec $CONTAINER tail -20 /var/log/nginx/error.log 2>/dev/null || \
docker exec $CONTAINER tail -20 /var/log/nginx/access.log 2>/dev/null || \
echo "   ⚠️ No se encontraron logs de nginx"

echo ""
echo "7. Verificando conectividad desde Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "   Traefik: $TRAEFIK_CONTAINER"
    echo "   Probando conexión a VIP 10.0.1.4:80..."
    docker exec $TRAEFIK_CONTAINER wget -O- --timeout=5 http://10.0.1.4:80/dashboard.html 2>&1 | head -10 || echo "   ❌ No se pudo conectar"
    
    echo "   Probando conexión a checkin24hs_dashboard:80..."
    docker exec $TRAEFIK_CONTAINER wget -O- --timeout=5 http://checkin24hs_dashboard:80/dashboard.html 2>&1 | head -10 || echo "   ❌ No se pudo conectar"
fi

echo ""
echo "8. Verificando labels actuales de Traefik..."
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""
echo "=== RESUMEN ==="
echo "Revisa los resultados arriba para identificar el problema específico."
echo ""






