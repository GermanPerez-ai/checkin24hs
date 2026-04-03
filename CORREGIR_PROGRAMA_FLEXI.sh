#!/bin/bash
# Corregir signos "?" en sección Programa Flexi

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔧 CORREGIR SIGNOS '?' EN PROGRAMA FLEXI"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
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
    
    # Estadía
    'Estad?a': 'Estadía',
    'estad?a': 'estadía',
    
    # Paso 3: Confirmación (completo)
    'Paso 3: Confirmaci?n': 'Paso 3: Confirmación',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# También usar regex para casos más complejos
content = re.sub(r'C\?mo', 'Cómo', content, flags=re.IGNORECASE)
content = re.sub(r'c\?mo', 'cómo', content)
content = re.sub(r'Confirmaci\?n', 'Confirmación', content, flags=re.IGNORECASE)
content = re.sub(r'Estad\?a', 'Estadía', content, flags=re.IGNORECASE)

# Corregir "?Cómo" al inicio de oraciones
content = re.sub(r'\?C\?mo', '¿Cómo', content)
content = re.sub(r'\?Cómo', '¿Cómo', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas en Programa Flexi")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo "✅ Corrección completada"
else
    echo "❌ Error en la corrección"
    exit 1
fi
echo ""

echo "=== Verificar correcciones ==="
RESTANTES=$(grep -cE "C\?mo|Confirmaci\?n|Estad\?a|\?C\?mo" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "C\?mo|Confirmaci\?n|Estad\?a|\?C\?mo" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas en Programa Flexi"
fi
echo ""

echo "=== Verificar que se corrigió correctamente ==="
grep -n "¿Cómo\|Confirmación\|Estadía\|Paso 3: Confirmación" "$DASHBOARD_PATH" | head -5
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
