#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"

echo "=== Restaurar del backup ==="
BACKUP=$(ls -t /root/checkin24hs/dashboard.html.backup_* 2>/dev/null | head -1)
if [ -n "$BACKUP" ]; then
    cp "$BACKUP" "$DASHBOARD_PATH"
    echo "✅ Restaurado desde: $BACKUP"
else
    echo "⚠️  No se encontró backup"
fi
echo ""

echo "=== Corregir SOLO en console.log (NO en URLs) ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Solo corregir codificación UTF-8
replacements = {
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'est?n': 'están', 'v?lido': 'válido', 'b?sico': 'básico', 'cach?': 'caché'
}

for old, new in replacements.items():
    content = content.replace(old, new)

# Corregir signos "?" SOLO en console.log/warn/error, con contexto específico
# Solo si está al inicio de una cadena de texto, NO en URLs
content = re.sub(r"console\.log\('\\?\s+([^']+)", r"console.log('🔍 \1", content)
content = re.sub(r'console\.log\("\\?\s+([^"]+)', r'console.log("🔍 \1', content)
content = re.sub(r"console\.warn\('\\?\s+([^']+)", r"console.warn('⚠️ \1", content)
content = re.sub(r'console\.warn\("\\?\s+([^"]+)', r'console.warn("⚠️ \1', content)
content = re.sub(r"console\.error\('\\?\s+([^']+)", r"console.error('❌ \1", content)
content = re.sub(r'console\.error\("\\?\s+([^"]+)', r'console.error("❌ \1', content)

# Corregir "??" SOLO en console.log
content = re.sub(r"console\.log\('\\?\\?\s+", "console.log('🔍 ", content)
content = re.sub(r'console\.log\("\\?\\?\s+', 'console.log("🔍 ', content)
content = re.sub(r"console\.warn\('\\?\\?\s+", "console.warn('⚠️ ", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas (solo console.log)")
PYTHON_EOF

echo "✅ Completado"
echo ""

echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    echo "✅ Copiado"
fi
echo ""

echo "Recarga con Ctrl+F5"
