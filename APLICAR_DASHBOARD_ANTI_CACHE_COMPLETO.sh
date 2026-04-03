#!/bin/bash
# Aplicar dashboard.html con anti-caché completo

echo "=== APLICANDO DASHBOARD CON ANTI-CACHÉ COMPLETO ==="
echo ""

# 1. Verificar que dashboard.html existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    exit 1
fi

echo "📦 1. Copiando dashboard.html a los contenedores..."
CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
    echo "   ⚠️  No se encontraron contenedores"
    exit 1
fi

for CONTAINER in $CONTAINERS; do
    echo "   Copiando a $CONTAINER..."
    
    # Intentar diferentes rutas comunes
    if docker exec "$CONTAINER" test -d /app 2>/dev/null; then
        docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html" 2>/dev/null && \
            echo "   ✅ Copiado a $CONTAINER (ruta: /app/dashboard.html)" || \
            echo "   ⚠️  Error copiando a /app/dashboard.html"
    elif docker exec "$CONTAINER" test -d /usr/src/app 2>/dev/null; then
        docker cp deploy/dashboard.html "${CONTAINER}:/usr/src/app/dashboard.html" 2>/dev/null && \
            echo "   ✅ Copiado a $CONTAINER (ruta: /usr/src/app/dashboard.html)" || \
            echo "   ⚠️  Error copiando a /usr/src/app/dashboard.html"
    else
        # Buscar dónde está dashboard.html
        DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
        if [ -n "$DASHBOARD_PATH" ]; then
            DASHBOARD_DIR=$(dirname "$DASHBOARD_PATH")
            docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_PATH}" 2>/dev/null && \
                echo "   ✅ Copiado a $CONTAINER (ruta: $DASHBOARD_PATH)" || \
                echo "   ⚠️  Error copiando a $DASHBOARD_PATH"
        else
            echo "   ⚠️  No se encontró dashboard.html en el contenedor"
            echo "   📋 Estructura del contenedor:"
            docker exec "$CONTAINER" ls -la / 2>/dev/null | head -10
        fi
    fi
    
    # Reiniciar contenedor
    echo "   🔄 Reiniciando $CONTAINER..."
    docker restart "$CONTAINER" 2>/dev/null && \
        echo "   ✅ $CONTAINER reiniciado" || \
        echo "   ⚠️  Error reiniciando $CONTAINER"
done

# 2. Verificar headers de Traefik
echo ""
echo "🔧 2. Verificando headers anti-caché en Traefik..."
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -i "cache\|nocache" | head -5

# 3. Esperar a que los contenedores estén listos
echo ""
echo "⏳ Esperando 15 segundos para que los contenedores se inicien..."
sleep 15

# 4. Verificar headers HTTP
echo ""
echo "🔍 3. Verificando headers HTTP..."
echo ""
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|surrogate|http" | head -10

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "✅ Cambios aplicados:"
echo "   - dashboard.html actualizado con meta tags anti-caché"
echo "   - Headers anti-caché en Traefik"
echo "   - Contenedores reiniciados"
echo ""
echo "📋 Para probar en otra computadora:"
echo "   1. Abre: https://dashboard.checkin24hs.com/?v=$(date +%s)"
echo "   2. Presiona Ctrl+Shift+R (o Cmd+Shift+R en Mac)"
echo "   3. O limpia completamente el caché del navegador"
echo "   4. Si aún ves la versión antigua, espera 1-2 minutos y vuelve a intentar"
echo ""





