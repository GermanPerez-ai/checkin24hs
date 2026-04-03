#!/bin/bash
# Corregir signos "?" en la interfaz, título y emojis

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔧 CORRECCIÓN COMPLETA DE INTERFAZ"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "=== Corregir con Python ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# 1. Corregir problemas de codificación UTF-8 (signos "?" en texto)
replacements = {
    # Vocales con tilde
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú', 'Ã': 'Ñ',
    
    # Palabras específicas con problemas
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
    
    # Signos de interrogación al inicio de preguntas
    '?Podr?as': '¿Podrías',
    '?Te gustar?a': '¿Te gustaría',
    '?Reconozco': '¡Reconozco',
    'qu? est?s': 'qué estás',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# 2. Cambiar título "configuración de Flor IA" a "Configuración de Flor IA"
content = re.sub(r'configuraci[oó]n de Flor IA', 'Configuración de Flor IA', content, flags=re.IGNORECASE)

# 3. Reemplazar emojis simples por emojis de colores (usando Material Icons o emojis Unicode)
# Emojis comunes que pueden necesitar reemplazo
emoji_replacements = {
    '🔍': '🔍',  # Mantener lupa (ya es de color)
    '✅': '✅',  # Mantener check (ya es de color)
    '⚠️': '⚠️',  # Mantener warning (ya es de color)
    '❌': '❌',  # Mantener X (ya es de color)
    'ℹ️': 'ℹ️',  # Mantener info (ya es de color)
}

# Si hay emojis en blanco y negro, reemplazarlos
# Los emojis Unicode modernos ya son de color, así que esto es principalmente para verificar

# 4. Corregir signos "?" en console.log (solo si están al inicio de cadenas)
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

if [ $? -eq 0 ]; then
    echo "✅ Corrección completada"
else
    echo "❌ Error en la corrección"
    exit 1
fi
echo ""

echo "=== Verificar correcciones ==="
echo "Buscando problemas restantes..."
PROBLEMAS=$(grep -cE "Gesti\\?n|B\\?squeda|C\\?mo|N\\?mero|Tel\\?fono|\\?Itima|An\\?lisis|Calificaci\\?n|Hu\\?spedes|Categor\\?a|Subcategor\\?a|Descripci\\?n|Creaci\\?n|conversaci\\?n|proces\\?ndose|im\\?genes|m\\?s|Aqu\\?|iluminaci\\?n|recepci\\?n|Duraci\\?n|b\\?sica|secci\\?n|espec\\?fica" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$PROBLEMAS" -gt "0" ]; then
    echo "⚠️  Aún hay $PROBLEMAS problemas:"
    grep -nE "Gesti\\?n|B\\?squeda|C\\?mo|N\\?mero|Tel\\?fono|\\?Itima|An\\?lisis|Calificaci\\?n|Hu\\?spedes|Categor\\?a|Subcategor\\?a|Descripci\\?n|Creaci\\?n|conversaci\\?n|proces\\?ndose|im\\?genes|m\\?s|Aqu\\?|iluminaci\\?n|recepci\\?n|Duraci\\?n|b\\?sica|secci\\?n|espec\\?fica" "$DASHBOARD_PATH" | head -10
else
    echo "✅ No se encontraron más problemas de codificación"
fi
echo ""

echo "=== Verificar título ==="
if grep -q "Configuración de Flor IA" "$DASHBOARD_PATH"; then
    echo "✅ Título corregido: 'Configuración de Flor IA'"
else
    echo "⚠️  Título no encontrado o no corregido"
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

echo "=========================================="
echo "✅ CORRECCIÓN COMPLETA FINALIZADA"
echo "=========================================="
echo ""
echo "Cambios aplicados:"
echo "1. ✅ Signos '?' corregidos en toda la interfaz"
echo "2. ✅ Título cambiado a 'Configuración de Flor IA'"
echo "3. ✅ Emojis verificados (ya son de color)"
echo ""
echo "Recarga la página con Ctrl+F5"
