#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD.HTML (DETENIENDO CONTENEDORES PRIMERO) ==="
echo ""

# Obtener todos los contenedores
containers=$(docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

# Paso 1: Detener todos los contenedores
echo "=== PASO 1: DETENIENDO CONTENEDORES ==="
echo "$containers" | while read container; do
    if [ ! -z "$container" ]; then
        echo "Deteniendo $container..."
        docker stop $container > /dev/null 2>&1
    fi
done

echo "Esperando 3 segundos..."
sleep 3
echo ""

# Paso 2: Copiar archivo a todos los contenedores
echo "=== PASO 2: COPIANDO ARCHIVO ==="
echo "$containers" | while read container; do
    if [ ! -z "$container" ]; then
        echo "Copiando a $container..."
        docker cp deploy/dashboard.html $container:/app/dashboard.html
    fi
done

echo ""
echo "Esperando 2 segundos..."
sleep 2
echo ""

# Paso 3: Reiniciar todos los contenedores
echo "=== PASO 3: REINICIANDO CONTENEDORES ==="
echo "$containers" | while read container; do
    if [ ! -z "$container" ]; then
        echo "Reiniciando $container..."
        docker start $container > /dev/null 2>&1
    fi
done

echo ""
echo "Esperando 5 segundos..."
sleep 5
echo ""

# Paso 4: Verificación final
echo "=== PASO 4: VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    line_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$line_5150" | grep -q "editHotelName"; then
        echo "✅ $container: OK"
    else
        echo "❌ $container: ERROR"
    fi
done

echo ""
echo "=== PROCESO COMPLETADO ==="
