#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Crear backup ==="
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

echo "=== Corregir con Python ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Corregir codificación UTF-8
replacements = {
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú', 'Ã': 'Ñ',
    'est?n': 'están', 'v?lido': 'válido', 'b?sico': 'básico', 'cach?': 'caché'
}

for old, new in replacements.items():
    content = content.replace(old, new)

# Corregir signos "?" en console.log
content = re.sub(r"console\.log\('\\?", "console.log('🔍", content)
content = re.sub(r'console\.log\("\\?', 'console.log("🔍', content)
content = re.sub(r"console\.warn\('\\?", "console.warn('⚠️", content)
content = re.sub(r'console\.warn\("\\?', 'console.warn("⚠️', content)
content = re.sub(r"console\.error\('\\?", "console.error('❌", content)
content = re.sub(r'console\.error\("\\?', 'console.error("❌', content)

# Corregir "??"
content = re.sub(r"'\\?\\?", "'🔍", content)
content = re.sub(r'"\\?\\?', '"🔍', content)
content = re.sub(r'`\\?\\?', '`🔍', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas")
PYTHON_EOF

echo "✅ Corrección completada"
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado al contenedor"
fi
echo ""

echo "✅ Completado. Recarga con Ctrl+F5"
