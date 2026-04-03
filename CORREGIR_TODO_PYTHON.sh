#!/bin/bash
# Script completo para corregir todos los signos "?" y problemas de codificación

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

# Leer archivo
with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Corregir problemas de codificación UTF-8
replacements = {
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú', 'Ã': 'Ñ',
    # Palabras específicas con problemas
    'est?n': 'están',
    'v?lido': 'válido',
    'b?sico': 'básico',
    'cach?': 'caché',
    'no est?n': 'no están',
    'est? disponible': 'está disponible',
    'no est? disponible': 'no está disponible'
}

for old, new in replacements.items():
    content = content.replace(old, new)

# Corregir signos "?" en console.log (patrón: console.xxx('? ...)
content = re.sub(r"console\.log\('\\?", "console.log('🔍", content)
content = re.sub(r'console\.log\("\\?', 'console.log("🔍', content)
content = re.sub(r"console\.warn\('\\?", "console.warn('⚠️", content)
content = re.sub(r'console\.warn\("\\?', 'console.warn("⚠️', content)
content = re.sub(r"console\.error\('\\?", "console.error('❌", content)
content = re.sub(r'console\.error\("\\?', 'console.error("❌', content)

# Corregir "??" (doble signo) en cualquier contexto
content = re.sub(r"'\\?\\?", "'🔍", content)
content = re.sub(r'"\\?\\?', '"🔍', content)
content = re.sub(r'`\\?\\?', '`🔍', content)

# Corregir casos específicos encontrados
content = re.sub(r"console\.warn\('\\?\\? Algunas", "console.warn('⚠️ Algunas", content)
content = re.sub(r"console\.error\('\\? El navegador", "console.error('⚠️ El navegador", content)
content = re.sub(r"console\.error\('\\? \.content", "console.error('❌ .content", content)
content = re.sub(r"console\.warn\('\\?\\? No se encontr", "console.warn('⚠️ No se encontr", content)
content = re.sub(r"console\.log\('\\? Conocimiento", "console.log('✅ Conocimiento", content)
content = re.sub(r"console\.error\('\\? Campo", "console.error('❌ Campo", content)
content = re.sub(r"console\.error\('\\? Contenedor", "console.error('❌ Contenedor", content)
content = re.sub(r"console\.error\('\\? Modal", "console.error('❌ Modal", content)
content = re.sub(r"console\.log\('\\? Modal", "console.log('🔍 Modal", content)
content = re.sub(r"console\.warn\('\\?\\? openImageManager", "console.warn('⚠️ openImageManager", content)

# Guardar archivo
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Todas las correcciones aplicadas")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo "✅ Corrección completada"
else
    echo "❌ Error en la corrección"
    exit 1
fi
echo ""

echo "=== Verificar problemas restantes ==="
RESTANTES=$(grep -cE "console\..*'\\?|console\..*\"\\?|\\?\\?|est\\?n|v\\?lido|b\\?sico" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$RESTANTES" -gt "0" ]; then
    echo "⚠️  Aún hay $RESTANTES problemas:"
    grep -nE "console\..*'\\?|console\..*\"\\?|\\?\\?|est\\?n|v\\?lido|b\\?sico" "$DASHBOARD_PATH" | head -10
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
