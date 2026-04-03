#!/bin/bash
# Corregir "Mes/A?o" por "Mes/Año" en Dashboard

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔧 CORREGIR 'Mes/A?o' EN DASHBOARD"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
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

# Corregir "A?o" por "Año" en todos los contextos
replacements = {
    'Mes/A?o': 'Mes/Año',
    'A?o': 'Año',
    'a?o': 'año',
    'A?OS': 'AÑOS',
    'a?os': 'años',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# También usar regex para casos más complejos
content = re.sub(r'A\?o', 'Año', content, flags=re.IGNORECASE)
content = re.sub(r'a\?o', 'año', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas: 'A?o' -> 'Año'")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo "✅ Corrección completada"
else
    echo "❌ Error en la corrección"
    exit 1
fi
echo ""

echo "=== Verificar correcciones ==="
RESTANTES=$(grep -cE "A\?o|a\?o|Mes/A\?o" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "A\?o|a\?o|Mes/A\?o" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas de 'A?o'"
fi
echo ""

echo "=== Verificar que se corrigió correctamente ==="
grep -n "Mes/Año" "$DASHBOARD_PATH" | head -5
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

echo "✅ Completado. Recarga la página con Ctrl+F5"
