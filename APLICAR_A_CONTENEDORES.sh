#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD.HTML A CONTENEDORES ==="
echo ""

# Buscar contenedores de dashboard
CONTAINERS=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard")
COUNT=$(echo "$CONTAINERS" | wc -l)

if [ -z "$CONTAINERS" ]; then
    echo "⚠️ No se encontraron contenedores de dashboard"
    exit 1
fi

echo "Contenedores encontrados: $COUNT"
echo ""

# Aplicar a cada contenedor
for container in $CONTAINERS; do
    echo "📦 Procesando: $container"
    
    # Detener contenedor
    docker stop $container 2>/dev/null
    
    # Copiar archivo (intentar ambas rutas)
    if docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null; then
        echo "  ✅ Archivo copiado a /app/dashboard.html"
    elif docker cp deploy/dashboard.html $container:/usr/share/nginx/html/dashboard.html 2>/dev/null; then
        echo "  ✅ Archivo copiado a /usr/share/nginx/html/dashboard.html"
    else
        echo "  ⚠️ No se pudo copiar, intentando otras rutas..."
        # Intentar otras rutas comunes
        docker cp deploy/dashboard.html $container:/app/ 2>/dev/null || \
        docker cp deploy/dashboard.html $container:/usr/share/nginx/html/ 2>/dev/null || \
        echo "  ❌ No se pudo copiar el archivo"
    fi
    
    # Reiniciar contenedor
    docker start $container 2>/dev/null
    echo "  ✅ Contenedor reiniciado"
    echo ""
done

echo "✅ PROCESO COMPLETADO"
echo ""
echo "Verifica que los contenedores estén corriendo:"
docker ps | grep checkin24hs_dashboard










