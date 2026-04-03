#!/bin/bash
# Script para actualizar automáticamente el BUILD_TIMESTAMP en dashboard.html
# Ejecutar antes de cada commit o deploy

DASHBOARD_FILE="dashboard.html"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ Error: No se encuentra $DASHBOARD_FILE"
    exit 1
fi

# Actualizar BUILD_TIMESTAMP
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/window.BUILD_TIMESTAMP = '[^']*'/window.BUILD_TIMESTAMP = '$TIMESTAMP'/" "$DASHBOARD_FILE"
else
    # Linux
    sed -i "s/window.BUILD_TIMESTAMP = '[^']*'/window.BUILD_TIMESTAMP = '$TIMESTAMP'/" "$DASHBOARD_FILE"
fi

echo "✅ BUILD_TIMESTAMP actualizado a: $TIMESTAMP"
echo "📝 Archivo: $DASHBOARD_FILE"
