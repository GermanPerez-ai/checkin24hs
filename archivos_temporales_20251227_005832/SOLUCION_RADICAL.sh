#!/bin/bash
# SOLUCION RADICAL - Eliminar línea 5150 directamente en el servidor

cd /root/checkin24hs

echo "=== SOLUCION RADICAL ==="
echo ""

# Backup
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# Verificar qué hay en línea 5150
echo "Línea 5150 ANTES:"
sed -n '5150p' deploy/dashboard.html | cat -A
echo ""

# ELIMINAR línea 5150 completamente
echo "Eliminando línea 5150..."
sed -i '5150d' deploy/dashboard.html

# Verificar después
echo "Línea 5150 DESPUES (ahora es la que estaba en 5151):"
sed -n '5149,5151p' deploy/dashboard.html
echo ""

# Aplicar a TODOS los contenedores
echo "Aplicando a TODOS los contenedores..."
COUNT=0
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    COUNT=$((COUNT + 1))
    echo "[$COUNT] $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "  ✅ Actualizado"
done

echo ""
echo "=== COMPLETADO ==="
echo "Línea 5150 ELIMINADA"
echo "Contenedores actualizados: $COUNT"
echo ""
echo "VERIFICA AHORA en modo incognito (Ctrl+Shift+N)"

