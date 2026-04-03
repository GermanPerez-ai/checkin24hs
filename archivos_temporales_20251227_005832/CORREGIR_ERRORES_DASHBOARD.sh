#!/bin/bash

# Script para corregir errores en dashboard.html en el servidor
# 1. Eliminar emojis de console.log
# 2. Verificar que showSection esté correctamente definida

echo "=========================================="
echo "Corrigiendo errores en dashboard.html"
echo "=========================================="
echo ""

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "Backup creado: $BACKUP_FILE"
echo ""

# 1. Eliminar emojis de console.log usando sed
echo "1. Eliminando emojis de console.log..."
sed -i 's/🎫//g' "$DASHBOARD_PATH"
sed -i 's/🤖//g' "$DASHBOARD_PATH"
sed -i 's/✅//g' "$DASHBOARD_PATH"
sed -i 's/💾//g' "$DASHBOARD_PATH"
sed -i 's/🔄//g' "$DASHBOARD_PATH"
sed -i 's/📊//g' "$DASHBOARD_PATH"
sed -i 's/☁️//g' "$DASHBOARD_PATH"
sed -i 's/⚠️//g' "$DASHBOARD_PATH"
sed -i 's/❌//g' "$DASHBOARD_PATH"
sed -i 's/🔐//g' "$DASHBOARD_PATH"
sed -i 's/📁//g' "$DASHBOARD_PATH"
sed -i 's/✏️//g' "$DASHBOARD_PATH"
sed -i 's/🗑️//g' "$DASHBOARD_PATH"
sed -i 's/🖼️//g' "$DASHBOARD_PATH"
sed -i 's/👁️//g' "$DASHBOARD_PATH"
sed -i 's/⚙️//g' "$DASHBOARD_PATH"
sed -i 's/⏭️//g' "$DASHBOARD_PATH"
sed -i 's/ℹ️//g' "$DASHBOARD_PATH"
echo "Emojis eliminados"
echo ""

# 2. Verificar que showSection esté definida en el head
echo "2. Verificando definicion de showSection..."
if grep -q "window.showSection = function" "$DASHBOARD_PATH"; then
    echo "showSection encontrada en el archivo"
    # Verificar que esté en el head (primeras 50 líneas)
    if head -50 "$DASHBOARD_PATH" | grep -q "window.showSection = function"; then
        echo "showSection esta en el head - OK"
    else
        echo "ADVERTENCIA: showSection no esta en el head"
    fi
else
    echo "ERROR: showSection NO encontrada"
fi
echo ""

# 3. Buscar posibles errores de sintaxis alrededor de la línea 5150
echo "3. Verificando linea 5150..."
if [ -f "$DASHBOARD_PATH" ]; then
    TOTAL_LINES=$(wc -l < "$DASHBOARD_PATH")
    echo "Total de lineas en el archivo: $TOTAL_LINES"
    if [ "$TOTAL_LINES" -ge 5150 ]; then
        echo "Líneas alrededor de 5150:"
        sed -n '5145,5155p' "$DASHBOARD_PATH" | cat -n
    else
        echo "El archivo tiene menos de 5150 lineas"
    fi
fi
echo ""

echo "=========================================="
echo "Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Ahora copia el archivo al contenedor:"
echo "  CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp $DASHBOARD_PATH \${CONTAINER_ID}:/app/dashboard.html"
echo "  docker service update --force checkin24hs_dashboard"


