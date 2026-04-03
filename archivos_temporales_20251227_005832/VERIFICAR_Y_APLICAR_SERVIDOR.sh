#!/bin/bash
# Verificar y aplicar solución final en el servidor

cd /root/checkin24hs

echo "=== VERIFICACION Y APLICACION FINAL ==="
echo ""

# Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "ERROR: No se encuentra deploy/dashboard.html"
    exit 1
fi

# Verificar tamaño del archivo
FILE_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "Tamaño del archivo: $FILE_SIZE bytes"

# Verificar líneas alrededor de 5150
echo ""
echo "Líneas 5145-5155 en servidor:"
sed -n '5145,5155p' deploy/dashboard.html

# Verificar que no haya caracteres problemáticos
echo ""
echo "Buscando caracteres no ASCII alrededor de línea 5150:"
sed -n '5145,5155p' deploy/dashboard.html | od -c | head -5

echo ""
echo "Aplicando a TODOS los contenedores..."
echo ""

COUNT=0
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    COUNT=$((COUNT + 1))
    echo "[$COUNT] Procesando: $container"
    
    # Copiar archivo
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Verificar que se copió
        CONTAINER_SIZE=$(docker exec $container stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
        echo "  ✅ Copiado (tamaño: $CONTAINER_SIZE bytes)"
        
        # Verificar línea 5150 en contenedor
        LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        echo "  Línea 5150: ${LINE_5150:0:50}..."
        
        # Reiniciar
        docker restart $container >/dev/null 2>&1
        echo "  ✅ Reiniciado"
    else
        echo "  ❌ Error copiando"
    fi
    echo ""
done

echo "=== COMPLETADO ==="
echo "Total de contenedores procesados: $COUNT"
echo ""
echo "IMPORTANTE:"
echo "1. Abre en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica consola (F12) - NO debería haber errores en línea 5150"

