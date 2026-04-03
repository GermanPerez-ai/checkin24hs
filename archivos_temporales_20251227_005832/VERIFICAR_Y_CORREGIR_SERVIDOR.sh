#!/bin/bash
# Verificar y corregir directamente en el servidor

cd /root/checkin24hs

echo "=== VERIFICACION Y CORRECCION ==="
echo ""

# Verificar línea 5150
echo "1. Línea 5150 actual:"
sed -n '5150p' deploy/dashboard.html | cat -A
echo ""

# Verificar funciones globales
echo "2. Funciones globales:"
SHOW_SECTION=$(grep -n "window.showSection = function" deploy/dashboard.html | head -1)
SEARCH_USERS=$(grep -n "window.searchUsers = function" deploy/dashboard.html | head -1)

if [ -z "$SHOW_SECTION" ]; then
    echo "❌ window.showSection NO encontrada"
else
    echo "✅ window.showSection: $SHOW_SECTION"
fi

if [ -z "$SEARCH_USERS" ]; then
    echo "❌ window.searchUsers NO encontrada"
else
    echo "✅ window.searchUsers: $SEARCH_USERS"
fi

echo ""

# Si las funciones no están en el head (líneas < 2000), necesitamos agregarlas
if [ -z "$SHOW_SECTION" ] || [ -z "$SEARCH_USERS" ]; then
    echo "⚠️  Las funciones globales NO están en el head"
    echo "Necesitas subir el archivo corregido desde tu máquina"
    exit 1
fi

# Verificar que estén ANTES de la línea 2000 (en el head)
SHOW_SECTION_LINE=$(echo "$SHOW_SECTION" | cut -d: -f1)
SEARCH_USERS_LINE=$(echo "$SEARCH_USERS" | cut -d: -f1)

if [ "$SHOW_SECTION_LINE" -gt 2000 ] || [ "$SEARCH_USERS_LINE" -gt 2000 ]; then
    echo "⚠️  Las funciones están DESPUÉS del HTML (línea > 2000)"
    echo "Necesitas subir el archivo corregido desde tu máquina"
    exit 1
fi

echo "✅ Funciones globales están en el head (líneas < 2000)"
echo ""

# Aplicar a todos los contenedores
echo "3. Aplicando a TODOS los contenedores..."
COUNT=0
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    COUNT=$((COUNT + 1))
    echo "[$COUNT] $container"
    
    # Copiar archivo
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Verificar que se copió
        CONTAINER_LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        echo "  Línea 5150 en contenedor: ${CONTAINER_LINE_5150:0:50}..."
        
        # Reiniciar
        docker restart $container >/dev/null 2>&1
        echo "  ✅ Actualizado y reiniciado"
    else
        echo "  ❌ Error copiando"
    fi
done

echo ""
echo "=== COMPLETADO ==="
echo "Contenedores actualizados: $COUNT"
echo ""
echo "VERIFICA en modo incognito (Ctrl+Shift+N) y presiona Ctrl+Shift+R"
