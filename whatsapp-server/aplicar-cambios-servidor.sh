#!/bin/bash
# 🔧 Aplicar cambios de connectionTimestamp directamente en el servidor

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 APLICANDO CAMBIOS EN EL SERVIDOR"
echo "=============================================================="
echo ""

# Backup
BACKUP_FILE="whatsapp-server/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)"
cp whatsapp-server/whatsapp-server-baileys.js "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Usar Python para aplicar los cambios
python3 << 'PYTHON_EOF'
import re

file_path = 'whatsapp-server/whatsapp-server-baileys.js'

# Leer el archivo
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Agregar connectionTimestamp después de isSyncingAppState
if 'let connectionTimestamp = null' not in content:
    # Buscar la línea con isSyncingAppState
    pattern1 = r'(let isSyncingAppState = false;.*?\n)'
    replacement1 = r'\1let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente\n'
    content = re.sub(pattern1, replacement1, content, flags=re.DOTALL)
    print("✅ connectionTimestamp agregado")
else:
    print("✅ connectionTimestamp ya existe")

# 2. Agregar protección durante sincronización (buscar el bloque de isDeviceRemoved)
if 'minutesSinceConnection < 15' not in content:
    # Buscar el bloque donde se maneja isDeviceRemoved
    pattern2 = r'(if \(isDeviceRemoved \|\| statusCode === 401\) \{)\s*(console\.log\(\'⚠️ Sesión conflictiva detectada)'
    replacement2 = r'''\1
                // Verificar si estamos sincronizando app state
                // Si es así, puede ser un falso positivo - la sincronización puede tardar mucho
                if (isSyncingAppState || connectionStatus === 'syncing' || (connectionTimestamp && phoneNumber)) {
                    const timeSinceConnection = connectionTimestamp ? Date.now() - connectionTimestamp : 0;
                    const minutesSinceConnection = Math.round(timeSinceConnection / 60000);
                    const secondsSinceConnection = Math.round(timeSinceConnection / 1000);
                    
                    // Si la conexión ocurrió hace menos de 15 minutos, proteger la sesión
                    // (la sincronización puede tardar mucho tiempo)
                    if (minutesSinceConnection < 15 && secondsSinceConnection > 30) {
                        console.log('⚠️ Error durante sincronización del app state');
                        console.log(`💡 Tiempo desde conexión: ${minutesSinceConnection} minutos, ${secondsSinceConnection % 60} segundos`);
                        console.log('💡 Esto puede ser normal - la sincronización puede tardar varios minutos');
                        console.log('💡 Esperando más tiempo antes de considerar que es un error real...');
                        console.log('🔄 Reconectando sin limpiar sesión (puede ser solo un timeout de sincronización)...');
                        
                        // Reconectar sin limpiar sesión si estamos sincronizando
                        if (sock) {
                            try {
                                sock.end().catch(() => {});
                                sock = null;
                            } catch (e) {}
                        }
                        
                        // Reconectar después de un tiempo
                        setTimeout(() => {
                            console.log('🔄 Reconectando después de error durante sincronización...');
                            connectToWhatsApp().catch(err => {
                                console.error('❌ Error reconectando:', err);
                            });
                        }, 5000);
                        
                        return; // Salir sin limpiar sesión
                    }
                }
                
                \2'''
    content = re.sub(pattern2, replacement2, content, flags=re.DOTALL)
    print("✅ Protección durante sincronización agregada")
else:
    print("✅ Protección durante sincronización ya existe")

# 3. Agregar connectionTimestamp = Date.now() cuando se conecta
if 'connectionTimestamp = Date.now()' not in content:
    # Buscar donde se marca como 'open'
    pattern3 = r'(connectionStatus = \'open\';)\s*(console\.log\(\'\'\s*console\.log\(\'═══════════════════════════════════════════════════════════\')'
    replacement3 = r'''\1
            
            // Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            \2'''
    content = re.sub(pattern3, replacement3, content, flags=re.DOTALL)
    print("✅ connectionTimestamp = Date.now() agregado")
else:
    print("✅ connectionTimestamp = Date.now() ya existe")

# 4. Agregar reseteo de connectionTimestamp al limpiar sesión
if 'connectionTimestamp = null; // Resetear timestamp' not in content:
    # Buscar donde se limpia la sesión
    pattern4 = r'(console\.log\(\'✅ Sesión limpiada completamente\. Se generará un nuevo QR code\.\'\);)\s*(qrCodeData = null;)'
    replacement4 = r'''\1
                        connectionTimestamp = null; // Resetear timestamp de conexión
                        isSyncingAppState = false; // Resetear flag de sincronización
                        \2'''
    content = re.sub(pattern4, replacement4, content, flags=re.DOTALL)
    print("✅ Reseteo de connectionTimestamp agregado")
else:
    print("✅ Reseteo de connectionTimestamp ya existe")

# Escribir el archivo
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Archivo actualizado")
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CAMBIOS APLICADOS"
    echo ""
    echo "Verificando cambios..."
    if grep -q "connectionTimestamp = null" whatsapp-server/whatsapp-server-baileys.js; then
        echo "   ✅ connectionTimestamp encontrado"
        grep -n "connectionTimestamp = null" whatsapp-server/whatsapp-server-baileys.js | head -1
    else
        echo "   ❌ connectionTimestamp NO encontrado"
        echo "   Restaurando backup..."
        cp "$BACKUP_FILE" whatsapp-server/whatsapp-server-baileys.js
        exit 1
    fi
    echo ""
    echo "📤 Ahora puedes hacer commit y push:"
    echo "   git add whatsapp-server/whatsapp-server-baileys.js"
    echo "   git commit -m 'Fix: Proteger sesión durante sincronización app state'"
    echo "   git push"
else
    echo ""
    echo "❌ Error aplicando cambios"
    echo "   Restaurando backup..."
    cp "$BACKUP_FILE" whatsapp-server/whatsapp-server-baileys.js
    exit 1
fi
