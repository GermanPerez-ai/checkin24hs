#!/bin/bash

echo "=========================================="
echo "Solución Rápida: Copiar serve-dashboard.js"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Verificar que serve-dashboard.js existe localmente
if [ ! -f "serve-dashboard.js" ]; then
    echo "❌ Error: serve-dashboard.js no existe en /root/checkin24hs"
    echo "Necesitas subirlo primero con: scp serve-dashboard.js root@72.61.58.240:/root/checkin24hs/"
    exit 1
fi

echo "✅ serve-dashboard.js encontrado"
echo ""

# Obtener contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor corriendo"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Copiar archivo al contenedor
echo "=== Copiando serve-dashboard.js al contenedor ==="
docker cp serve-dashboard.js $CONTAINER_ID:/app/serve-dashboard.js

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
    echo ""
    
    # Verificar que se copió
    echo "Verificando archivo:"
    docker exec $CONTAINER_ID ls -lh /app/serve-dashboard.js
    echo ""
    
    # Reiniciar el servicio para que use el nuevo archivo
    echo "=== Reiniciando servicio ==="
    docker service update --force checkin24hs_dashboard
    echo "✅ Servicio reiniciado"
    echo ""
    
    echo "Esperando 30 segundos..."
    sleep 30
    
    # Verificar nuevo contenedor
    NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
    if [ ! -z "$NEW_CONTAINER_ID" ]; then
        echo "Nuevo contenedor: $NEW_CONTAINER_ID"
        echo ""
        
        # Copiar archivo al nuevo contenedor también
        echo "Copiando archivo al nuevo contenedor..."
        docker cp serve-dashboard.js $NEW_CONTAINER_ID:/app/serve-dashboard.js
        echo "✅ Archivo copiado"
        echo ""
        
        # Verificar proceso
        echo "Verificando proceso:"
        docker exec $NEW_CONTAINER_ID ps aux | grep node
        echo ""
        
        # Probar acceso
        echo "Probando acceso:"
        docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
    fi
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "NOTA: Esta es una solución temporal."
echo "Para una solución permanente, necesitas:"
echo "1. Hacer commit y push de serve-dashboard.js a GitHub"
echo "2. Hacer redeploy en EasyPanel para reconstruir la imagen"
echo ""




