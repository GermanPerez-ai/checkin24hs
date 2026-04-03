#!/bin/bash
# Script para restaurar estado1 y aplicar correcciones paso a paso

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Restaurando estado1 y corrigiendo paso a paso"
echo "=========================================="
echo ""

# 1. Restaurar estado1
echo "1. Restaurando estado1..."
cp /root/checkin24hs/backups/estado1/dashboard.html dashboard.html
echo "   OK: Estado1 restaurado"
echo ""

# 2. Verificar línea 5150
echo "2. Verificando linea 5150..."
sed -n '5145,5155p' dashboard.html | cat -n
echo ""

# 3. Aplicar correcciones paso a paso
echo "3. Aplicando correcciones..."
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

print("   a) Eliminando TODOS los emojis...")
# Lista completa de emojis
emojis = [
    '🎫', '🤖', '✅', '💾', '🔄', '📊', '☁️', '⚠️', '❌', '🔐', '📁', 
    '✏️', '🗑️', '🖼️', '👁️', '⚙️', '⏭️', 'ℹ️', '📋', '🔍', '🌸', 
    '📦', '💬', '📱', '📑', '👋'
]

# Eliminar emojis de cualquier console.XXX(...)
for emoji in emojis:
    content = re.sub(
        rf'console\.(log|error|warn|info)\(([^)]*){re.escape(emoji)}([^)]*)\)',
        lambda m: m.group(0).replace(emoji, ''),
        content
    )
print("      Emojis eliminados")

print("   b) Corrigiendo funciones globales...")
# Hacer funciones globales
if 'window.loadAIConfigFromSupabase' not in content:
    content = re.sub(
        r'async function loadAIConfigFromSupabase\(\)',
        'window.loadAIConfigFromSupabase = async function loadAIConfigFromSupabase()',
        content
    )
    print("      loadAIConfigFromSupabase ahora es global")

if 'window.loadWhatsAppCards' not in content:
    content = re.sub(
        r'async function loadWhatsAppCards\(\)',
        'window.loadWhatsAppCards = async function loadWhatsAppCards()',
        content
    )
    print("      loadWhatsAppCards ahora es global")

print("   c) Corrigiendo llamadas a funciones...")
# Corregir llamadas para usar window.
lines = content.split('\n')
new_lines = []
for line in lines:
    # Corregir loadAIConfigFromSupabase() pero no la definición
    if 'loadAIConfigFromSupabase()' in line and 'window.loadAIConfigFromSupabase =' not in line:
        line = line.replace('loadAIConfigFromSupabase()', 'window.loadAIConfigFromSupabase()')
    # Corregir loadWhatsAppCards() pero no la definición
    if 'loadWhatsAppCards()' in line and 'window.loadWhatsAppCards =' not in line:
        line = line.replace('loadWhatsAppCards()', 'window.loadWhatsAppCards()')
    new_lines.append(line)
content = '\n'.join(new_lines)
print("      Llamadas corregidas")

print("   d) Verificando y corrigiendo showSection...")
# Verificar que showSection esté en el head
if 'window.showSection = function' not in content[:5000]:  # Primeras 5000 líneas
    print("      ADVERTENCIA: showSection no encontrada en el head")
    # Buscar <head> y agregar showSection después
    head_match = re.search(r'<head>', content, re.IGNORECASE)
    if head_match:
        show_section_code = '''    <!-- CRITICO: Definir showSection LO PRIMERO -->
    <script>
        window.showSection = function(section, event) {
            try {
                if (event && event.preventDefault) event.preventDefault();
                var sections = document.querySelectorAll('[id$="-section"]');
                for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
                var target = document.getElementById(section + '-section');
                if (target) {
                    target.style.display = 'block';
                    var items = document.querySelectorAll('.menu-item');
                    for (var j = 0; j < items.length; j++) items[j].classList.remove('active');
                    if (event && event.target) event.target.classList.add('active');
                }
            } catch(e) { console.error('showSection error:', e); }
        };
    </script>
'''
        insert_pos = head_match.end()
        content = content[:insert_pos] + '\n' + show_section_code + content[insert_pos:]
        print("      showSection agregada al head")
else:
    print("      showSection encontrada en el head")

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("")
print("Correcciones aplicadas exitosamente")
PYTHON_EOF

echo ""
echo "4. Verificando correcciones..."
head -50 dashboard.html | grep -q "window.showSection" && echo "   OK: showSection encontrada" || echo "   ERROR: showSection NO encontrada"
grep -q "window.loadAIConfigFromSupabase" dashboard.html && echo "   OK: loadAIConfigFromSupabase es global" || echo "   ERROR"
grep -q "window.loadWhatsAppCards" dashboard.html && echo "   OK: loadWhatsAppCards es global" || echo "   ERROR"

echo ""
echo "=========================================="
echo "Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Ahora aplica al contenedor:"
echo "  CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "  docker service update --force checkin24hs_dashboard"
echo "  sleep 30"
echo "  NEW_CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${NEW_CONTAINER_ID}:/app/dashboard.html"
echo ""


