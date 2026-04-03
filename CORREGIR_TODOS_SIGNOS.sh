#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Buscar signos '?' problemáticos ==="
echo "1. En console.log:"
grep -n "console\." "$DASHBOARD_PATH" | grep "'\?" | grep -v "http" | grep -v "query" | head -15
echo ""

echo "2. Signos '??':"
grep -n "\?\?" "$DASHBOARD_PATH" | head -15
echo ""

echo "=== Corregir problemas de codificación ==="
sed -i 's/Ã¡/á/g; s/Ã©/é/g; s/Ã­/í/g; s/Ã³/ó/g; s/Ãº/ú/g; s/Ã±/ñ/g' "$DASHBOARD_PATH"
sed -i 's/Ã/Á/g; s/Ã‰/É/g; s/Ã/Í/g; s/Ã"/Ó/g; s/Ãš/Ú/g; s/Ã'/Ñ/g' "$DASHBOARD_PATH"
echo "✅ Codificación corregida"
echo ""

echo "=== Corregir signos '?' en console.log ==="
sed -i "s/console\.log('?/console.log('🔍/g" "$DASHBOARD_PATH"
sed -i "s/console\.log(\"?/console.log(\"🔍/g" "$DASHBOARD_PATH"
sed -i "s/console\.warn('?/console.warn('⚠️/g" "$DASHBOARD_PATH"
sed -i "s/console\.error('?/console.error('❌/g" "$DASHBOARD_PATH"
sed -i "s/'??/'🔍/g; s/\"??/\"🔍/g; s/\`??/\`🔍/g" "$DASHBOARD_PATH"
echo "✅ Signos '?' corregidos"
echo ""

echo "=== Verificar problemas restantes ==="
RESTANTES=$(grep -c "console\..*'\?\|??\|Ã" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -n "console\..*'\?\|??\|Ã" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas"
fi
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor"
else
    echo "⚠️  Contenedor no encontrado"
fi
echo ""

echo "✅ Completado. Recarga con Ctrl+F5"
