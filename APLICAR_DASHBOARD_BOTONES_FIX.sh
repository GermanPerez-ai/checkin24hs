#!/bin/bash
# Script para aplicar el dashboard.html corregido a todos los contenedores

cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD CORREGIDO A TODOS LOS CONTENEDORES ==="
echo ""

# Detener todos los contenedores del dashboard
echo "1. Deteniendo contenedores..."
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    echo "   Deteniendo $container..."
    docker stop $container >/dev/null 2>&1
done
sleep 3

# Copiar el archivo corregido a todos los contenedores
echo ""
echo "2. Copiando dashboard.html corregido..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    echo "   Copiando a $container..."
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "   ✅ $container actualizado"
    else
        echo "   ⚠️ Error copiando a $container (puede estar detenido)"
    fi
done

# Iniciar todos los contenedores
echo ""
echo "3. Iniciando contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    echo "   Iniciando $container..."
    docker start $container >/dev/null 2>&1
done
sleep 3

# Verificación final
echo ""
echo "=== VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    fecha=$(docker exec $container ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    size=$(docker exec $container ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
    if [ ! -z "$fecha" ]; then
        echo "✅ $container: $fecha ($size)"
    else
        echo "❌ $container: Error verificando archivo"
    fi
done

echo ""
echo "✅ Proceso completado"
echo ""
echo "Ahora recarga el dashboard en el navegador (Ctrl+F5) y prueba los botones."
