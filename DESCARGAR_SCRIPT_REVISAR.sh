#!/bin/bash
# Comando para descargar el script de revisión del dashboard desde GitHub

echo "📥 Descargando script REVISAR_Y_ACTUALIZAR_DASHBOARD.sh desde GitHub..."

curl -L -o REVISAR_Y_ACTUALIZAR_DASHBOARD.sh \
  https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/REVISAR_Y_ACTUALIZAR_DASHBOARD.sh

if [ $? -eq 0 ]; then
    chmod +x REVISAR_Y_ACTUALIZAR_DASHBOARD.sh
    echo "✅ Script descargado y hecho ejecutable"
    echo ""
    echo "📋 Ahora puedes ejecutar:"
    echo "   bash REVISAR_Y_ACTUALIZAR_DASHBOARD.sh"
else
    echo "❌ Error al descargar el script"
    echo ""
    echo "💡 Alternativa: El script no está en GitHub aún."
    echo "   Puedes crearlo manualmente o copiarlo desde tu máquina local."
fi
