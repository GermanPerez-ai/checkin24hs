#!/bin/bash
# Script para corregir todos los errores en dashboard.html

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Corrigiendo todos los errores"
echo "=========================================="
echo ""

# Backup
cp dashboard.html "dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"
echo "Backup creado"
echo ""

# Eliminar TODOS los emojis usando Python
echo "1. Eliminando TODOS los emojis de console.log..."
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

# Eliminar emojis de cualquier console.XXX(...)
for emoji in emojis:
    # Patrón para console.log/error/warn/info con emoji
    patterns = [
        # Comillas simples
        (rf"console\.(log|error|warn|info)\('([^']*){re.escape(emoji)}([^']*)'\)", 
         lambda m: m.group(0).replace(emoji, '')),
        # Comillas dobles
        (rf'console\.(log|error|warn|info)\("([^"]*){re.escape(emoji)}([^"]*)"\)', 
         lambda m: m.group(0).replace(emoji, '')),
        # Template literals
        (rf'console\.(log|error|warn|info)\(`([^`]*){re.escape(emoji)}([^`]*)`\)', 
         lambda m: m.group(0).replace(emoji, '')),
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content)
    
    # También eliminar emojis sueltos en cualquier console.XXX
    content = re.sub(
        rf'console\.(log|error|warn|info)\(([^)]*){re.escape(emoji)}([^)]*)\)',
        lambda m: m.group(0).replace(emoji, ''),
        content
    )

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Emojis eliminados")
PYTHON_EOF

echo ""

# Verificar que loadAIConfigFromSupabase esté disponible globalmente
echo "2. Verificando funciones globales..."
if grep -q "window.loadAIConfigFromSupabase" dashboard.html; then
    echo "OK: loadAIConfigFromSupabase es global"
else
    echo "Corrigiendo loadAIConfigFromSupabase..."
    python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Cambiar function loadAIConfigFromSupabase a window.loadAIConfigFromSupabase
content = re.sub(
    r'async function loadAIConfigFromSupabase\(\)',
    'window.loadAIConfigFromSupabase = async function loadAIConfigFromSupabase()',
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("loadAIConfigFromSupabase corregida")
PYTHON_EOF
fi

if grep -q "window.loadWhatsAppCards" dashboard.html; then
    echo "OK: loadWhatsAppCards es global"
else
    echo "Corrigiendo loadWhatsAppCards..."
    python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Cambiar function loadWhatsAppCards a window.loadWhatsAppCards
content = re.sub(
    r'async function loadWhatsAppCards\(\)',
    'window.loadWhatsAppCards = async function loadWhatsAppCards()',
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("loadWhatsAppCards corregida")
PYTHON_EOF
fi

echo ""

# Verificar showSection
echo "3. Verificando showSection..."
head -50 dashboard.html | grep -q "window.showSection" && echo "OK: showSection encontrada en head" || echo "ERROR: showSection NO encontrada"

echo ""
echo "=========================================="
echo "Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Ahora copia al contenedor:"
echo "CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "docker service update --force checkin24hs_dashboard"


