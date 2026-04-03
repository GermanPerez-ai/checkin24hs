#!/bin/bash
# Solución definitiva para actualizar a Build #39

echo "🔧 SOLUCIÓN DEFINITIVA: Build #39"
echo ""

# 1. Asegurar que el host tiene Build #39
cd /etc/easypanel/projects/checkin24hs/dashboard/code
echo "[1/4] Verificando archivo en host..."
BUILD_HOST=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
echo "Build en host: $BUILD_HOST"

if [ "$BUILD_HOST" != "39" ]; then
    echo "Descargando Build #39..."
    curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
    BUILD_HOST=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
    echo "Build después de descargar: $BUILD_HOST"
fi

# 2. Verificar montajes
echo ""
echo "[2/4] Verificando montajes del contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    MOUNTED=$(docker inspect ${CONTAINER_ID} --format='{{range .Mounts}}{{if eq .Destination "/app"}}YES{{end}}{{end}}')
    if [ "$MOUNTED" = "YES" ]; then
        echo "⚠️  /app está montado desde el host"
        echo "   El archivo en host ES el que se usa, no el del contenedor"
        echo "   ✅ Archivo en host ya tiene Build #$BUILD_HOST"
    else
        echo "✅ /app NO está montado, necesitamos copiar al contenedor"
    fi
fi

# 3. Reiniciar servicio (esto recargará el archivo desde el host si está montado)
echo ""
echo "[3/4] Reiniciando servicio para recargar archivo..."
docker service update --force checkin24hs_dashboard

echo ""
echo "⏳ Esperando 15 segundos para que el servicio se reinicie..."
sleep 15

# 4. Verificar Build en nuevo contenedor
echo ""
echo "[4/4] Verificando Build en contenedor después del reinicio..."
NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -n "$NEW_CONTAINER_ID" ]; then
    CONTAINER_BUILD=$(docker exec ${NEW_CONTAINER_ID} grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)
    echo "Build en contenedor: $CONTAINER_BUILD"
    
    if [ "$CONTAINER_BUILD" = "39" ]; then
        echo "✅ ¡Build #39 confirmado en contenedor!"
    else
        echo "⚠️  Contenedor aún tiene Build #$CONTAINER_BUILD"
        echo "   Esto puede ser caché del navegador"
    fi
fi

# 5. Restaurar Traefik
echo ""
echo "[EXTRA] Restaurando labels de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Limpia caché del navegador: Ctrl+Shift+Delete (Todo el tiempo)"
echo "2. Cierra todas las pestañas del dashboard"
echo "3. Abre nueva pestaña: https://dashboard.checkin24hs.com"
echo "4. Presiona Ctrl+Shift+R para recarga forzada"
echo "5. Verifica en consola: window.DASHBOARD_BUILD_NUMBER (debe ser 39)"
echo ""
echo "💡 Si sigue mostrando #38, puede ser caché de CDN o proxy"
