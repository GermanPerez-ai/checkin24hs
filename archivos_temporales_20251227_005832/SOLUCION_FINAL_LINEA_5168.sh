#!/bin/bash
# Solución final para el SyntaxError en línea 5168

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Solucion final para SyntaxError linea 5168"
echo "=========================================="
echo ""

# Backup
cp dashboard.html "dashboard.html.backup_final_5168_$(date +%Y%m%d_%H%M%S)"
echo "Backup creado"
echo ""

# Ver línea 5168 exacta
echo "1. Verificando linea 5168 exacta..."
docker exec $(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1) sed -n '5168p' /app/dashboard.html | od -c | head -5
echo ""

# Corregir con Python de manera más agresiva
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

print("2. Corrigiendo SyntaxError en linea 5168...")

# Dividir en líneas
lines = content.split('\n')

if len(lines) > 5167:
    line_5168 = lines[5167]
    print(f"   Linea original (primeros 150 chars): {repr(line_5168[:150])}")
    
    # Estrategia agresiva: si hay un console.log problemático, comentarlo o simplificarlo
    if 'console.log' in line_5168:
        # Buscar el patrón console.log('...') y simplificarlo
        # Reemplazar cualquier console.log problemático con uno simple
        line_5168 = re.sub(
            r"console\.log\([^)]*\)",
            "console.log('Debug')",
            line_5168
        )
        print("   console.log simplificado")
    
    # Eliminar cualquier carácter no ASCII problemático excepto espacios y caracteres comunes
    # Mantener solo caracteres ASCII imprimibles y algunos caracteres comunes
    cleaned_line = ''
    for char in line_5168:
        # Mantener caracteres ASCII imprimibles (32-126) y algunos caracteres comunes
        if ord(char) < 128 or char in ['\n', '\t']:
            cleaned_line += char
        else:
            # Reemplazar caracteres no ASCII problemáticos con espacio
            cleaned_line += ' '
            print(f"   Eliminado caracter no ASCII: {repr(char)}")
    
    lines[5167] = cleaned_line
    print(f"   Linea corregida (primeros 150 chars): {repr(cleaned_line[:150])}")

# También verificar líneas alrededor por si hay problemas de contexto
for i in range(max(0, 5165), min(len(lines), 5175)):
    if i != 5167:  # Ya corregimos 5168
        line = lines[i]
        # Buscar caracteres problemáticos
        if any(ord(c) > 127 and c not in ['\n', '\t'] for c in line if c not in ['á', 'é', 'í', 'ó', 'ú', 'ñ', 'Á', 'É', 'Í', 'Ó', 'Ú', 'Ñ']):
            # Simplificar líneas problemáticas
            if 'console.log' in line:
                lines[i] = re.sub(r"console\.log\([^)]*\)", "console.log('Debug')", line)

content = '\n'.join(lines)

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

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
echo "Aplica al contenedor y prueba. Si el problema persiste,"
echo "procederemos a crear la pagina separada crm.checkin24hs.com"
echo ""


