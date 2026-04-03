#!/bin/bash
cd /root/checkin24hs

echo "=== FORZAR COPIA LIMPIA DEL DASHBOARD ==="
echo ""

# Verificar archivo
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encontró deploy/dashboard.html"
    exit 1
fi

LINES=$(wc -l < deploy/dashboard.html)
echo "📊 Líneas del archivo: $LINES"
echo ""

# Detener TODOS los contenedores
echo "🛑 Deteniendo TODOS los contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 5
echo "✅ Detenidos"
echo ""

# Verificar que están detenidos
RUNNING=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | wc -l)
if [ "$RUNNING" -gt 0 ]; then
    echo "⚠️ Forzando detención..."
    docker kill $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
    sleep 3
fi
echo ""

# Copiar a cada contenedor
echo "📋 Copiando archivo a contenedores..."
CONTAINERS=$(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard")
if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores"
    exit 1
fi

for c in $CONTAINERS; do
    echo "  Procesando: $c"
    
    # Intentar ambas rutas
    if docker cp deploy/dashboard.html "$c:/app/dashboard.html" 2>/dev/null; then
        # Verificar que se copió correctamente
        CONTAINER_LINES=$(docker exec $c wc -l /app/dashboard.html 2>/dev/null | awk '{print $1}' || echo "0")
        if [ "$CONTAINER_LINES" -gt 20000 ]; then
            echo "    ✅ Copiado a /app/dashboard.html ($CONTAINER_LINES líneas)"
        else
            echo "    ⚠️ Advertencia: Solo $CONTAINER_LINES líneas"
        fi
    elif docker cp deploy/dashboard.html "$c:/usr/share/nginx/html/dashboard.html" 2>/dev/null; then
        echo "    ✅ Copiado a /usr/share/nginx/html/dashboard.html"
    else
        echo "    ❌ Error al copiar a $c"
    fi
done
echo ""

# Reiniciar contenedores
echo "🚀 Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 5
echo "✅ Reiniciados"
echo ""

# Verificar estado
echo "=== ESTADO FINAL ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep checkin24hs_dashboard
echo ""

echo "✅ Proceso completado!"
echo ""
echo "Espera 15 segundos antes de probar el dashboard"
echo "Luego presiona Ctrl+F5 para refrescar sin caché"










