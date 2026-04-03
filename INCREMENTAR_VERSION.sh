#!/bin/bash
# Script para incrementar el build number del dashboard antes de subir a GitHub

DASHBOARD_PATH="deploy/dashboard.html"
BACKUP_FILE="deploy/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔢 INCREMENTAR VERSIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "=== Incrementar build number ==="
python3 << 'PYTHON_EOF'
import re
from datetime import datetime

file_path = 'deploy/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Obtener build number actual
build_match = re.search(r"window\.DASHBOARD_BUILD_NUMBER\s*=\s*(\d+)", content)
if build_match:
    current_build = int(build_match.group(1))
    new_build = current_build + 1
    print(f"Build actual: {current_build}")
    print(f"Nuevo build: {new_build}")
else:
    new_build = 1
    print(f"Primer build: {new_build}")

# Generar timestamp actual
current_timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
print(f"Timestamp: {current_timestamp}")

# Actualizar build number
content = re.sub(
    r"window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+",
    f"window.DASHBOARD_BUILD_NUMBER = {new_build}",
    content
)

# Actualizar build timestamp
content = re.sub(
    r"window\.DASHBOARD_BUILD\s*=\s*'[^']+'",
    f"window.DASHBOARD_BUILD = '{current_timestamp}'",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Versión actualizada")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo "✅ Build number incrementado"
else
    echo "❌ Error al incrementar build number"
    exit 1
fi
echo ""

echo "=== Verificar cambios ==="
grep -E "DASHBOARD_BUILD|DASHBOARD_BUILD_NUMBER" "$DASHBOARD_PATH" | head -2
echo ""

echo "=========================================="
echo "✅ Versión incrementada. Listo para commit y push"
echo "=========================================="
