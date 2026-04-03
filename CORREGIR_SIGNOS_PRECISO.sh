#!/bin/bash
# Corregir signos "?" SOLO en console.log, NO en URLs ni código

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"

echo "=========================================="
echo "🔧 CORRECCIÓN PRECISA DE SIGNOS '?'"
echo "=========================================="
echo ""

# Restaurar del backup más reciente
echo "=== Restaurar del backup ==="
BACKUP=$(ls -t /root/checkin24hs/dashboard.html.backup_* 2>/dev/null | head -1)
if [ -n "$BACKUP" ]; then
    cp "$BACKUP" "$DASHBOARD_PATH"
    echo "✅ Restaurado desde: $BACKUP"
else
    echo "⚠️  No se encontró backup, continuando con archivo actual"
fi
echo ""

echo "=== Corregir SOLO en console.log (no en URLs ni código) ==="
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Corregir problemas de codificación UTF-8 (solo estos)
replacements = {
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú', 'Ã±': 'ñ',
    'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú', 'Ã': 'Ñ',
    'est?n': 'están', 'v?lido': 'válido', 'b?sico': 'básico', 'cach?': 'caché'
}

for old, new in replacements.items():
    content = content.replace(old, new)

# Corregir signos "?" SOLO en console.log/warn/error, NO en URLs ni código
# Patrón más específico: console.xxx('? texto) o console.xxx("? texto)
# NO tocar si hay http, https, ?, :, /, etc. antes del signo

# Solo reemplazar si el signo ? está al inicio de una cadena en console.log
content = re.sub(r"console\.log\('\\?\s+([^']+)", r"console.log('🔍 \1", content)
content = re.sub(r'console\.log\("\\?\s+([^"]+)', r'console.log("🔍 \1', content)
content = re.sub(r"console\.warn\('\\?\s+([^']+)", r"console.warn('⚠️ \1", content)
content = re.sub(r'console\.warn\("\\?\s+([^"]+)', r'console.warn("⚠️ \1', content)
content = re.sub(r"console\.error\('\\?\s+([^']+)", r"console.error('❌ \1", content)
content = re.sub(r'console\.error\("\\?\s+([^"]+)', r'console.error("❌ \1', content)

# Corregir "??" SOLO en console.log (no en URLs)
content = re.sub(r"console\.log\('\\?\\?\s+", "console.log('🔍 ", content)
content = re.sub(r'console\.log\("\\?\\?\s+', 'console.log("🔍 ', content)
content = re.sub(r"console\.warn\('\\?\\?\s+", "console.warn('⚠️ ", content)
content = re.sub(r'console\.warn\("\\?\\?\s+', 'console.warn("⚠️ ', content)

# Casos específicos encontrados (sin tocar URLs)
content = re.sub(r"console\.warn\('\\?\\? Algunas funciones no están", "console.warn('⚠️ Algunas funciones no están", content)
content = re.sub(r"console\.error\('\\?\s+El navegador está usando caché", "console.error('⚠️ El navegador está usando caché", content)
content = re.sub(r"console\.error\('\\?\s+\.content no encontrado", "console.error('❌ .content no encontrado", content)
content = re.sub(r"console\.warn\('\\?\\?\s+No se encontr", "console.warn('⚠️ No se encontr", content)
content = re.sub(r"console\.log\('\\?\s+Conocimiento adicional guardado", "console.log('✅ Conocimiento adicional guardado", content)
content = re.sub(r"console\.error\('\\?\s+Campo editHotelPhotos", "console.error('❌ Campo editHotelPhotos", content)
content = re.sub(r"console\.error\('\\?\s+Contenedor editPhotosPreview", "console.error('❌ Contenedor editPhotosPreview", content)
content = re.sub(r"console\.error\('\\?\s+Modal no encontrado", "console.error('❌ Modal no encontrado", content)
content = re.sub(r"console\.log\('\\?\s+Modal encontrado", "console.log('🔍 Modal encontrado", content)
content = re.sub(r"console\.warn\('\\?\\?\s+openImageManager no está", "console.warn('⚠️ openImageManager no está", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas (solo en console.log)")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo "✅ Corrección completada"
else
    echo "❌ Error en la corrección"
    exit 1
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
