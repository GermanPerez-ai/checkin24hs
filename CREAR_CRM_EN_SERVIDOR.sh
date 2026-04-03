#!/bin/bash
# Script para crear CRM en el servidor desde dashboard.html

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Creando CRM separado"
echo "=========================================="
echo ""

# Usar Python para extraer secciones
python3 << 'PYTHON_EOF'
import re

dashboard_path = '/root/checkin24hs/dashboard.html'
crm_path = '/root/checkin24hs/crm.html'

print("Leyendo dashboard.html...")
with open(dashboard_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Buscar inicio y fin de cada sección usando líneas conocidas
lines = content.split('\n')

# Encontrar líneas de inicio
interactions_start = None
chats_start = None
flor_start = None

for i, line in enumerate(lines):
    if 'id="interactions-section"' in line:
        interactions_start = i
    elif 'id="chats-section"' in line:
        chats_start = i
    elif 'id="flor-config-section"' in line:
        flor_start = i

print(f"Secciones encontradas:")
print(f"  Interactions: línea {interactions_start}")
print(f"  Chats: línea {chats_start}")
print(f"  Flor: línea {flor_start}")

# Extraer CSS (primer bloque style)
css_match = re.search(r'<style>(.*?)</style>', content, re.DOTALL)
css = css_match.group(1) if css_match else ''

# Crear CRM HTML básico
crm_html = f'''<!DOCTYPE html>
<html lang="es">
<head>
    <script>
        window.showSection = function(section, event) {{
            try {{
                if (event && event.preventDefault) event.preventDefault();
                var sections = document.querySelectorAll('[id$="-section"]');
                for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
                var target = document.getElementById(section + '-section');
                if (target) {{
                    target.style.display = 'block';
                    var items = document.querySelectorAll('.menu-item');
                    for (var j = 0; j < items.length; j++) items[j].classList.remove('active');
                    if (event && event.target) event.target.classList.add('active');
                }}
            }} catch(e) {{ console.error('showSection error:', e); }}
        }};
    </script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CRM - Checkin24hs</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link rel="icon" type="image/png" href="logo.png">
    <style>
{css}
    </style>
</head>
<body class="authenticated">
    <div class="sidebar">
        <div class="sidebar-header">
            <h2><span class="material-icons">business</span>CRM Checkin24hs</h2>
        </div>
        <div class="sidebar-menu">
            <a href="#" class="menu-item active" onclick="window.showSection('interactions', event)">
                <span class="material-icons">chat</span>Interacciones
            </a>
            <a href="#" class="menu-item" onclick="window.showSection('chats', event)">
                <span class="material-icons">forum</span>Chats
            </a>
            <a href="#" class="menu-item" onclick="window.showSection('flor-config', event)">
                <span class="material-icons">settings</span>Flor IA
            </a>
        </div>
    </div>
    <div class="main-content">
        <!-- Las secciones se copiarán aquí manualmente o con otro script -->
        <p>CRM en construcción. Las secciones se agregarán próximamente.</p>
    </div>
    <script src="supabase-config.js"></script>
    <script src="supabase-client.js"></script>
</body>
</html>'''

with open(crm_path, 'w', encoding='utf-8') as f:
    f.write(crm_html)

print(f"\nCRM básico creado: {crm_path}")
print("NOTA: Necesitas copiar manualmente las secciones HTML desde dashboard.html")
print("o usar un script más avanzado para extraerlas automáticamente.")
PYTHON_EOF

echo ""
echo "CRM básico creado. Para completarlo, necesitas:"
echo "1. Copiar las secciones HTML de interactions-section, chats-section, flor-config-section"
echo "2. Copiar las funciones JavaScript relacionadas"
echo "3. Probar el CRM"


