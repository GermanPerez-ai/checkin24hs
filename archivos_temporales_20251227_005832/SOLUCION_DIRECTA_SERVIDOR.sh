#!/bin/bash
# SOLUCION DIRECTA EN EL SERVIDOR - Corregir línea 5150 directamente

cd /root/checkin24hs

echo "=== SOLUCION DIRECTA EN SERVIDOR ==="
echo ""

# Backup
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# Verificar línea 5150 actual
echo "Línea 5150 ANTES:"
sed -n '5150p' deploy/dashboard.html
echo ""

# ELIMINAR completamente la línea 5150 y reemplazar con código seguro
sed -i '5150d' deploy/dashboard.html

# Verificar después
echo "Línea 5150 DESPUES (ahora es la que estaba en 5151):"
sed -n '5149,5151p' deploy/dashboard.html
echo ""

echo "Aplicando a TODOS los contenedores..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "✅ $container actualizado"
done

echo ""
echo "=== COMPLETADO ==="
echo "Línea 5150 ELIMINADA. El archivo ahora tiene una línea menos."
echo ""
echo "VERIFICA: Abre https://dashboard.checkin24hs.com/ en modo incognito"

