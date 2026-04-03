#!/bin/bash
# Script para aplicar whatsapp-server.js corregido a todos los contenedores

cd /root/checkin24hs

echo "=== APLICANDO WHATSAPP-SERVER.JS CORREGIDO ==="
echo ""

# Verificar que el archivo existe
if [ ! -f "whatsapp-server/whatsapp-server.js" ]; then
    echo "❌ ERROR: No se encuentra whatsapp-server/whatsapp-server.js"
    exit 1
fi

echo "✅ Archivo encontrado"
echo ""

# Copiar a todos los contenedores whatsapp
echo "📦 Copiando archivo a contenedores..."
docker ps --filter "name=whatsapp" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        docker cp whatsapp-server/whatsapp-server.js $container:/app/whatsapp-server.js
        echo "✅ Copiado a $container"
    fi
done

echo ""
echo "🔄 Reiniciando contenedores..."
docker ps --filter "name=whatsapp" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        docker restart $container
        echo "✅ Reiniciado $container"
    fi
done

echo ""
echo "✅✅✅ PROCESO COMPLETADO ✅✅✅"
echo ""
echo "Espera unos segundos y revisa los logs con:"
echo "docker logs -f <nombre_del_contenedor>"








