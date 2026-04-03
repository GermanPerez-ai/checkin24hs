#!/bin/bash
echo "=== ACTUALIZANDO DASHBOARD EN CONTENEDOR ==="
echo ""

if [ ! -f "deploy/dashboard.html" ]; then
    echo "Error: No se encuentra deploy/dashboard.html"
    exit 1
fi

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "Error: No se encontró contenedor activo"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

echo "Buscando dashboard.html..."
DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    for path in "/app/dashboard.html" "/usr/src/app/dashboard.html" "/root/checkin24hs/dashboard.html"; do
        if docker exec "$CONTAINER" test -f "$path" 2>/dev/null; then
            DASHBOARD_PATH="$path"
            break
        fi
    done
fi

if [ -z "$DASHBOARD_PATH" ]; then
    echo "Error: No se encontró dashboard.html en el contenedor"
    docker exec "$CONTAINER" ls -la / 2>/dev/null | head -20
    exit 1
fi

echo "Ruta encontrada: $DASHBOARD_PATH"
echo ""

echo "Copiando dashboard.html..."
docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "Archivo copiado exitosamente"
    
    echo ""
    echo "Verificando contenido..."
    docker exec "$CONTAINER" grep -q "Configurar WhatsApp" "$DASHBOARD_PATH" 2>/dev/null && \
        echo "Contiene botones de WhatsApp" || \
        echo "NO contiene botones de WhatsApp"
    
    echo ""
    echo "Reiniciando contenedor..."
    docker restart "$CONTAINER" 2>/dev/null || docker service update --force checkin24hs_dashboard
    
    echo ""
    echo "Esperando 20 segundos..."
    sleep 20
    
    echo ""
    echo "Verificando acceso:"
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -5
else
    echo "Error al copiar el archivo"
    exit 1
fi

echo ""
echo "=== COMPLETADO ==="
