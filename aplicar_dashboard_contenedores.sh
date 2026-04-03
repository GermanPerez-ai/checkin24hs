#!/bin/bash
# Script para aplicar dashboard.html a los contenedores Docker

echo "=========================================="
echo "Aplicando dashboard.html a contenedores Docker"
echo "=========================================="
echo ""

# Verificar que el archivo existe
FILE="/root/checkin24hs/deploy/dashboard.html"
if [ ! -f "$FILE" ]; then
    echo "ERROR: No se encuentra el archivo: $FILE"
    exit 1
fi

echo "Archivo local encontrado: $FILE"
echo "Tamaño: $(ls -lh "$FILE" | awk '{print $5}')"
echo ""

# Buscar contenedores de dashboard
echo "Buscando contenedores de dashboard..."
CONTAINERS=$(docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "No se encontraron contenedores con nombre 'checkin24hs_dashboard'"
    echo "Buscando contenedores que sirvan dashboard..."
    CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(dashboard|nginx|web)" || echo "")
fi

if [ -z "$CONTAINERS" ]; then
    echo "ERROR: No se encontraron contenedores"
    echo ""
    echo "Contenedores disponibles:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Procesar cada contenedor
for CONTAINER in $CONTAINERS; do
    echo "Procesando contenedor: $CONTAINER"
    
    # Intentar diferentes rutas comunes
    PATHS=(
        "/app/dashboard.html"
        "/usr/share/nginx/html/dashboard.html"
        "/var/www/html/dashboard.html"
        "/usr/local/apache2/htdocs/dashboard.html"
    )
    
    COPIED=false
    for TARGET_PATH in "${PATHS[@]}"; do
        if docker cp "$FILE" "$CONTAINER:$TARGET_PATH" 2>/dev/null; then
            echo "  ✓ Copiado a: $TARGET_PATH"
            COPIED=true
            break
        fi
    done
    
    if [ "$COPIED" = false ]; then
        echo "  ⚠ No se pudo copiar a ninguna ruta estándar"
        echo "  Intentando encontrar la ruta del archivo en el contenedor..."
        docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | head -5
    fi
    
    # Reiniciar el contenedor
    echo "  Reiniciando contenedor..."
    docker restart "$CONTAINER" >/dev/null 2>&1
    echo "  ✓ Contenedor reiniciado"
    echo ""
done

echo "=========================================="
echo "Proceso completado"
echo "=========================================="
echo ""
echo "Espera 10-15 segundos y luego verifica el dashboard en el navegador."
echo "Si aún no ves los cambios, limpia la caché del navegador (Ctrl+F5)"


