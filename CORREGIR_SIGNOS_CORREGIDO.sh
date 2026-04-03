#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Buscar signos '?' problemáticos ==="
echo "1. En console.log con '?':"
grep -n "console\." "$DASHBOARD_PATH" | grep -E "'\?|\"\?" | grep -v "http" | grep -v "query" | head -15
echo ""

echo "2. Signos '??' (doble):"
grep -n "\?\?" "$DASHBOARD_PATH" | head -15
echo ""

echo "=== Corregir problemas de codificación ==="
sed -i 's/Ã¡/á/g' "$DASHBOARD_PATH"
sed -i 's/Ã©/é/g' "$DASHBOARD_PATH"
sed -i 's/Ã­/í/g' "$DASHBOARD_PATH"
sed -i 's/Ã³/ó/g' "$DASHBOARD_PATH"
sed -i 's/Ãº/ú/g' "$DASHBOARD_PATH"
sed -i 's/Ã±/ñ/g' "$DASHBOARD_PATH"
sed -i 's/Ã/Á/g' "$DASHBOARD_PATH"
sed -i 's/Ã‰/É/g' "$DASHBOARD_PATH"
sed -i 's/Ã/Í/g' "$DASHBOARD_PATH"
sed -i 's/Ã"/Ó/g' "$DASHBOARD_PATH"
sed -i 's/Ãš/Ú/g' "$DASHBOARD_PATH"
sed -i 's/Ã'/Ñ/g' "$DASHBOARD_PATH"
echo "✅ Codificación corregida"
echo ""

echo "=== Corregir signos '?' en console.log ==="
# Escapar correctamente el signo ? en las expresiones regulares
sed -i "s/console\.log('\\?/console.log('🔍/g" "$DASHBOARD_PATH"
sed -i 's/console\.log("\\?/console.log("🔍/g' "$DASHBOARD_PATH"
sed -i "s/console\.warn('\\?/console.warn('⚠️/g" "$DASHBOARD_PATH"
sed -i 's/console\.warn("\\?/console.warn("⚠️/g' "$DASHBOARD_PATH"
sed -i "s/console\.error('\\?/console.error('❌/g" "$DASHBOARD_PATH"
sed -i 's/console\.error("\\?/console.error("❌/g' "$DASHBOARD_PATH"
sed -i "s/'\\?\\?/'🔍/g" "$DASHBOARD_PATH"
sed -i 's/"\\?\\?/"🔍/g' "$DASHBOARD_PATH"
sed -i 's/`\\?\\?/`🔍/g' "$DASHBOARD_PATH"
echo "✅ Signos '?' corregidos"
echo ""

echo "=== Verificar problemas restantes ==="
RESTANTES=$(grep -cE "console\..*'\\?|console\..*\"\\?|\\?\\?|Ã" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "console\..*'\\?|console\..*\"\\?|\\?\\?|Ã" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas"
fi
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor: $CONTAINER"
else
    echo "⚠️  Contenedor no encontrado"
fi
echo ""

echo "✅ Completado. Recarga con Ctrl+F5"
echo ""
