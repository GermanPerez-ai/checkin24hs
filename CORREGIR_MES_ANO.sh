#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Buscar 'Mes/A?o' ==="
grep -n "Mes/A\?o\|A\?o" "$DASHBOARD_PATH" | head -15
echo ""

echo "=== Corregir con Python ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Corregir "A?o" por "Año"
replacements = {
    'Mes/A?o': 'Mes/Año',
    'A?o': 'Año',
    'a?o': 'año',
    'A?OS': 'AÑOS',
    'a?os': 'años',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# También usar regex
content = re.sub(r'A\?o', 'Año', content, flags=re.IGNORECASE)
content = re.sub(r'a\?o', 'año', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas: 'A?o' -> 'Año'")
PYTHON_EOF

echo "✅ Corrección completada"
echo ""

echo "=== Verificar ==="
RESTANTES=$(grep -cE "A\?o|a\?o|Mes/A\?o" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "A\?o|a\?o|Mes/A\?o" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas"
fi
echo ""

echo "=== Verificar corrección ==="
grep -n "Mes/Año" "$DASHBOARD_PATH" | head -5
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor"
fi
echo ""

echo "✅ Completado. Recarga con Ctrl+F5"
