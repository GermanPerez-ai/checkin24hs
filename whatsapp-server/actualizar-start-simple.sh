#!/bin/bash
# 🔧 Actualizar función start() en el servidor (versión simple)

echo "=============================================================="
echo "🔧 ACTUALIZANDO FUNCIÓN start()"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# Verificar que el archivo existe
if [ ! -f "whatsapp-server/whatsapp-server-baileys.js" ]; then
    echo "❌ Archivo no encontrado"
    exit 1
fi

# Hacer backup
echo "1️⃣  Creando backup..."
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)
echo "   ✅ Backup creado"
echo ""

# Buscar la línea donde empieza la función start
START_LINE=$(grep -n "^async function start()" whatsapp-server/whatsapp-server-baileys.js | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    echo "❌ No se encontró la función start()"
    exit 1
fi

echo "2️⃣  Función start() encontrada en línea $START_LINE"
echo ""

# Buscar dónde termina la función (buscar el cierre del try-catch)
# Buscar la línea con "    } catch" o "} catch" después de start
END_LINE=$(sed -n "${START_LINE},$"p whatsapp-server/whatsapp-server-baileys.js | grep -n "} catch\|^}" | head -1 | cut -d: -f1)
END_LINE=$((START_LINE + END_LINE))

# Verificar que encontramos el final
if [ -z "$END_LINE" ] || [ "$END_LINE" -le "$START_LINE" ]; then
    echo "⚠️  No se pudo determinar el final de la función"
    echo "   Mostrando líneas alrededor de start():"
    sed -n "$((START_LINE - 2)),$((START_LINE + 20))p" whatsapp-server/whatsapp-server-baileys.js
    exit 1
fi

echo "3️⃣  Función termina aproximadamente en línea $END_LINE"
echo ""

# Crear archivo Python temporal para hacer el reemplazo de forma más segura
PYTHON_SCRIPT=$(mktemp)
cat > "$PYTHON_SCRIPT" << 'PYEOF'
import sys
import re

file_path = sys.argv[1]
start_line = int(sys.argv[2])

# Leer el archivo
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Nuevo código de la función start
new_start_code = """async function start() {
    try {
        // Limpiar QR y estado al iniciar (por si hay un QR viejo en memoria)
        qrCodeData = null;
        connectionStatus = 'close';
        if (qrExpirationTimer) {
            clearTimeout(qrExpirationTimer);
            qrExpirationTimer = null;
        }
        
        // Iniciar servidor HTTP PRIMERO (antes de conectar WhatsApp)
        // Esto asegura que el servidor esté disponible incluso si WhatsApp tarda en conectar
        server.listen(CONFIG.PORT, '0.0.0.0', () => {
            console.log(`✅ Servidor iniciado en puerto ${CONFIG.PORT}`);
            console.log(`📱 Instancia WhatsApp: ${CONFIG.INSTANCE_NUMBER}`);
            console.log(`🌐 Servidor escuchando en 0.0.0.0:${CONFIG.PORT} (accesible desde cualquier interfaz)`);
            if (CONFIG.BASE_URL) {
                console.log(`🔗 URL base configurada: ${CONFIG.BASE_URL}`);
            }
            console.log(`📋 Endpoints disponibles:`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/health`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/status`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/qr`);
        });

        // Conectar a WhatsApp (después de iniciar el servidor)
        // Esto se hace en segundo plano para no bloquear el servidor HTTP
        connectToWhatsApp().catch(error => {
            console.error('❌ Error conectando a WhatsApp:', error);
            // El servidor HTTP seguirá funcionando aunque WhatsApp falle
        });
    } catch (error) {
        console.error('❌ Error iniciando servidor:', error);
        process.exit(1);
    }
}
"""

# Encontrar el final real de la función (buscar el cierre del try-catch)
end_line = start_line
in_try = False
brace_count = 0

for i in range(start_line - 1, len(lines)):
    line = lines[i]
    if 'try {' in line:
        in_try = True
        brace_count = 1
    elif in_try:
        brace_count += line.count('{') - line.count('}')
        if brace_count == 0 and '} catch' in line:
            end_line = i + 1
            # Buscar el cierre del catch
            for j in range(i + 1, len(lines)):
                if '}' in lines[j] and lines[j].strip() == '}':
                    end_line = j + 1
                    break
            break

# Si no encontramos el final, usar un rango aproximado
if end_line == start_line:
    end_line = start_line + 20

# Reemplazar las líneas
new_lines = lines[:start_line - 1] + [new_start_code + '\n'] + lines[end_line:]

# Escribir el archivo
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"✅ Archivo actualizado: reemplazadas líneas {start_line} a {end_line}")
PYEOF

# Ejecutar el script Python
echo "4️⃣  Aplicando cambios..."
python3 "$PYTHON_SCRIPT" whatsapp-server/whatsapp-server-baileys.js "$START_LINE" 2>&1

if [ $? -eq 0 ]; then
    echo "   ✅ Cambios aplicados"
else
    echo "   ⚠️  Error aplicando cambios con Python, intentando método alternativo..."
    # Método alternativo más simple con sed
    # Esto es más riesgoso pero puede funcionar
    exit 1
fi

# Limpiar
rm -f "$PYTHON_SCRIPT"

# Verificar
echo ""
echo "5️⃣  Verificando cambios..."
if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ El archivo tiene el código actualizado"
else
    echo "   ⚠️  No se pudo verificar el cambio"
fi
echo ""

echo "=============================================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=============================================================="
echo ""
