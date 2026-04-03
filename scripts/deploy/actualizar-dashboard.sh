#!/bin/bash
# Script para actualizar dashboard en servidor desde GitHub
# Uso: scripts/deploy/actualizar-dashboard.sh

ARCHIVO_MONTADO="/root/checkin24hs/dashboard.html"

echo "🔄 Actualizando dashboard desde GitHub..."
echo ""

# Descargar desde GitHub
curl -L -o "$ARCHIVO_MONTADO" https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -eq 0 ]; then
    # Verificar Build
    BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$ARCHIVO_MONTADO" | head -1)
    echo "✅ Archivo descargado (Build #$BUILD_NUM)"
else
    echo "❌ Error al descargar archivo"
    exit 1
fi

# Reiniciar servicio
echo ""
echo "🔄 Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar servicio"
    exit 1
fi

echo ""
echo "✅ Dashboard actualizado a Build #$BUILD_NUM"
echo ""
echo "📋 Próximos pasos:"
echo "1. Limpia caché del navegador"
echo "2. Recarga con Ctrl+Shift+R"
echo "3. Verifica: window.DASHBOARD_BUILD_NUMBER"
