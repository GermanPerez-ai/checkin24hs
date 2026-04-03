#!/bin/bash
# Script para ejecutar la actualización del dashboard admin desde GitHub
# Ejecutar en el servidor

echo "🚀 Ejecutando actualización del dashboard admin..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh" ]; then
    echo "📥 Descargando script desde GitHub..."
    curl -o ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
    chmod +x ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
fi

# Ejecutar el script
./ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
