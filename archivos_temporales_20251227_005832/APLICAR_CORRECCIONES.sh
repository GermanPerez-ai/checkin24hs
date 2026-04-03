#!/bin/bash
# Script para aplicar correcciones después de crear estado1

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Aplicando correcciones"
echo "=========================================="
echo ""

# Backup antes de las correcciones
cp dashboard.html "dashboard.html.backup_antes_correcciones_$(date +%Y%m%d_%H%M%S)"
echo "Backup de seguridad creado"
echo ""

# Aplicar correcciones con Python
echo "Aplicando correcciones..."
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Lista completa de emojis
emojis = [
    '🎫', '🤖', '✅', '💾', '🔄', '📊', '☁️', '⚠️', '❌', '🔐', '📁', 
    '✏️', '🗑️', '🖼️', '👁️', '⚙️', '⏭️', 'ℹ️', '📋', '🔍', '🌸', 
    '📦', '💬', '📱', '📑', '👋'
]

print("1. Eliminando emojis de console.log...")
# Eliminar emojis de cualquier console.XXX(...)
for emoji in emojis:
    # Patrón para eliminar emoji de console.log/error/warn/info
    content = re.sub(
        rf'console\.(log|error|warn|info)\(([^)]*){re.escape(emoji)}([^)]*)\)',
        lambda m: m.group(0).replace(emoji, ''),
        content
    )

print("   Emojis eliminados")

# Hacer funciones globales
print("2. Haciendo funciones globales...")

# loadAIConfigFromSupabase
if 'window.loadAIConfigFromSupabase' not in content:
    content = re.sub(
        r'async function loadAIConfigFromSupabase\(\)',
        'window.loadAIConfigFromSupabase = async function loadAIConfigFromSupabase()',
        content
    )
    print("   loadAIConfigFromSupabase ahora es global")
else:
    print("   loadAIConfigFromSupabase ya es global")

# loadWhatsAppCards
if 'window.loadWhatsAppCards' not in content:
    content = re.sub(
        r'async function loadWhatsAppCards\(\)',
        'window.loadWhatsAppCards = async function loadWhatsAppCards()',
        content
    )
    print("   loadWhatsAppCards ahora es global")
else:
    print("   loadWhatsAppCards ya es global")

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("")
print("Correcciones aplicadas exitosamente")
PYTHON_EOF

echo ""
echo "Verificando correcciones..."
head -50 dashboard.html | grep -q "window.showSection" && echo "OK: showSection encontrada en head" || echo "ERROR: showSection NO encontrada"
grep -q "window.loadAIConfigFromSupabase" dashboard.html && echo "OK: loadAIConfigFromSupabase es global" || echo "ERROR: loadAIConfigFromSupabase NO es global"
grep -q "window.loadWhatsAppCards" dashboard.html && echo "OK: loadWhatsAppCards es global" || echo "ERROR: loadWhatsAppCards NO es global"

echo ""
echo "=========================================="
echo "Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Ahora aplica al contenedor con:"
echo "  CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "  docker service update --force checkin24hs_dashboard"
echo "  sleep 30"
echo "  NEW_CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${NEW_CONTAINER_ID}:/app/dashboard.html"
echo ""


