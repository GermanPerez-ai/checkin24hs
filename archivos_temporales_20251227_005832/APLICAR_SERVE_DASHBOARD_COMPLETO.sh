#!/bin/bash

echo "=========================================="
echo "Aplicar serve-dashboard.js Completo"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar que el archivo existe
if [ ! -f "serve-dashboard.js" ]; then
    echo "❌ Error: serve-dashboard.js no existe"
    exit 1
fi

echo "✅ Archivo encontrado:"
ls -lh serve-dashboard.js
echo ""

# 2. Esperar a que haya un contenedor corriendo
echo "=== Esperando contenedor ==="
for i in {1..10}; do
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "✅ Contenedor encontrado: $CONTAINER_ID"
        break
    fi
    echo "Esperando contenedor... ($i/10)"
    sleep 3
done

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor después de 30 segundos"
    echo "Intentando reiniciar servicio..."
    docker service update --force checkin24hs_dashboard
    sleep 15
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar contenedor"
    exit 1
fi

echo ""

# 3. Copiar archivo al contenedor
echo "=== Copiando archivo al contenedor ==="
docker cp serve-dashboard.js $CONTAINER_ID:/app/serve-dashboard.js

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar archivo"
    exit 1
fi

echo "✅ Archivo copiado"
echo ""

# 4. Verificar que se copió
echo "=== Verificando archivo en contenedor ==="
docker exec $CONTAINER_ID ls -lh /app/serve-dashboard.js
echo ""

# 5. Reiniciar servicio
echo "=== Reiniciando servicio ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

# 6. Esperar a que se cree el nuevo contenedor
echo "Esperando 35 segundos para que se cree el nuevo contenedor..."
sleep 35

# 7. Buscar nuevo contenedor
echo ""
echo "=== Buscando nuevo contenedor ==="
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$NEW_CONTAINER_ID" ]; then
    echo "⚠️  No se encontró nuevo contenedor, intentando de nuevo..."
    sleep 10
    NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "✅ Nuevo contenedor: $NEW_CONTAINER_ID"
    echo ""
    
    # Copiar archivo al nuevo contenedor
    echo "=== Copiando archivo al nuevo contenedor ==="
    docker cp serve-dashboard.js $NEW_CONTAINER_ID:/app/serve-dashboard.js
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado al nuevo contenedor"
        echo ""
        
        # Verificar archivo
        echo "=== Verificando archivo ==="
        docker exec $NEW_CONTAINER_ID ls -lh /app/serve-dashboard.js
        echo ""
        
        # Verificar proceso
        echo "=== Verificando proceso ==="
        docker exec $NEW_CONTAINER_ID ps aux | grep node
        echo ""
        
        # Probar acceso
        echo "=== Probando acceso ==="
        docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
        echo ""
        
        # Ver logs
        echo "=== Ver logs (últimas 10 líneas) ==="
        docker logs $NEW_CONTAINER_ID --tail 10 2>&1
    else
        echo "❌ Error al copiar archivo al nuevo contenedor"
    fi
else
    echo "❌ No se pudo encontrar nuevo contenedor"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""




