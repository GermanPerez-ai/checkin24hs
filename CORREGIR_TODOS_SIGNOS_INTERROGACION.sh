#!/bin/bash
# Buscar y corregir TODOS los signos "?" problemáticos restantes

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔍 BUSCAR Y CORREGIR TODOS LOS SIGNOS '?'"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar TODOS los signos "?" problemáticos
echo "=== Buscar signos '?' problemáticos ==="
echo ""

# Buscar en console.log
echo "1. Signos '?' en console.log:"
grep -n "console\." "$DASHBOARD_PATH" | grep "'\?" | grep -v "http" | grep -v "query" | head -20
echo ""

# Buscar "??" (doble)
echo "2. Signos '??' (doble):"
grep -n "\?\?" "$DASHBOARD_PATH" | head -20
echo ""

# Buscar problemas de codificación restantes
echo "3. Problemas de codificación restantes:"
grep -n "Ã" "$DASHBOARD_PATH" | head -20
echo ""

# Corregir más problemas de codificación
echo "=== Corregir más problemas de codificación ==="
sed -i 's/Ã¡/á/g' "$DASHBOARD_PATH"
sed -i 's/Ã©/é/g' "$DASHBOARD_PATH"
sed -i 's/Ã­/í/g' "$DASHBOARD_PATH"
sed -i 's/Ã³/ó/g' "$DASHBOARD_PATH"
sed -i 's/Ãº/ú/g' "$DASHBOARD_PATH"
sed -i 's/Ã±/ñ/g' "$DASHBOARD_PATH"
sed -i 's/Ã'/Á/g' "$DASHBOARD_PATH"
sed -i 's/Ã‰/É/g' "$DASHBOARD_PATH"
sed -i 's/Ã/Í/g' "$DASHBOARD_PATH"
sed -i 's/Ã"/Ó/g' "$DASHBOARD_PATH"
sed -i 's/Ãš/Ú/g' "$DASHBOARD_PATH"
sed -i 's/Ã'/Ñ/g' "$DASHBOARD_PATH"
echo "✅ Más problemas de codificación corregidos"
echo ""

# Corregir signos "?" específicos en console.log
echo "=== Corregir signos '?' en console.log ==="

# Patrones comunes de signos "?" que deberían ser emojis o texto
sed -i "s/console\.log('?/console.log('🔍/g" "$DASHBOARD_PATH"
sed -i "s/console\.log(\"?/console.log(\"🔍/g" "$DASHBOARD_PATH"
sed -i "s/console\.warn('?/console.warn('⚠️/g" "$DASHBOARD_PATH"
sed -i "s/console\.warn(\"?/console.warn(\"⚠️/g" "$DASHBOARD_PATH"
sed -i "s/console\.error('?/console.error('❌/g" "$DASHBOARD_PATH"
sed -i "s/console\.error(\"?/console.error(\"❌/g" "$DASHBOARD_PATH"
sed -i "s/console\.info('?/console.info('ℹ️/g" "$DASHBOARD_PATH"
sed -i "s/console\.info(\"?/console.info(\"ℹ️/g" "$DASHBOARD_PATH"

# Corregir "??" específicos
sed -i "s/'??/'🔍/g" "$DASHBOARD_PATH"
sed -i 's/"??/"🔍/g' "$DASHBOARD_PATH"
sed -i 's/`??/`🔍/g' "$DASHBOARD_PATH"

echo "✅ Signos '?' en console.log corregidos"
echo ""

# Verificar si quedan problemas
echo "=== Verificar problemas restantes ==="
PROBLEMAS=$(grep -c "console\..*'\?\|console\..*\"\?\|??\|Ã" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$PROBLEMAS" -eq "0" ]; then
    echo "✅ No se encontraron más problemas"
else
    echo "⚠️  Aún hay $PROBLEMAS problemas"
    echo ""
    echo "Mostrando algunos:"
    grep -n "console\..*'\?\|console\..*\"\?\|??" "$DASHBOARD_PATH" | head -10
fi
echo ""

# Copiar al contenedor
echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado al contenedor: $CONTAINER"
    else
        echo "❌ Error al copiar"
    fi
else
    echo "⚠️  Contenedor no encontrado"
fi
echo ""

echo "=========================================="
echo "✅ Corrección completada"
echo "=========================================="
echo ""
echo "Recarga la página con Ctrl+F5"
echo ""
