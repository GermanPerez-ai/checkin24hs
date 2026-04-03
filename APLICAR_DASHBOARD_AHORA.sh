#!/bin/bash
# Aplicar dashboard.html a contenedores Docker

cd /root/checkin24hs

# Buscar contenedores
echo "Contenedores de dashboard encontrados:"
docker ps --filter "name=checkin24hs_dashboard" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo ""
echo "Si no hay contenedores listados, mostrando todos los contenedores:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo ""
echo "Copiando dashboard.html a contenedores..."
CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "No se encontraron contenedores con 'checkin24hs_dashboard'"
    echo "Por favor, indica el nombre del contenedor manualmente"
    exit 1
fi

for CONTAINER in $CONTAINERS; do
    echo "Copiando a: $CONTAINER"
    # Intentar diferentes rutas
    docker cp deploy/dashboard.html "$CONTAINER:/app/dashboard.html" 2>/dev/null && echo "  OK: /app/dashboard.html" || \
    docker cp deploy/dashboard.html "$CONTAINER:/usr/share/nginx/html/dashboard.html" 2>/dev/null && echo "  OK: /usr/share/nginx/html/dashboard.html" || \
    docker cp deploy/dashboard.html "$CONTAINER:/var/www/html/dashboard.html" 2>/dev/null && echo "  OK: /var/www/html/dashboard.html" || \
    echo "  ERROR: No se pudo copiar"
    
    echo "Reiniciando $CONTAINER..."
    docker restart "$CONTAINER"
    echo ""
done

echo "Espera 15 segundos y verifica en el navegador (limpiar cache: Ctrl+F5)"


