#!/usr/bin/env python3
"""
Aplicar modo pasivo de Baileys directamente en el servidor
Ejecutar: python3 aplicar-modo-pasivo-completo.py
"""

import re
import sys
from datetime import datetime

FILE_PATH = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

def aplicar_cambios():
    print("🔄 Aplicando modo pasivo de Baileys...")
    
    try:
        with open(FILE_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return False
    
    # Crear backup
    backup_path = f"{FILE_PATH}.backup-{int(datetime.now().timestamp())}"
    try:
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Backup creado: {backup_path}")
    except Exception as e:
        print(f"⚠️  No se pudo crear backup: {e}")
    
    # 1. Agregar passive: true después de browser
    if 'passive: true' not in content:
        content = re.sub(
            r"(browser: \['Chrome', 'Desktop', '1\.0\.0'\],)",
            r"\1\n        \n        // MODO PASIVO - Desactiva sincronización del app state (evita timeouts)\n        passive: true,",
            content
        )
        print("✅ Agregado passive: true")
    else:
        print("ℹ️  passive: true ya existe")
    
    # 2. Cambiar timeouts
    content = re.sub(r'connectTimeoutMs: 900000', 'connectTimeoutMs: 300000', content)
    content = re.sub(r'defaultQueryTimeoutMs: 600000', 'defaultQueryTimeoutMs: 60000', content)
    content = re.sub(r'appStateSyncTimeoutMs: 900000', 'appStateSyncTimeoutMs: 0', content)
    content = re.sub(r'keepAliveIntervalMs: 5000', 'keepAliveIntervalMs: 10000', content)
    content = re.sub(r'fireInitQueries: true', 'fireInitQueries: false', content)
    print("✅ Timeouts actualizados")
    
    # 3. Reemplazar shouldSyncAppState (función completa)
    pattern_should_sync = r"shouldSyncAppState: \(update\) => \{[^}]*\},"
    replacement_should_sync = "shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)"
    
    if re.search(pattern_should_sync, content, re.DOTALL):
        content = re.sub(pattern_should_sync, replacement_should_sync, content, flags=re.DOTALL)
        print("✅ shouldSyncAppState actualizado")
    else:
        print("⚠️  No se encontró shouldSyncAppState para reemplazar")
    
    # 4. Actualizar manejo de conexión 'open'
    old_connection = r"// Guardar timestamp de conexión\s+connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando app state.*?console\.log\('💡 La sincronización puede tardar hasta 15 minutos con conexiones lentas'\);"
    new_connection = """// Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            // MODO PASIVO: No hay sincronización del app state
            // Marcar como completamente conectado inmediatamente
            isSyncingAppState = false;
            connectionStatus = 'open'; // Ya está completamente conectado (modo pasivo)
            console.log('💡 Modo pasivo activado - Sin sincronización de app state');
            console.log('✅ Conexión completa inmediata (más rápido, sin esperar sincronización)');"""
    
    if re.search(old_connection, content, re.DOTALL):
        content = re.sub(old_connection, new_connection, content, flags=re.DOTALL)
        print("✅ Manejo de conexión 'open' actualizado")
    else:
        print("⚠️  No se encontró el patrón de conexión para reemplazar")
    
    # 5. Reemplazar timeouts de sincronización con emisión inmediata
    old_timeouts = r"// Esperar un tiempo antes de marcar como completamente conectado.*?console\.log\('✅ Evento de conexión emitido via Socket\.IO \(sincronizando\)'\);"
    new_timeouts = """// MODO PASIVO: Emitir conexión inmediatamente (no hay sincronización)
            io.emit('connection', { 
                status: 'open', // Ya está completamente conectado
                phone: phoneNumber,
                name: phoneName
            });
            console.log('✅ Evento de conexión emitido via Socket.IO');"""
    
    if re.search(old_timeouts, content, re.DOTALL):
        content = re.sub(old_timeouts, new_timeouts, content, flags=re.DOTALL)
        print("✅ Timeouts de sincronización eliminados")
    else:
        print("⚠️  No se encontraron timeouts de sincronización para reemplazar")
    
    # Guardar archivo
    try:
        with open(FILE_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Archivo actualizado: {FILE_PATH}")
        return True
    except Exception as e:
        print(f"❌ Error guardando archivo: {e}")
        return False

if __name__ == '__main__':
    if aplicar_cambios():
        print("\n✅ Cambios aplicados correctamente")
        print("\n📝 Próximos pasos:")
        print("   1. Verificar cambios: git diff whatsapp-server/whatsapp-server-baileys.js | head -100")
        print("   2. Agregar: git add whatsapp-server/whatsapp-server-baileys.js")
        print("   3. Commit: git commit -m 'Fix: Modo pasivo de Baileys'")
        print("   4. Push: git push")
        sys.exit(0)
    else:
        print("\n❌ Error aplicando cambios")
        sys.exit(1)
