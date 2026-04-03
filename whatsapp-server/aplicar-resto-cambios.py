#!/usr/bin/env python3
# Aplicar los cambios restantes de connectionTimestamp

import re

file_path = 'whatsapp-server/whatsapp-server-baileys.js'

# Leer el archivo
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Verificar si ya tiene connectionTimestamp = null (debe estar en línea 99)
has_connection_timestamp = any('connectionTimestamp = null' in line for line in lines)
print(f"connectionTimestamp = null: {'✅' if has_connection_timestamp else '❌'}")

# 2. Buscar dónde agregar la protección durante sincronización
# Buscar la línea con "if (isDeviceRemoved || statusCode === 401) {"
protection_added = False
for i, line in enumerate(lines):
    if 'if (isDeviceRemoved || statusCode === 401)' in line and 'minutesSinceConnection < 15' not in ''.join(lines[i:i+50]):
        # Insertar protección después de esta línea
        protection_code = '''                // Verificar si estamos sincronizando app state
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
                
'''
        lines.insert(i + 1, protection_code)
        protection_added = True
        print(f"✅ Protección durante sincronización agregada en línea {i+1}")
        break
    elif 'minutesSinceConnection < 15' in line:
        protection_added = True
        print("✅ Protección durante sincronización ya existe")
        break

if not protection_added:
    print("❌ No se encontró el lugar para agregar protección")

# 3. Agregar connectionTimestamp = Date.now() cuando se conecta
timestamp_set = False
for i, line in enumerate(lines):
    if "connectionStatus = 'open';" in line and 'connectionTimestamp = Date.now()' not in ''.join(lines[i:i+10]):
        # Insertar después de connectionStatus = 'open'
        lines.insert(i + 1, '            \n')
        lines.insert(i + 2, '            // Guardar timestamp de conexión\n')
        lines.insert(i + 3, '            connectionTimestamp = Date.now();\n')
        lines.insert(i + 4, '            \n')
        timestamp_set = True
        print(f"✅ connectionTimestamp = Date.now() agregado en línea {i+2}")
        break
    elif 'connectionTimestamp = Date.now()' in line:
        timestamp_set = True
        print("✅ connectionTimestamp = Date.now() ya existe")
        break

if not timestamp_set:
    print("❌ No se encontró el lugar para agregar connectionTimestamp = Date.now()")

# 4. Agregar reseteo de connectionTimestamp al limpiar sesión
reset_added = False
for i, line in enumerate(lines):
    if "Sesión limpiada completamente" in line and 'connectionTimestamp = null' not in ''.join(lines[i:i+5]):
        # Insertar después de esta línea
        lines.insert(i + 1, '                        connectionTimestamp = null; // Resetear timestamp de conexión\n')
        lines.insert(i + 2, '                        isSyncingAppState = false; // Resetear flag de sincronización\n')
        reset_added = True
        print(f"✅ Reseteo de connectionTimestamp agregado en línea {i+1}")
        break
    elif 'connectionTimestamp = null; // Resetear timestamp' in line:
        reset_added = True
        print("✅ Reseteo de connectionTimestamp ya existe")
        break

if not reset_added:
    print("❌ No se encontró el lugar para agregar reseteo")

# Escribir el archivo
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✅ Archivo actualizado")
