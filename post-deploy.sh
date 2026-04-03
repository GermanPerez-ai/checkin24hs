#!/bin/bash
# Script post-deploy para automatizar la configuración de cache busting
# Se ejecuta después de cada deploy para:
# 1. Actualizar BUILD_TIMESTAMP
# 2. Configurar Traefik (si es necesario)

echo "=== Ejecutando post-deploy para cache busting ==="

# Actualizar BUILD_TIMESTAMP
echo "📝 Actualizando BUILD_TIMESTAMP..."
node update-build-timestamp.js

if [ $? -eq 0 ]; then
    echo "✅ BUILD_TIMESTAMP actualizado correctamente"
else
    echo "❌ Error al actualizar BUILD_TIMESTAMP"
    exit 1
fi

# Opcional: Configurar Traefik (descomentar si es necesario)
# echo "🔧 Configurando Traefik..."
# bash configurar-traefik-anti-cache-auto.sh

echo "=== Post-deploy completado ==="
