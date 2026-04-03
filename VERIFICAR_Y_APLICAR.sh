#!/bin/bash

echo "🔍 Verificando y aplicando corrección de buildServerURL..."
echo ""

cd /root/checkin24hs

# Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    echo "   Necesitas subir el archivo primero desde PowerShell:"
    echo "   scp deploy\\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# Verificar que tiene la corrección
if grep -q "window.buildServerURL" deploy/dashboard.html; then
    echo "✅ Archivo verificado: contiene window.buildServerURL"
else
    echo "❌ Error: El archivo NO contiene window.buildServerURL"
    echo "   Necesitas subir el archivo corregido primero"
    exit 1
fi

echo ""

# Obtener contenedores
CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep checkin24hs_dashboard)
if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores de dashboard"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Detener contenedores
echo "⏸️ Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null || true
sleep 2

# Copiar archivo
echo "📋 Copiando archivo a contenedores..."
for container in $CONTAINERS; do
    echo "  → $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "    ✅ Copiado"
    else
        echo "    ⚠️ Error al copiar"
    fi
done

# Reiniciar contenedores
echo ""
echo "▶️ Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null || true

echo ""
echo "✅ Proceso completado"
echo ""
echo "📝 Próximos pasos:"
echo "1. Espera 10-15 segundos"
echo "2. Recarga el dashboard con Ctrl+Shift+R (hard reload)"
echo "3. Verifica en la consola: console.log('buildServerURL:', typeof buildServerURL === 'function');"








