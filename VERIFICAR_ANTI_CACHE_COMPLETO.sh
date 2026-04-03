#!/bin/bash
# Verificar que todos los cambios anti-caché estén aplicados

echo "=== VERIFICACIÓN COMPLETA ANTI-CACHÉ ==="
echo ""

# 1. Verificar headers HTTP
echo "🔍 1. Headers HTTP del servidor:"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|surrogate|http" | head -10
echo ""

# 2. Verificar meta tags en dashboard.html del contenedor
echo "📦 2. Verificando meta tags en dashboard.html del contenedor:"
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [ -n "$DASHBOARD_PATH" ]; then
        echo "   Ruta: $DASHBOARD_PATH"
        echo "   Meta tags encontrados:"
        docker exec "$CONTAINER" grep -i "cache-control\|pragma\|expires" "$DASHBOARD_PATH" 2>/dev/null | head -5
    else
        echo "   ⚠️  No se encontró dashboard.html"
    fi
fi
echo ""

# 3. Verificar código de detección de versiones
echo "🔍 3. Verificando código de detección de versiones:"
if [ -n "$CONTAINER" ] && [ -n "$DASHBOARD_PATH" ]; then
    echo "   Buscando código anti-caché..."
    docker exec "$CONTAINER" grep -i "VERSION_KEY\|dashboard_version\|setInterval" "$DASHBOARD_PATH" 2>/dev/null | head -3
fi
echo ""

# 4. Verificar configuración de Traefik
echo "🔧 4. Configuración de Traefik:"
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -i "cache\|nocache" | head -10
echo ""

# 5. Verificar server.js si existe
echo "📄 5. Verificando server.js:"
if [ -n "$CONTAINER" ]; then
    SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [ -n "$SERVER_PATH" ]; then
        echo "   Ruta: $SERVER_PATH"
        echo "   Headers anti-caché encontrados:"
        docker exec "$CONTAINER" grep -i "cache-control\|pragma\|expires" "$SERVER_PATH" 2>/dev/null | head -5
    else
        echo "   ⚠️  server.js no encontrado (puede ser normal si no se usa)"
    fi
fi
echo ""

echo "=== RESUMEN ==="
echo ""
echo "✅ Verificaciones completadas"
echo ""
echo "📋 INSTRUCCIONES PARA CLIENTES QUE VEN VERSIÓN ANTIGUA:"
echo ""
echo "1. FORZAR RECARGA SIN CACHÉ:"
echo "   - Windows/Linux: Ctrl + Shift + R"
echo "   - Mac: Cmd + Shift + R"
echo ""
echo "2. LIMPIAR CACHÉ COMPLETAMENTE:"
echo "   - Chrome/Edge: Ctrl+Shift+Delete → 'Cached images and files' → Limpiar"
echo "   - Firefox: Ctrl+Shift+Delete → 'Caché' → Limpiar"
echo ""
echo "3. MODO INCÓGNITO (para probar):"
echo "   Abre el dashboard en modo incógnito/privado"
echo ""
echo "4. El sistema detectará automáticamente nuevas versiones cada 30 segundos"
echo ""





