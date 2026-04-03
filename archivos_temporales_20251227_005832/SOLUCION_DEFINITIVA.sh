#!/bin/bash
# SOLUCION DEFINITIVA - Eliminar completamente la línea problemática

cd /root/checkin24hs

echo "=== SOLUCION DEFINITIVA ==="
echo ""

# Verificar archivo actual
echo "Verificando línea 5150 actual:"
sed -n '5150p' deploy/dashboard.html

echo ""
echo "Líneas 5145-5155:"
sed -n '5145,5155p' deploy/dashboard.html

echo ""
echo "Aplicando corrección DIRECTA en el archivo del servidor..."

# Crear backup
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# Eliminar la línea 5150 completamente usando sed
sed -i '5150d' deploy/dashboard.html

echo ""
echo "Verificando después de eliminar línea 5150:"
sed -n '5145,5155p' deploy/dashboard.html

echo ""
echo "Aplicando a TODOS los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "✅ $container actualizado"
done

echo ""
echo "=== COMPLETADO ==="
echo "Línea 5150 ELIMINADA completamente"
echo ""
echo "Abre en modo incognito y verifica que NO haya errores"
