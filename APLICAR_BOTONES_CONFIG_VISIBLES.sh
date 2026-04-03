#!/bin/bash

echo "🔧 Aplicando corrección de botones de configuración visibles..."

# Detener contenedores del dashboard
echo "⏹️ Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null || true
sleep 3

# Copiar dashboard.html a todos los contenedores
echo "📋 Copiando dashboard.html a contenedores..."
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null && echo "✅ $c" || echo "⚠️ $c (no se pudo copiar)"
done

# Iniciar contenedores
echo "▶️ Iniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null || true

echo "✅ Corrección aplicada. Los botones de configuración ahora son siempre visibles."
echo ""
echo "📝 Instrucciones:"
echo "1. Recarga la página del dashboard (Ctrl+F5 o Cmd+Shift+R)"
echo "2. Ve a la pestaña 'WhatsApp' en Flor IA"
echo "3. Deberías ver el botón '⚙️ Configurar Servidor' en la parte superior derecha"
echo "4. Si hay una URL configurada, también verás un botón 'Cambiar Configuración' en el indicador verde"








