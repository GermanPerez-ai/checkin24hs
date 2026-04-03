#!/bin/bash
# 🔧 Agregar variable qrExpirationTimer si no existe

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 AGREGANDO VARIABLE qrExpirationTimer"
echo "=============================================================="
echo ""

# Backup
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup2
echo "✅ Backup creado"
echo ""

# Verificar si la variable ya existe
if grep -q "let qrExpirationTimer\|var qrExpirationTimer\|const qrExpirationTimer" whatsapp-server/whatsapp-server-baileys.js; then
    echo "✅ La variable qrExpirationTimer ya existe"
    exit 0
fi

echo "⚠️  La variable qrExpirationTimer NO existe, agregándola..."
echo ""

# Buscar dónde están las otras variables globales (phoneNumber, connectionStatus, etc.)
VAR_LINE=$(grep -n "let phoneNumber\|let connectionStatus\|let qrCodeData" whatsapp-server/whatsapp-server-baileys.js | head -1 | cut -d: -f1)

if [ -z "$VAR_LINE" ]; then
    echo "❌ No se encontró dónde declarar la variable"
    exit 1
fi

echo "📍 Variables globales encontradas alrededor de la línea $VAR_LINE"
echo ""

# Usar Python para agregar la variable
python3 << 'PYEOF'
import re

file_path = 'whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Buscar dónde están las variables globales
var_insert_line = None
for i, line in enumerate(lines):
    if 'let phoneName' in line or 'let phoneNumber' in line:
        var_insert_line = i + 1
        break

if var_insert_line is None:
    print('❌ No se encontró dónde insertar la variable')
    exit(1)

# Verificar si ya existe
for line in lines:
    if 'qrExpirationTimer' in line and ('let ' in line or 'var ' in line or 'const ' in line):
        print('✅ La variable ya existe')
        exit(0)

# Insertar la variable después de phoneName o phoneNumber
new_lines = lines[:var_insert_line] + ['let qrExpirationTimer = null; // Timer para detectar QR expirado\n'] + lines[var_insert_line:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✅ Variable agregada después de la línea {var_insert_line}')
PYEOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Variable agregada"
    echo ""
    echo "Verificando..."
    if grep -q "let qrExpirationTimer" whatsapp-server/whatsapp-server-baileys.js; then
        echo "✅ Verificación exitosa"
    else
        echo "❌ Verificación falló"
        exit 1
    fi
else
    echo ""
    echo "❌ Error. Restaurando backup..."
    cp whatsapp-server/whatsapp-server-baileys.js.backup2 whatsapp-server/whatsapp-server-baileys.js
    exit 1
fi

echo ""
echo "✅ COMPLETADO"
echo ""
