#!/bin/bash

echo "🔄 Aplicando corrección de buildServerURL en contenedores..."

# Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra /root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# Verificar que buildServerURL está en el archivo
if ! grep -q "window.buildServerURL" /root/checkin24hs/deploy/dashboard.html; then
    echo "⚠️ Advertencia: window.buildServerURL no encontrado en el archivo"
    echo "   Asegúrate de haber subido el archivo corregido primero"
fi

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

echo ""
echo "✅ Corrección aplicada."
echo ""
echo "📝 Próximos pasos:"
echo "1. Espera 10-15 segundos para que los contenedores se reinicien"
echo "2. Recarga el dashboard con Ctrl+Shift+R (hard reload)"
echo "3. Verifica en la consola que buildServerURL esté disponible:"
echo "   console.log('buildServerURL:', typeof buildServerURL === 'function');"








