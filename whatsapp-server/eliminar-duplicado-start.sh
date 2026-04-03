#!/bin/bash
# 🔧 Eliminar función start() duplicada

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 ELIMINANDO FUNCIÓN start() DUPLICADA"
echo "=============================================================="
echo ""

# Backup
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup3
echo "✅ Backup creado"
echo ""

# Usar Python para eliminar el duplicado
python3 << 'PYEOF'
file_path = 'whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Encontrar todas las funciones start
start_lines = []
for i, line in enumerate(lines):
    if 'async function start()' in line:
        start_lines.append(i)

print(f'Encontradas {len(start_lines)} funciones start() en líneas: {[l+1 for l in start_lines]}')

if len(start_lines) <= 1:
    print('✅ No hay duplicados')
    exit(0)

# Encontrar dónde termina la primera función start
first_start = start_lines[0]
second_start = start_lines[1]

# Buscar el final de la primera función (buscar el cierre del catch)
first_end = None
brace_count = 0
in_try = False

for i in range(first_start, min(second_start, len(lines))):
    line = lines[i]
    if 'try {' in line:
        in_try = True
        brace_count = 1
    elif in_try:
        brace_count += line.count('{') - line.count('}')
        if brace_count == 0 and '} catch' in line:
            # Buscar el cierre del catch
            for j in range(i + 1, min(second_start, len(lines))):
                if '}' in lines[j] and lines[j].strip() == '}':
                    first_end = j + 1
                    break
            break

if first_end is None:
    first_end = second_start

print(f'Primera función start: líneas {first_start+1} a {first_end}')
print(f'Segunda función start: línea {second_start+1}')

# Eliminar la segunda función start y todo hasta el final del archivo o hasta "// Manejar" o "process.on"
second_end = len(lines)
for i in range(second_start, len(lines)):
    if '// Manejar' in lines[i] or 'process.on' in lines[i]:
        second_end = i
        break

# Si hay un "start()" después, mantenerlo
has_start_call = False
for i in range(second_start, len(lines)):
    if 'start();' in lines[i] and i > second_end:
        second_end = i + 1
        has_start_call = True
        break

# Eliminar desde la segunda función start hasta antes de "// Manejar" o "process.on"
# Pero mantener "// Manejar", "process.on" y "start()"
new_lines = lines[:second_start]

# Agregar las líneas finales si existen
if second_end < len(lines):
    # Verificar si hay "// Manejar" o "process.on"
    for i in range(second_end, len(lines)):
        if '// Manejar' in lines[i] or 'process.on' in lines[i]:
            new_lines.extend(lines[i:])
            break
    else:
        # Si no hay, agregar las líneas finales estándar
        if not has_start_call:
            new_lines.extend([
                '\n',
                '// Manejar cierre limpio\n',
                "process.on('SIGINT', () => {\n",
                "    console.log('\\n🛑 Cerrando servidor...');\n",
                '    if (sock) {\n',
                '        sock.end();\n',
                '    }\n',
                '    process.exit(0);\n',
                '});\n',
                '\n',
                '// Iniciar\n',
                'start();\n'
            ])

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✅ Duplicado eliminado. Archivo ahora tiene {len(new_lines)} líneas')
PYEOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Duplicado eliminado"
    echo ""
    echo "Verificando..."
    START_COUNT=$(grep -c "async function start()" whatsapp-server/whatsapp-server-baileys.js)
    if [ "$START_COUNT" -eq 1 ]; then
        echo "✅ Solo hay una función start()"
    else
        echo "⚠️  Aún hay $START_COUNT funciones start()"
    fi
else
    echo ""
    echo "❌ Error. Restaurando backup..."
    cp whatsapp-server/whatsapp-server-baileys.js.backup3 whatsapp-server/whatsapp-server-baileys.js
    exit 1
fi

echo ""
echo "✅ COMPLETADO"
echo ""
