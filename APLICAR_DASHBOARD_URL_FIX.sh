#!/bin/bash

echo "🔄 Aplicando corrección de URL de WhatsApp en contenedores..."

# Detener contenedores
echo "⏸️ Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null || true
sleep 2

# Copiar archivo a todos los contenedores
echo "📋 Copiando dashboard.html a contenedores..."
for container in $(docker ps -a --format "{{.Names}}" | grep checkin24hs_dashboard); do
    echo "  → Copiando a $container..."
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null || echo "    ⚠️ No se pudo copiar a $container"
done

# Reiniciar contenedores
echo "▶️ Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null || true

echo "✅ Corrección aplicada. Espera unos segundos y recarga el dashboard con Ctrl+Shift+R (hard reload)."








