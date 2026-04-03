#!/bin/bash
# Script para corregir el SyntaxError en la línea 5168

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Corrigiendo SyntaxError en linea 5168"
echo "=========================================="
echo ""

# Backup
cp dashboard.html "dashboard.html.backup_antes_linea5168_$(date +%Y%m%d_%H%M%S)"
echo "Backup creado"
echo ""

# Verificar línea 5168
echo "1. Verificando linea 5168..."
sed -n '5165,5175p' dashboard.html | cat -n
echo ""

# Corregir con Python
echo "2. Corrigiendo error..."
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("   Buscando y corrigiendo problemas en linea 5168...")

# Verificar línea 5168 (índice 5167)
if len(lines) > 5167:
    line_5168 = lines[5167]  # Índice 0-based
    print(f"   Linea 5168 original: {repr(line_5168[:100])}")
    
    # Buscar caracteres problemáticos o errores comunes
    # Caracteres no válidos en JavaScript
    problematic_chars = ['\u2028', '\u2029']  # Line/Paragraph separators
    for char in problematic_chars:
        if char in line_5168:
            line_5168 = line_5168.replace(char, ' ')
            print(f"   Eliminado caracter problemático: {repr(char)}")
    
    # Buscar comillas incorrectas o caracteres especiales
    # Reemplazar comillas curvas por comillas rectas
    line_5168 = line_5168.replace(''', "'").replace(''', "'")
    line_5168 = line_5168.replace('"', '"').replace('"', '"')
    
    # Buscar posibles problemas de sintaxis comunes
    # Si hay un console.log con caracteres raros
    if 'console.log' in line_5168:
        # Asegurar que las comillas estén balanceadas
        single_quotes = line_5168.count("'") - line_5168.count("\\'")
        double_quotes = line_5168.count('"') - line_5168.count('\\"')
        if single_quotes % 2 != 0 or double_quotes % 2 != 0:
            print("   ADVERTENCIA: Comillas desbalanceadas detectadas")
            # Intentar corregir
            if single_quotes % 2 != 0:
                line_5168 = line_5168.replace("'", "'", 1)  # Reemplazar primera comilla problemática
    
    lines[5167] = line_5168
    print(f"   Linea 5168 corregida: {repr(line_5168[:100])}")

# También buscar y corregir cualquier otro problema similar en el archivo
print("   Buscando otros problemas similares...")
for i, line in enumerate(lines):
    # Buscar caracteres problemáticos
    if any(char in line for char in ['\u2028', '\u2029']):
        lines[i] = line.replace('\u2028', ' ').replace('\u2029', ' ')
        print(f"   Corregido caracter problemático en linea {i+1}")

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("")
print("Correcciones aplicadas")
PYTHON_EOF

echo ""
echo "3. Verificando correccion..."
sed -n '5165,5175p' dashboard.html | cat -n
echo ""

echo "=========================================="
echo "Correccion aplicada"
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


