#!/usr/bin/env python3
# -*- coding: utf-8 -*-

file_path = "deploy/dashboard.html"
print("🔍 Verificando sintaxis alrededor de línea 21403...")

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Verificar líneas alrededor de 21403
start = max(0, 21400 - 5)
end = min(len(lines), 21410)

print(f"\n📋 Líneas {start+1} a {end}:")
for i in range(start, end):
    line = lines[i]
    # Buscar caracteres problemáticos
    if '<' in line and 'script' not in line.lower() and 'html' not in line.lower() and 'console' not in line.lower():
        print(f"⚠️ Línea {i+1} tiene '<' sospechoso: {line.strip()[:100]}")
    else:
        print(f"✅ Línea {i+1}: {line.strip()[:80]}")

# Verificar si hay problemas de cierre de funciones
print("\n🔍 Verificando balance de llaves alrededor de updateWhatsAppStatus...")
in_function = False
brace_count = 0
start_line = None

for i, line in enumerate(lines):
    if 'window.updateWhatsAppStatus' in line:
        in_function = True
        start_line = i
        print(f"✅ Función encontrada en línea {i+1}")
        break

if start_line:
    brace_count = 0
    for i in range(start_line, min(start_line + 200, len(lines))):
        line = lines[i]
        brace_count += line.count('{') - line.count('}')
        if brace_count == 0 and '};' in line and i > start_line + 10:
            print(f"✅ Función cerrada correctamente en línea {i+1}")
            break
    else:
        print(f"⚠️ Función no cerrada correctamente (balance: {brace_count})")

# Verificar si hay múltiples declaraciones de variables
print("\n🔍 Verificando declaraciones duplicadas...")
duplicates = {}
for i, line in enumerate(lines):
    if 'const SUPABASE_CONFIG' in line or 'let SUPABASE_CONFIG' in line or 'var SUPABASE_CONFIG' in line:
        if 'SUPABASE_CONFIG' not in duplicates:
            duplicates['SUPABASE_CONFIG'] = []
        duplicates['SUPABASE_CONFIG'].append(i+1)
    
    if 'const currentSection' in line or 'let currentSection' in line or 'var currentSection' in line:
        if 'currentSection' not in duplicates:
            duplicates['currentSection'] = []
        duplicates['currentSection'].append(i+1)
    
    if 'const flexiPrograms' in line or 'let flexiPrograms' in line or 'var flexiPrograms' in line:
        if 'flexiPrograms' not in duplicates:
            duplicates['flexiPrograms'] = []
        duplicates['flexiPrograms'].append(i+1)

if duplicates:
    print("⚠️ Variables declaradas múltiples veces:")
    for var, lines_list in duplicates.items():
        if len(lines_list) > 1:
            print(f"  {var}: líneas {lines_list}")
else:
    print("✅ No se encontraron declaraciones duplicadas obvias")


