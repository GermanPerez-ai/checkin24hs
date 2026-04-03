#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Buscar signos '?' en Programa Flexi ==="
grep -n "C\?mo\|Confirmaci\?n\|Estad\?a\|Paso 3" "$DASHBOARD_PATH" | head -15
echo ""

echo "=== Corregir con Python ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Corregir problemas específicos de Programa Flexi
replacements = {
    # Cómo
    '?Cómo': '¿Cómo',
    'C?mo': 'Cómo',
    'c?mo': 'cómo',
    
    # Confirmación
    'Confirmaci?n': 'Confirmación',
    'confirmaci?n': 'confirmación',
    'Paso 3: Confirmaci?n': 'Paso 3: Confirmación',
    
    # Estadía
    'Estad?a': 'Estadía',
    'estad?a': 'estadía',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# También usar regex
content = re.sub(r'C\?mo', 'Cómo', content, flags=re.IGNORECASE)
content = re.sub(r'c\?mo', 'cómo', content)
content = re.sub(r'Confirmaci\?n', 'Confirmación', content, flags=re.IGNORECASE)
content = re.sub(r'Estad\?a', 'Estadía', content, flags=re.IGNORECASE)

# Corregir "?Cómo" al inicio
content = re.sub(r'\?C\?mo', '¿Cómo', content)
content = re.sub(r'\?Cómo', '¿Cómo', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas")
PYTHON_EOF

echo "✅ Corrección completada"
echo ""

echo "=== Verificar ==="
RESTANTES=$(grep -cE "C\?mo|Confirmaci\?n|Estad\?a|\?C\?mo" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "C\?mo|Confirmaci\?n|Estad\?a|\?C\?mo" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas"
fi
echo ""

echo "=== Verificar corrección ==="
grep -n "¿Cómo\|Confirmación\|Estadía\|Paso 3: Confirmación" "$DASHBOARD_PATH" | head -5
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor"
fi
echo ""

echo "✅ Completado. Recarga con Ctrl+F5"
