#!/bin/bash
# Verificar que dashboard.html está en los contenedores

cd /root/checkin24hs

echo "=========================================="
echo "Verificando dashboard.html en contenedores"
echo "=========================================="
echo ""

# Obtener contenedores activos
CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "No se encontraron contenedores activos"
    exit 1
fi

for CONTAINER in $CONTAINERS; do
    echo "Contenedor: $CONTAINER"
    
    # Buscar el archivo dashboard.html en el contenedor
    echo "  Buscando dashboard.html..."
    DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | head -1)
    
    if [ -n "$DASHBOARD_PATH" ]; then
        echo "  ✓ Encontrado en: $DASHBOARD_PATH"
        
        # Verificar tags HTML
        HTML_COUNT=$(docker exec "$CONTAINER" grep -c '<html' "$DASHBOARD_PATH" 2>/dev/null || echo "0")
        WHATSAPP_COUNT=$(docker exec "$CONTAINER" grep -c 'whatsapp-server-url' "$DASHBOARD_PATH" 2>/dev/null || echo "0")
        KNOWLEDGE_COUNT=$(docker exec "$CONTAINER" grep -c 'knowledge-hotel-selector' "$DASHBOARD_PATH" 2>/dev/null || echo "0")
        
        echo "  - Tags <html>: $HTML_COUNT"
        echo "  - whatsapp-server-url: $WHATSAPP_COUNT"
        echo "  - knowledge-hotel-selector: $KNOWLEDGE_COUNT"
        
        if [ "$HTML_COUNT" -eq 1 ] && [ "$WHATSAPP_COUNT" -gt 0 ]; then
            echo "  ✓ Archivo CORRECTO"
        else
            echo "  ⚠ Archivo puede estar corrupto o incompleto"
        fi
    else
        echo "  ✗ No se encontró dashboard.html en el contenedor"
        
        # Intentar copiar a las rutas comunes
        echo "  Intentando copiar..."
        docker cp deploy/dashboard.html "$CONTAINER:/app/dashboard.html" 2>/dev/null && echo "    ✓ Copiado a /app/dashboard.html" || \
        docker cp deploy/dashboard.html "$CONTAINER:/usr/share/nginx/html/dashboard.html" 2>/dev/null && echo "    ✓ Copiado a /usr/share/nginx/html/dashboard.html" || \
        docker cp deploy/dashboard.html "$CONTAINER:/var/www/html/dashboard.html" 2>/dev/null && echo "    ✓ Copiado a /var/www/html/dashboard.html" || \
        echo "    ✗ No se pudo copiar a ninguna ruta estándar"
    fi
    
    echo ""
done

echo "=========================================="
echo "Verificación completada"
echo "=========================================="
echo ""
echo "Si todos los archivos están correctos, espera 15 segundos y recarga el dashboard en el navegador."
echo "IMPORTANTE: Presiona Ctrl+F5 para limpiar la caché del navegador."
