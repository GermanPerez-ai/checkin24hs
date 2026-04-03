#!/bin/bash
# Solución completa anti-caché para el dashboard

echo "=== SOLUCIÓN COMPLETA ANTI-CACHÉ ==="
echo ""

# 1. Copiar dashboard.html actualizado
echo "📦 1. Copiando dashboard.html actualizado..."
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "   Contenedor: $CONTAINER"

# Buscar ruta de dashboard.html
DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    # Intentar rutas comunes
    if docker exec "$CONTAINER" test -d /app 2>/dev/null; then
        DASHBOARD_PATH="/app/dashboard.html"
    elif docker exec "$CONTAINER" test -d /usr/src/app 2>/dev/null; then
        DASHBOARD_PATH="/usr/src/app/dashboard.html"
    else
        echo "   ⚠️  Buscando estructura del contenedor..."
        docker exec "$CONTAINER" ls -la / 2>/dev/null | head -15
        echo ""
        echo "   Por favor, indica la ruta donde está dashboard.html en el contenedor:"
        read -r DASHBOARD_PATH
    fi
fi

if [ -n "$DASHBOARD_PATH" ]; then
    echo "   Ruta encontrada: $DASHBOARD_PATH"
    docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_PATH}" 2>/dev/null && \
        echo "   ✅ dashboard.html copiado exitosamente" || \
        echo "   ❌ Error al copiar dashboard.html"
else
    echo "   ❌ No se pudo determinar la ruta"
fi

# 2. Copiar server.js si existe
if [ -f "server.js" ]; then
    echo ""
    echo "📦 2. Copiando server.js actualizado..."
    SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)
    
    if [ -n "$SERVER_PATH" ]; then
        echo "   Ruta encontrada: $SERVER_PATH"
        docker cp server.js "${CONTAINER}:${SERVER_PATH}" 2>/dev/null && \
            echo "   ✅ server.js copiado exitosamente" || \
            echo "   ⚠️  Error al copiar server.js (puede ser normal si no se usa)"
    else
        echo "   ⚠️  server.js no encontrado en el contenedor (puede ser normal)"
    fi
fi

# 3. Reiniciar contenedor
echo ""
echo "🔄 3. Reiniciando contenedor..."
docker restart "$CONTAINER" 2>/dev/null && \
    echo "   ✅ Contenedor reiniciado" || \
    echo "   ⚠️  Error al reiniciar (puede ser un servicio de Docker Swarm)"

# 4. Verificar headers de Traefik
echo ""
echo "🔧 4. Verificando configuración de Traefik..."
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -i "cache\|nocache" | head -10

# 5. Esperar
echo ""
echo "⏳ Esperando 20 segundos para que el servicio se inicie..."
sleep 20

# 6. Verificar headers HTTP
echo ""
echo "🔍 5. Verificando headers HTTP..."
echo ""
HEADERS=$(curl -I https://dashboard.checkin24hs.com 2>&1)
echo "$HEADERS" | grep -iE "cache-control|pragma|expires|surrogate|http" | head -10

# Verificar que los headers están presentes
if echo "$HEADERS" | grep -qi "cache-control.*no-cache"; then
    echo ""
    echo "✅ Headers anti-caché configurados correctamente"
else
    echo ""
    echo "⚠️  Los headers anti-caché pueden no estar configurados correctamente"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 INSTRUCCIONES PARA CLIENTES:"
echo ""
echo "Si un cliente ve la versión antigua, debe hacer lo siguiente:"
echo ""
echo "1. FORZAR RECARGA SIN CACHÉ:"
echo "   - Windows/Linux: Presiona Ctrl + Shift + R"
echo "   - Mac: Presiona Cmd + Shift + R"
echo ""
echo "2. LIMPIAR CACHÉ COMPLETAMENTE:"
echo "   - Chrome/Edge: Ctrl+Shift+Delete → Seleccionar 'Cached images and files' → Limpiar"
echo "   - Firefox: Ctrl+Shift+Delete → Seleccionar 'Caché' → Limpiar"
echo ""
echo "3. ABRIR CON PARÁMETRO DE VERSIÓN:"
echo "   https://dashboard.checkin24hs.com/?v=$(date +%s)"
echo ""
echo "4. MODO INCÓGNITO (para probar):"
echo "   Abre el dashboard en modo incógnito/privado"
echo ""
echo "NOTA: Los cambios pueden tardar 1-2 minutos en propagarse debido a cachés intermedios."
echo ""

