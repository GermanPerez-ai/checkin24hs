#!/bin/bash
# Script para encontrar la ruta correcta dentro de los contenedores

echo "🔍 Buscando rutas dentro de los contenedores..."
echo ""

FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontraron contenedores de dashboard"
    exit 1
fi

echo "📦 Analizando contenedor: $FIRST_CONTAINER"
echo ""

# Buscar archivos dashboard.html existentes
echo "🔍 Buscando archivos dashboard.html existentes..."
docker exec $FIRST_CONTAINER find / -name "dashboard.html" 2>/dev/null | head -5

echo ""
echo "🔍 Verificando rutas comunes..."
echo ""

# Verificar rutas comunes
PATHS=(
    "/usr/share/nginx/html"
    "/app"
    "/var/www/html"
    "/usr/share/nginx"
    "/opt/app"
)

for path in "${PATHS[@]}"; do
    echo "Verificando $path..."
    if docker exec $FIRST_CONTAINER test -d "$path" 2>/dev/null; then
        echo "   ✅ Existe: $path"
        docker exec $FIRST_CONTAINER ls -la "$path" 2>/dev/null | head -5
    else
        echo "   ❌ No existe: $path"
    fi
    echo ""
done

echo "💡 Usa la ruta que existe para copiar el archivo"




