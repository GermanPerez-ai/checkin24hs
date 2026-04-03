#!/bin/bash
# Aplicar configuración anti-caché completa

echo "=== APLICANDO CONFIGURACIÓN ANTI-CACHÉ COMPLETA ==="
echo ""

# 1. Copiar server.js actualizado a los contenedores
echo "📦 1. Copiando server.js a los contenedores..."
CONTAINERS=$(docker service ps checkin24hs_dashboard --filter "desired-state=running" --format "{{.Name}}" 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
    echo "   ⚠️  No se encontraron contenedores corriendo, buscando contenedores activos..."
    CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" 2>/dev/null)
fi

if [ -z "$CONTAINERS" ]; then
    echo "   ⚠️  No se encontraron contenedores"
else
    echo "$CONTAINERS" | while read -r CONTAINER; do
        if [ -n "$CONTAINER" ]; then
            echo "   Copiando a $CONTAINER..."
            # Intentar diferentes rutas comunes
            if docker cp server.js "${CONTAINER}:/app/server.js" 2>/dev/null; then
                echo "   ✅ Copiado a $CONTAINER (ruta: /app/server.js)"
            elif docker cp server.js "${CONTAINER}:/root/checkin24hs/server.js" 2>/dev/null; then
                echo "   ✅ Copiado a $CONTAINER (ruta: /root/checkin24hs/server.js)"
            elif docker cp server.js "${CONTAINER}:/usr/src/app/server.js" 2>/dev/null; then
                echo "   ✅ Copiado a $CONTAINER (ruta: /usr/src/app/server.js)"
            else
                echo "   ⚠️  Error al copiar a $CONTAINER, intentando encontrar ruta..."
                docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | head -3
            fi
        fi
    done
fi

# 2. Configurar Traefik con middlewares anti-caché
echo ""
echo "🔧 2. Configurando Traefik con headers anti-caché..."

docker service update \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate, proxy-revalidate" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Pragma=no-cache" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Expires=0" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Surrogate-Control=no-store" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-nocache" \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo "   ✅ Middlewares configurados"

# 3. Reiniciar servicio
echo ""
echo "🔄 3. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "⏳ Esperando 25 segundos..."
sleep 25

# 4. Verificar headers
echo ""
echo "🔍 4. Verificando headers HTTP..."
echo ""
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|surrogate|http" | head -10

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "✅ Cambios aplicados:"
echo "   - Headers anti-caché en Node.js"
echo "   - Headers anti-caché en Traefik"
echo "   - Servicio reiniciado"
echo ""
echo "📋 Para probar en otra computadora:"
echo "   1. Abre: https://dashboard.checkin24hs.com/?v=$(date +%s)"
echo "   2. Presiona Ctrl+Shift+R (o Cmd+Shift+R en Mac)"
echo "   3. O limpia el caché del navegador"
echo ""
