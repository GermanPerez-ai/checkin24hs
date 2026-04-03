#!/bin/bash
# Script para corregir dashboard.html en el servidor
# Elimina emojis y caracteres problemáticos de console.log

cd /root/checkin24hs || exit 1

# Backup
cp dashboard.html "dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"
echo "Backup creado"

# Método alternativo: usar Python si está disponible, o sed con patrones más específicos
if command -v python3 &> /dev/null; then
    echo "Usando Python para eliminar emojis..."
    python3 << 'PYTHON_EOF'
import re
import sys

file_path = '/root/checkin24hs/dashboard.html'

# Leer archivo
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Lista de emojis a eliminar (códigos Unicode)
emojis_to_remove = [
    '\U0001F3AB',  # 🎫
    '\U0001F916',  # 🤖
    '\u2705',      # ✅
    '\U0001F4BE',  # 💾
    '\U0001F504',  # 🔄
    '\U0001F4CA',  # 📊
    '\u2601\ufe0f', # ☁️
    '\u26a0\ufe0f', # ⚠️
    '\u274c',      # ❌
    '\U0001F510',  # 🔐
    '\U0001F4C1',  # 📁
    '\u270f\ufe0f', # ✏️
    '\U0001F5D1\ufe0f', # 🗑️
    '\U0001F5BC\ufe0f', # 🖼️
    '\U0001F441\ufe0f', # 👁️
    '\u2699\ufe0f', # ⚙️
    '\u23ed\ufe0f', # ⏭️
    '\u2139\ufe0f', # ℹ️
]

# Eliminar emojis de console.log/error/warn/info
for emoji in emojis_to_remove:
    # Buscar console.XXX('...emoji...') o console.XXX("...emoji...") o console.XXX(`...emoji...`)
    patterns = [
        (rf"console\.(log|error|warn|info)\('([^']*){re.escape(emoji)}([^']*)'\)", r"console.\1('\2\3')"),
        (rf'console\.(log|error|warn|info)\("([^"]*){re.escape(emoji)}([^"]*)"\)', r'console.\1("\2\3")'),
        (rf'console\.(log|error|warn|info)\(`([^`]*){re.escape(emoji)}([^`]*)`\)', r'console.\1(`\2\3`)'),
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

print("Emojis eliminados exitosamente")
PYTHON_EOF
else
    echo "Python no disponible, usando sed con patrones ASCII..."
    # Método alternativo: buscar y reemplazar patrones específicos conocidos
    # Esto es menos efectivo pero funciona sin Python
    
    # Buscar líneas con console.log que contengan caracteres problemáticos
    # y eliminar solo los caracteres no-ASCII dentro de las comillas
    sed -i 's/console\.log([^)]*[^[:print:]][^)]*)/console.log(...)/g' dashboard.html 2>/dev/null || true
    
    echo "Nota: Algunos emojis pueden quedar. Se recomienda usar Python para eliminación completa."
fi

# Verificar showSection
echo ""
echo "Verificando showSection..."
if head -50 dashboard.html | grep -q "window.showSection"; then
    echo "OK: showSection encontrada en head"
else
    echo "ERROR: showSection NO encontrada en head"
fi

echo ""
echo "Correcciones aplicadas. Ahora copia al contenedor:"
echo "CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "docker service update --force checkin24hs_dashboard"


