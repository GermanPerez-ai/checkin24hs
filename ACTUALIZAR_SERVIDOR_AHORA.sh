#!/bin/bash
# Script para actualizar dashboard en servidor - EJECUTAR EN EL SERVIDOR

echo "🔄 Actualizando dashboard en servidor..."
echo ""

# 1. Descargar archivo actualizado desde GitHub
cd /etc/easypanel/projects/checkin24hs/dashboard/code
echo "📥 Descargando dashboard.html desde GitHub..."
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado correctamente"
else
    echo "❌ Error al descargar archivo"
    exit 1
fi

# 2. Verificar build number
echo ""
echo "🔍 Verificando build number..."
if grep -q "DASHBOARD_BUILD_NUMBER = 39" dashboard.html 2>/dev/null; then
    echo "✅ Build #39 encontrado"
else
    echo "⚠️  Build number puede no estar actualizado"
fi

# 3. Reiniciar servicio
echo ""
echo "🔄 Reiniciando servicio dashboard..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar servicio"
    exit 1
fi

# 4. Esperar unos segundos para que arranque
echo ""
echo "⏳ Esperando 5 segundos para que el servicio inicie..."
sleep 5

# 5. Restaurar labels de Traefik
echo ""
echo "🔧 Restaurando labels de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Labels de Traefik restauradas"
else
    echo "⚠️  Error al restaurar labels (puede que ya existan)"
fi

echo ""
echo "=========================================="
echo "✅ Actualización completada"
echo "=========================================="
echo ""
echo "🌐 Accede a: https://dashboard.checkin24hs.com"
echo "🔄 Recarga la página con Ctrl+Shift+R para ver el Build #39"
