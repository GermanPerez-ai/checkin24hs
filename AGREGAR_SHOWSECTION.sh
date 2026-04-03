#!/bin/bash
# Script para agregar showSection al dashboard.html si no está

cd /root/checkin24hs

echo "Verificando si showSection existe..."
if grep -q "window.showSection = function" dashboard.html; then
    echo "showSection ya existe en el archivo"
    # Verificar posición
    LINE_NUM=$(grep -n "window.showSection = function" dashboard.html | head -1 | cut -d: -f1)
    echo "showSection encontrada en la linea $LINE_NUM"
    if [ "$LINE_NUM" -le 50 ]; then
        echo "OK: showSection esta en el head"
    else
        echo "ADVERTENCIA: showSection NO esta en el head (linea $LINE_NUM)"
    fi
else
    echo "showSection NO encontrada. Agregandola al head..."
    
    # Crear backup
    cp dashboard.html "dashboard.html.backup_before_showsection_$(date +%Y%m%d_%H%M%S)"
    
    # Buscar la línea después de <head>
    HEAD_LINE=$(grep -n "<head>" dashboard.html | head -1 | cut -d: -f1)
    
    if [ -z "$HEAD_LINE" ]; then
        echo "ERROR: No se encontro <head> en el archivo"
        exit 1
    fi
    
    echo "Head encontrado en linea $HEAD_LINE"
    
    # Script Python para insertar showSection después de <head>
    python3 << 'PYTHON_EOF'
import sys

file_path = '/root/checkin24hs/dashboard.html'

# Leer archivo
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Definición de showSection
show_section_code = '''    <!-- CRITICO: Definir showSection LO PRIMERO - antes de cualquier otro codigo -->
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

# Buscar <head> y verificar si showSection ya está
head_found = False
show_section_exists = False

for i, line in enumerate(lines):
    if '<head>' in line.lower() and not head_found:
        head_found = True
        head_line = i
        # Verificar si showSection ya está en las siguientes 50 líneas
        for j in range(i, min(i + 50, len(lines))):
            if 'window.showSection' in lines[j]:
                show_section_exists = True
                break
        break

if not head_found:
    print("ERROR: No se encontro <head>")
    sys.exit(1)

if show_section_exists:
    print("showSection ya existe en el archivo")
    sys.exit(0)

# Insertar showSection después de <head>
insert_pos = head_line + 1
new_lines = lines[:insert_pos] + [show_section_code + '\n'] + lines[insert_pos:]

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"showSection agregada despues de <head> (linea {head_line + 1})")
PYTHON_EOF

    echo ""
    echo "Verificando que se agrego correctamente..."
    if head -50 dashboard.html | grep -q "window.showSection"; then
        echo "OK: showSection ahora esta en el head"
    else
        echo "ERROR: showSection NO se agrego correctamente"
        exit 1
    fi
fi

echo ""
echo "Archivo listo. Ahora copia al contenedor:"
echo "CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "docker service update --force checkin24hs_dashboard"


