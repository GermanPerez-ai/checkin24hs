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

# 1. Corregir problemas de codificación UTF-8
replacements = {
    # Vocales con tilde
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú', 'Ã': 'Ñ',
    
    # Palabras específicas con problemas (de las imágenes)
    'Gesti?n': 'Gestión',
    'B?squeda': 'Búsqueda',
    'C?mo': 'Cómo',
    'N?mero': 'Número',
    'env?a': 'envía',
    'confirmaci?n': 'confirmación',
    'Tel?fono': 'Teléfono',
    '?Itima': 'Última',
    'An?lisis': 'Análisis',
    'Calificaci?n': 'Calificación',
    'Hu?spedes': 'Huéspedes',
    'Categor?a': 'Categoría',
    'Subcategor?a': 'Subcategoría',
    'Descripci?n': 'Descripción',
    'Creaci?n': 'Creación',
    'conversaci?n': 'conversación',
    'proces?ndose': 'procesándose',
    'im?genes': 'imágenes',
    'm?s': 'más',
    'Aqu?': 'Aquí',
    'iluminaci?n': 'iluminación',
    'recepci?n': 'recepción',
    'Duraci?n': 'Duración',
    'b?sica': 'básica',
    'secci?n': 'sección',
    'espec?fica': 'específica',
    'est?n': 'están',
    'v?lido': 'válido',
    'b?sico': 'básico',
    'cach?': 'caché',
    '?Podr?as': '¿Podrías',
    '?Te gustar?a': '¿Te gustaría',
    '?Reconozco': '¡Reconozco',
    'qu? est?s': 'qué estás',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# 2. Cambiar título "configuración de Flor IA" a "Configuración de Flor IA"
content = re.sub(r'configuraci[oó]n de Flor IA', 'Configuración de Flor IA', content, flags=re.IGNORECASE)

# 3. Los emojis Unicode modernos ya son de color, así que no necesitamos cambiarlos
# Pero podemos verificar que estén correctos

# 4. Corregir signos "?" en console.log
content = re.sub(r"console\.log\('\\?\s+([^']+)", r"console.log('🔍 \1", content)
content = re.sub(r'console\.log\("\\?\s+([^"]+)', r'console.log("🔍 \1', content)
content = re.sub(r"console\.warn\('\\?\s+([^']+)", r"console.warn('⚠️ \1", content)
content = re.sub(r'console\.warn\("\\?\s+([^"]+)', r'console.warn("⚠️ \1', content)
content = re.sub(r"console\.error\('\\?\s+([^']+)", r"console.error('❌ \1", content)
content = re.sub(r'console\.error\("\\?\s+([^"]+)', r'console.error("❌ \1', content)

# Corregir "??"
content = re.sub(r"console\.log\('\\?\\?\s+", "console.log('🔍 ", content)
content = re.sub(r'console\.log\("\\?\\?\s+', 'console.log("🔍 ', content)
content = re.sub(r"console\.warn\('\\?\\?\s+", "console.warn('⚠️ ", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Todas las correcciones aplicadas")
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
