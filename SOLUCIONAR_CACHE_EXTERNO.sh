#!/bin/bash
# Solucionar problema de caché en otros ordenadores/internet
# Agregar headers anti-caché en Node.js y Traefik

echo "=== SOLUCIONANDO CACHÉ EXTERNO ==="
echo ""

# 1. Agregar headers anti-caché al server.js
echo "📝 1. Agregando headers anti-caché al server.js..."

# Verificar si ya tiene los headers
if grep -q "Cache-Control.*no-cache" server.js 2>/dev/null; then
    echo "   ⚠️  server.js ya tiene headers anti-caché"
else
    # Crear backup
    cp server.js server.js.backup.$(date +%Y%m%d_%H%M%S)
    
    # Agregar middleware anti-caché después de express.json()
    sed -i '/app.use(express.json());/a\
\
// Middleware para prevenir caché en todos los archivos HTML y la ruta principal\
app.use((req, res, next) => {\
    if (req.path === '\''/'\'' || req.path === '\''/dashboard.html'\'' || req.path.endsWith('\''.html'\'')) {\
        res.setHeader('\''Cache-Control'\'', '\''no-cache, no-store, must-revalidate, proxy-revalidate'\'');\
        res.setHeader('\''Pragma'\'', '\''no-cache'\'');\
        res.setHeader('\''Expires'\'', '\''0'\'');\
        res.setHeader('\''Surrogate-Control'\'', '\''no-store'\'');\
        res.setHeader('\''X-Content-Type-Options'\'', '\''nosniff'\'');\
    }\
    next();\
});' server.js
    
    echo "   ✅ Headers anti-caché agregados a server.js"
fi

# 2. Actualizar la ruta principal para asegurar headers
echo ""
echo "📝 2. Actualizando ruta principal para asegurar headers..."

# Verificar si la ruta principal ya tiene headers
if grep -q "res.setHeader.*Cache-Control" server.js 2>/dev/null && grep -q "app.get('\''/'\''" server.js 2>/dev/null; then
    # Buscar la línea de app.get('/') y agregar headers antes de sendFile
    sed -i "/app.get('\''\/'\'', (req, res) => {/,/res.sendFile/ {
        /res.sendFile/i\
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate, proxy-revalidate');\
    res.setHeader('Pragma', 'no-cache');\
    res.setHeader('Expires', '0');\
    res.setHeader('Surrogate-Control', 'no-store');
    }" server.js
fi

# 3. Configurar Traefik con middlewares anti-caché
echo ""
echo "🔧 3. Configurando Traefik con middlewares anti-caché..."

# Obtener VIP del servicio
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}' 2>/dev/null)
VIP=$(docker service inspect checkin24hs_dashboard --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)

echo "   VIP del dashboard: $VIP"

# Agregar middlewares de Traefik para headers anti-caché
docker service update \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate, proxy-revalidate" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Pragma=no-cache" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Expires=0" \
  --label-add "traefik.http.middlewares.dashboard-nocache.headers.customResponseHeaders.Surrogate-Control=no-store" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-nocache" \
  checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "   ✅ Middlewares de Traefik configurados"
else
    echo "   ⚠️  Error al configurar middlewares (puede que ya existan)"
fi

# 4. Copiar server.js actualizado a los contenedores
echo ""
echo "📦 4. Copiando server.js actualizado a los contenedores..."

CONTAINERS=$(docker service ps checkin24hs_dashboard --filter "desired-state=running" --format "{{.Name}}" 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
    echo "   ⚠️  No se encontraron contenedores corriendo"
else
    for CONTAINER in $CONTAINERS; do
        echo "   Copiando a $CONTAINER..."
        docker cp server.js ${CONTAINER}:/root/checkin24hs/server.js 2>/dev/null && \
            echo "   ✅ Copiado a $CONTAINER" || \
            echo "   ⚠️  Error al copiar a $CONTAINER (puede necesitar reinicio)"
    done
fi

# 5. Reiniciar servicio para aplicar cambios
echo ""
echo "🔄 5. Reiniciando servicio para aplicar cambios..."
docker service update --force checkin24hs_dashboard

echo ""
echo "⏳ Esperando 20 segundos para que el servicio se estabilice..."
sleep 20

# 6. Verificar headers HTTP
echo ""
echo "🔍 6. Verificando headers HTTP enviados..."

echo ""
echo "   Headers desde el servidor:"
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|surrogate" || echo "   ⚠️  No se encontraron headers anti-caché"

echo ""
echo "   Headers completos:"
curl -I https://dashboard.checkin24hs.com 2>&1 | head -20

echo ""
echo "=== VERIFICACIÓN FINAL ==="
echo ""
echo "✅ Cambios aplicados:"
echo "   1. Headers anti-caché agregados a server.js"
echo "   2. Middlewares de Traefik configurados"
echo "   3. Servicio reiniciado"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "   1. Espera 2-3 minutos para que los cambios se propaguen"
echo "   2. En otra computadora, abre: https://dashboard.checkin24hs.com/?v=$(date +%s)"
echo "   3. Si aún ves versión antigua, presiona Ctrl+Shift+R (o Cmd+Shift+R en Mac)"
echo "   4. O limpia el caché del navegador manualmente"
echo ""
echo "🔍 Para verificar headers desde otra computadora:"
echo "   curl -I https://dashboard.checkin24hs.com | grep -i cache"
echo ""






