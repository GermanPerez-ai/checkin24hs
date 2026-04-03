#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para extraer secciones CRM del dashboard.html y crear crm.html
"""

import re

def extract_section(html_content, section_id):
    """Extrae una sección completa del HTML"""
    pattern = rf'<div[^>]*id="{section_id}"[^>]*>.*?</div>\s*</div>\s*</div>'
    match = re.search(pattern, html_content, re.DOTALL)
    if match:
        return match.group(0)
    return None

def extract_css(html_content):
    """Extrae el CSS del dashboard"""
    # Buscar el bloque <style>
    style_match = re.search(r'<style>(.*?)</style>', html_content, re.DOTALL)
    if style_match:
        return style_match.group(1)
    return ''

def extract_js_functions(html_content, function_names):
    """Extrae funciones JavaScript específicas"""
    functions = {}
    for func_name in function_names:
        # Buscar función con diferentes patrones
        patterns = [
            rf'(window\.{func_name}\s*=\s*function[^{{]*\{{[^}}]*\}}[^}}]*\}})',
            rf'(function\s+{func_name}\s*\([^)]*\)\s*\{{[^}}]*\}}[^}}]*\}})',
            rf'(async\s+function\s+{func_name}\s*\([^)]*\)\s*\{{[^}}]*\}}[^}}]*\}})',
        ]
        for pattern in patterns:
            match = re.search(pattern, html_content, re.DOTALL)
            if match:
                functions[func_name] = match.group(1)
                break
    return functions

def create_crm_html(dashboard_path, output_path):
    """Crea crm.html desde dashboard.html"""
    
    print("Leyendo dashboard.html...")
    with open(dashboard_path, 'r', encoding='utf-8') as f:
        dashboard_content = f.read()
    
    print("Extrayendo secciones...")
    
    # Extraer secciones HTML
    interactions_section = extract_section(dashboard_content, 'interactions-section')
    chats_section = extract_section(dashboard_content, 'chats-section')
    flor_config_section = extract_section(dashboard_content, 'flor-config-section')
    
    # Extraer CSS
    css = extract_css(dashboard_content)
    
    # Buscar funciones JavaScript necesarias
    # Usar búsqueda más simple: buscar desde la definición hasta el cierre
    print("Extrayendo funciones JavaScript...")
    
    # Buscar loadInteractions
    load_interactions_match = re.search(
        r'(window\.loadInteractions\s*=\s*async\s+function[^}]*?};)',
        dashboard_content,
        re.DOTALL
    )
    load_interactions = load_interactions_match.group(1) if load_interactions_match else ''
    
    # Buscar loadChats
    load_chats_match = re.search(
        r'(window\.loadChats\s*=\s*async\s+function[^}]*?};)',
        dashboard_content,
        re.DOTALL
    )
    load_chats = load_chats_match.group(1) if load_chats_match else ''
    
    # Buscar funciones de Flor IA (buscar bloques grandes)
    flor_functions_match = re.search(
        r'(//.*?Flor.*?function.*?\{.*?\n.*?\n.*?\})',
        dashboard_content,
        re.DOTALL
    )
    
    # Crear HTML del CRM
    crm_html = f'''<!DOCTYPE html>
<html lang="es">
<head>
    <!-- CRITICO: Definir showSection LO PRIMERO -->
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
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-header">
            <h2>
                <span class="material-icons">business</span>
                CRM Checkin24hs
            </h2>
        </div>
        <div class="sidebar-menu">
            <a href="#" class="menu-item active" onclick="window.showSection('interactions', event)">
                <span class="material-icons">chat</span>
                Interacciones
            </a>
            <a href="#" class="menu-item" onclick="window.showSection('chats', event)">
                <span class="material-icons">forum</span>
                Chats
            </a>
            <a href="#" class="menu-item" onclick="window.showSection('flor-config', event)">
                <span class="material-icons">settings</span>
                Flor IA
            </a>
        </div>
    </div>

    <!-- Main Content -->
    <div class="main-content">
{interactions_section if interactions_section else '<!-- Interactions section -->'}
{chats_section if chats_section else '<!-- Chats section -->'}
{flor_config_section if flor_config_section else '<!-- Flor config section -->'}
    </div>

    <!-- Scripts -->
    <script src="supabase-config.js"></script>
    <script src="supabase-client.js"></script>
    
    <script>
        // Funciones CRM
{load_interactions}

{load_chats}

        // Inicializar cuando se carga la página
        document.addEventListener('DOMContentLoaded', function() {{
            // Cargar interacciones por defecto
            if (typeof window.loadInteractions === 'function') {{
                window.loadInteractions();
            }}
        }});
    </script>
</body>
</html>'''
    
    print(f"Guardando {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(crm_html)
    
    print(f"CRM creado exitosamente: {output_path}")
    print(f"Tamaño: {len(crm_html)} caracteres")

if __name__ == '__main__':
    import sys
    dashboard_path = sys.argv[1] if len(sys.argv) > 1 else 'dashboard.html'
    output_path = sys.argv[2] if len(sys.argv) > 2 else 'crm.html'
    create_crm_html(dashboard_path, output_path)


