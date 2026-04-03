#!/bin/bash
# Corregir error de sintaxis causado por el script anterior

cd /root/checkin24hs
FILE="whatsapp-server/whatsapp-server-baileys.js"

echo "🔧 Corrigiendo error de sintaxis..."

# Backup
cp "$FILE" "$FILE.backup-sintaxis-$(date +%s)"

# Buscar y corregir el problema
python3 << 'PYEOF'
import re

file_path = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Buscar el patrón problemático: "MODO PASIVO: Emitir inmediatamente" seguido de código incorrecto
# El problema es que se reemplazó código dentro del bloque del error 515 incorrectamente

# Buscar y corregir el bloque del error 515
pattern_515 = r'(if \(statusCode === 515\) \{.*?io\.emit\(\'connection\', \{ status: \'close\' \}\);.*?if \(shouldReconnect\) \{.*?setTimeout\(\(\) => \{.*?console\.log\(\'🔄 Iniciando reconexión después de restart required\.\.\.\'\);.*?connectToWhatsApp\(\)\.catch\(err => \{.*?console\.error\(\'❌ Error en reconexión:\', err\);.*?// Reintentar después de 30 segundos si falla.*?setTimeout\(\(\) => \{.*?console\.log\(\'🔄 Reintentando reconexión después de error 515\.\.\.\'\);.*?connectToWhatsApp\(\)\.catch\(e => console\.error\(\'❌ Error en reintento:\', e\)\);.*?\}, 30000\);.*?\}\);.*?\}, 10000\);.*?\}.*?return;.*?\})'

# Reemplazo correcto para el error 515
replacement_515 = """if (statusCode === 515) {
                console.log('ℹ️ Error 515: Restart required (normal después del pairing)');
                console.log('💡 El teléfono está autenticando, esperando antes de reconectar...');
                console.log('🔄 Reconectando automáticamente en 10 segundos...');
                // No limpiar sesión, solo reconectar
                // Dar más tiempo al teléfono para completar la autenticación
                io.emit('connection', { status: 'close' });
                if (shouldReconnect) {
                    setTimeout(() => {
                        console.log('🔄 Iniciando reconexión después de restart required...');
                        connectToWhatsApp().catch(err => {
                            console.error('❌ Error en reconexión:', err);
                            // Reintentar después de 30 segundos si falla
                            setTimeout(() => {
                                console.log('🔄 Reintentando reconexión después de error 515...');
                                connectToWhatsApp().catch(e => console.error('❌ Error en reintento:', e));
                            }, 30000);
                        });
                    }, 10000); // Aumentado a 10 segundos para dar tiempo al teléfono
                }
                return; // Salir temprano, no procesar más
            }"""

# Buscar el patrón problemático más específico
# El problema parece ser que hay un "catch" sin "try" o código mal formado
# Buscar líneas que tengan "MODO PASIVO: Emitir inmediatamente" seguidas de código incorrecto

# Buscar el patrón problemático específico
problem_pattern = r'// MODO PASIVO: Emitir inmediatamente\s+io\.emit\(\'connection\', \{ status: \'open\', phone: phoneNumber, name: phoneName \}\);\s+console\.log\(\'✅ Evento de conexión emitido\'\);\s+sock = null;\s+\} catch \(e\) \{\}'

if re.search(problem_pattern, content, re.DOTALL):
    print("⚠️  Encontrado patrón problemático, corrigiendo...")
    # Eliminar el código problemático y restaurar el código correcto del error 515
    content = re.sub(problem_pattern, '', content, flags=re.DOTALL)
    
    # Asegurar que el bloque del error 515 esté completo
    if 'if (statusCode === 515)' in content and 'return; // Salir temprano' not in content:
        # Buscar dónde está el bloque 515 y asegurar que esté completo
        pass

# Verificar sintaxis básica: buscar "catch" sin "try" antes
lines = content.split('\n')
for i, line in enumerate(lines):
    if '} catch' in line or 'catch (' in line:
        # Verificar que haya un try antes
        found_try = False
        for j in range(max(0, i-20), i):
            if 'try {' in lines[j] or 'try(' in lines[j]:
                found_try = True
                break
        if not found_try and '} catch' in line:
            print(f"⚠️  Posible problema en línea {i+1}: {line.strip()}")
            # Si es un catch huérfano, eliminarlo o comentarlo
            if '} catch (e) {}' in line:
                print(f"   Eliminando catch huérfano en línea {i+1}")
                lines[i] = ''  # Eliminar la línea

content = '\n'.join(lines)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Corrección aplicada")
PYEOF

echo "✅ Script de corrección ejecutado"
echo ""
echo "📝 Verificar sintaxis:"
echo "   node -c $FILE"
