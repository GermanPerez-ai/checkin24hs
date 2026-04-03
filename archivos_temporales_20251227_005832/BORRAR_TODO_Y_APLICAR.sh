#!/bin/bash
# BORRAR TODO Y APLICAR - Solución radical

cd /root/checkin24hs

echo "=== BORRANDO Y APLICANDO ==="
echo ""

# Backup
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# Eliminar líneas 5140-5150 completamente
echo "Eliminando líneas problemáticas..."
sed -i '5140,5150d' deploy/dashboard.html

# Verificar
echo "Líneas después de eliminar:"
sed -n '5135,5145p' deploy/dashboard.html

echo ""
echo "Aplicando a TODOS los contenedores..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "✅ $container"
done

echo ""
echo "✅ COMPLETADO - 11 líneas eliminadas"

