#!/bin/bash
# Script para actualizar dashboard en servidor con todas las correcciones

echo "🔄 Actualizando dashboard en servidor..."
echo ""

# 1. Descargar archivo actualizado desde GitHub
cd /etc/easypanel/projects/checkin24hs/dashboard/code
echo "📥 Descargando archivo desde GitHub..."
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado correctamente"
else
    echo "❌ Error al descargar archivo"
    exit 1
fi

# 2. Verificar que el archivo tiene el código correcto
echo ""
echo "🔍 Verificando código..."
if grep -q "MODO TEMPORAL" dashboard.html 2>/dev/null; then
    echo "⚠️  El archivo aún tiene código TEMPORAL (no debería)"
else
    echo "✅ Archivo sin código temporal (correcto)"
fi

if grep -q "DASHBOARD_BUILD_NUMBER = 39" dashboard.html 2>/dev/null; then
    echo "✅ Build number 39 encontrado"
else
    echo "⚠️  Build number puede no estar actualizado"
fi

# 3. Copiar al contenedor si es necesario
echo ""
echo "📋 Para aplicar cambios, reinicia el servicio dashboard desde EasyPanel"
echo "   O ejecuta: docker service update --force checkin24hs_dashboard"
echo ""
echo "🔧 Después del reinicio, no olvides restaurar las labels de Traefik:"
echo ""
echo "docker service update \\"
echo "  --label-add \"traefik.enable=true\" \\"
echo "  --label-add \"traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)\" \\"
echo "  --label-add \"traefik.http.routers.dashboard.entrypoints=websecure\" \\"
echo "  --label-add \"traefik.http.routers.dashboard.tls=true\" \\"
echo "  --label-add \"traefik.http.routers.dashboard.tls.certresolver=letsencrypt\" \\"
echo "  --label-add \"traefik.http.services.dashboard.loadbalancer.server.port=3000\" \\"
echo "  checkin24hs_dashboard"
