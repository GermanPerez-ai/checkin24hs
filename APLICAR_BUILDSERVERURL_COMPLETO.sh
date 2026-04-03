#!/bin/bash

echo "🔄 Aplicando corrección de buildServerURL..."
echo ""

# Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra /root/checkin24hs/deploy/dashboard.html"
    echo "   Asegúrate de haber subido el archivo primero con:"
    echo "   scp deploy\\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# Verificar que buildServerURL está en el archivo
if ! grep -q "window.buildServerURL" /root/checkin24hs/deploy/dashboard.html; then
    echo "⚠️ Advertencia: window.buildServerURL no encontrado en el archivo"
    echo "   El archivo puede no tener la corrección aplicada"
    echo "   Continuando de todas formas..."
fi

echo "✅ Archivo encontrado"
echo ""

# Obtener lista de contenedores activos
echo "=== Obteniendo lista de contenedores ==="
CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}")
if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores activos"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Detener contenedores
echo "⏸️ Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null || true
sleep 2

# Copiar archivo a todos los contenedores
echo "📋 Copiando dashboard.html a contenedores..."
for container in $CONTAINERS; do
    echo "  → Copiando a $container..."
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "    ✅ Copiado correctamente"
    else
        echo "    ⚠️ No se pudo copiar (puede que el contenedor esté detenido)"
    fi
done

# También copiar a contenedores detenidos
echo ""
echo "📋 Copiando a contenedores detenidos..."
for container in $(docker ps -a --format "{{.Names}}" | grep checkin24hs_dashboard); do
    if ! echo "$CONTAINERS" | grep -q "$container"; then
        echo "  → Copiando a $container (detenido)..."
        docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "    ✅ Copiado correctamente"
        fi
    fi
done

# Reiniciar contenedores
echo ""
echo "▶️ Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null || true

echo ""
echo "✅ Corrección aplicada"
echo ""
echo "📝 Próximos pasos:"
echo "1. Espera 10-15 segundos para que los contenedores se reinicien"
echo "2. Recarga el dashboard con Ctrl+Shift+R (hard reload)"
echo "3. Verifica en la consola que buildServerURL esté disponible:"
echo "   console.log('buildServerURL:', typeof buildServerURL === 'function');"
echo ""
echo "   Deberías ver: buildServerURL: true"








