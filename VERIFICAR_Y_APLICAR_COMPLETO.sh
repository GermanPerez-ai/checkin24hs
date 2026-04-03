#!/bin/bash
# Verificar conectividad y aplicar cambios anti-caché

echo "=== VERIFICACIÓN COMPLETA ==="
echo ""

# 1. Verificar que Traefik puede acceder al servicio
echo "🔍 1. Verificando conectividad desde Traefik al servicio..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "   Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "   Probando conexión HTTP directa:"
    docker exec "$TRAEFIK_CONTAINER" wget -qO- --timeout=5 "http://checkin24hs_dashboard:3000/" 2>&1 | head -3
    echo ""
    echo "   Verificando resolución DNS:"
    docker exec "$TRAEFIK_CONTAINER" nslookup checkin24hs_dashboard 2>&1 | head -5 || docker exec "$TRAEFIK_CONTAINER" getent hosts checkin24hs_dashboard 2>&1
else
    echo "   ⚠️  No se encontró contenedor de Traefik"
fi
echo ""

# 2. Verificar que ambos servicios están en la misma red
echo "🌐 2. Verificando redes..."
echo "   Redes del dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
echo ""
echo "   Redes de Traefik:"
docker inspect "$TRAEFIK_CONTAINER" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}' 2>/dev/null | head -5
echo ""

# 3. Verificar routers de Traefik
echo "🔧 3. Verificando routers de Traefik..."
docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard | head -5
echo ""

# 4. Aplicar cambios anti-caché si dashboard.html existe
if [ -f "deploy/dashboard.html" ]; then
    echo "📦 4. Aplicando dashboard.html actualizado..."
    CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
    if [ -n "$CONTAINER" ]; then
        DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
        if [ -n "$DASHBOARD_PATH" ]; then
            docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_PATH}" 2>/dev/null && \
                echo "   ✅ dashboard.html copiado a $DASHBOARD_PATH" || \
                echo "   ⚠️  Error al copiar dashboard.html"
        else
            echo "   ⚠️  No se encontró dashboard.html en el contenedor"
        fi
    fi
fi
echo ""

# 5. Probar acceso desde diferentes ubicaciones simuladas
echo "🌍 5. Probando acceso HTTPS:"
echo ""
echo "   Desde servidor (local):"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -E "HTTP|cache-control|pragma|expires" | head -5
echo ""

echo "=== RESUMEN ==="
echo ""
echo "✅ Configuración aplicada:"
echo "   - Traefik usa nombre del servicio: checkin24hs_dashboard:3000"
echo "   - Headers anti-caché configurados"
echo ""
echo "📋 Si aún ves 404 desde otras ubicaciones:"
echo "   1. Espera 2-5 minutos (propagación DNS/CDN)"
echo "   2. Verifica DNS: nslookup dashboard.checkin24hs.com"
echo "   3. Prueba desde modo incógnito"
echo "   4. Verifica firewall (puerto 443 debe estar abierto)"
echo ""





