#!/bin/bash
# Script para forzar actualización del servidor a Build #39

echo "🔄 Actualizando servidor a Build #39..."
echo ""

# 1. Ir al directorio
cd /etc/easypanel/projects/checkin24hs/dashboard/code

# 2. Descargar archivo
echo "📥 Descargando dashboard.html desde GitHub..."
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado"
else
    echo "❌ Error al descargar"
    exit 1
fi

# 3. Verificar Build Number
echo ""
echo "🔍 Verificando Build Number..."
BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
echo "Build Number encontrado: $BUILD_NUM"

if [ "$BUILD_NUM" != "39" ]; then
    echo "⚠️  El build no es 39, puede haber un problema"
else
    echo "✅ Build #39 confirmado"
fi

# 4. Reiniciar servicio
echo ""
echo "🔄 Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar servicio"
    exit 1
fi

# 5. Esperar
echo ""
echo "⏳ Esperando 10 segundos..."
sleep 10

# 6. Restaurar Traefik
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

echo ""
echo "=========================================="
echo "✅ Actualización completada"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Limpia caché del navegador: Ctrl+Shift+Delete"
echo "2. Recarga forzada: Ctrl+Shift+R"
echo "3. Verifica Build: window.DASHBOARD_BUILD_NUMBER (debe ser 39)"
echo "4. Debería pedir login"
