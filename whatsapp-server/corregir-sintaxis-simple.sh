#!/bin/bash
# Corregir error de sintaxis - versión simple

cd /root/checkin24hs
FILE="whatsapp-server/whatsapp-server-baileys.js"

echo "🔧 Corrigiendo error de sintaxis..."

# Backup
cp "$FILE" "$FILE.backup-$(date +%s)"

# Buscar y eliminar líneas problemáticas
# El problema es que hay un "catch" sin su "try" correspondiente
# Buscar el patrón problemático y corregirlo

python3 << 'PYEOF'
import re

file_path = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Buscar el problema: líneas que tienen "MODO PASIVO: Emitir inmediatamente" 
# seguidas de código incorrecto que deja un catch huérfano
new_lines = []
skip_next_catch = False
i = 0

while i < len(lines):
    line = lines[i]
    
    # Si encontramos el patrón problemático
    if 'MODO PASIVO: Emitir inmediatamente' in line:
        # Verificar las siguientes líneas
        if i + 1 < len(lines) and 'io.emit' in lines[i + 1]:
            if i + 2 < len(lines) and 'console.log' in lines[i + 2]:
                if i + 3 < len(lines) and 'sock = null' in lines[i + 3]:
                    if i + 4 < len(lines) and '} catch (e) {}' in lines[i + 4]:
                        # Este es el patrón problemático - eliminar estas líneas
                        print(f"⚠️  Eliminando código problemático en línea {i+1}")
                        i += 5  # Saltar estas líneas
                        continue
    
    # Si encontramos un catch huérfano (sin try antes)
    if '} catch (e) {}' in line or '} catch(e) {}' in line:
        # Verificar si hay un try en las 20 líneas anteriores
        found_try = False
        for j in range(max(0, i-20), i):
            if 'try {' in lines[j] or 'try(' in lines[j]:
                found_try = True
                break
        
        if not found_try:
            print(f"⚠️  Eliminando catch huérfano en línea {i+1}: {line.strip()}")
            i += 1
            continue
    
    new_lines.append(line)
    i += 1

# Escribir el archivo corregido
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ Corrección aplicada")
PYEOF

echo ""
echo "📝 Verificando sintaxis..."
if node -c "$FILE" 2>&1; then
    echo "✅ Sintaxis correcta"
else
    echo "❌ Aún hay errores de sintaxis"
    echo "   Revisar manualmente el archivo"
fi
