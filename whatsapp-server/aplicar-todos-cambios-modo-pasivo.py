#!/usr/bin/env python3
"""
Aplicar TODOS los cambios del modo pasivo de forma robusta
Busca múltiples variantes de los patrones para asegurar que se apliquen
"""

import re
import sys
from datetime import datetime

FILE_PATH = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

def aplicar_cambios():
    print("🔄 Aplicando TODOS los cambios del modo pasivo...")
    
    try:
        with open(FILE_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return False
    
    # Backup
    backup_path = f"{FILE_PATH}.backup-{int(datetime.now().timestamp())}"
    try:
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Backup creado: {backup_path}")
    except Exception as e:
        print(f"⚠️  No se pudo crear backup: {e}")
    
    cambios_aplicados = []
    
    # 1. Asegurar que passive: true esté presente
    if 'passive: true' not in content:
        content = re.sub(
            r"(browser: \['Chrome', 'Desktop', '1\.0\.0'\],)",
            r"\1\n        \n        // MODO PASIVO - Desactiva sincronización del app state (evita timeouts)\n        passive: true,",
            content
        )
        cambios_aplicados.append("passive: true agregado")
    else:
        cambios_aplicados.append("passive: true ya existe")
    
    # 2. Cambiar timeouts (múltiples variantes)
    if 'appStateSyncTimeoutMs: 0' not in content:
        content = re.sub(r'appStateSyncTimeoutMs: \d+', 'appStateSyncTimeoutMs: 0', content)
        cambios_aplicados.append("appStateSyncTimeoutMs: 0")
    
    if 'defaultQueryTimeoutMs: 60000' not in content:
        content = re.sub(r'defaultQueryTimeoutMs: \d+', 'defaultQueryTimeoutMs: 60000', content)
        cambios_aplicados.append("defaultQueryTimeoutMs: 60000")
    
    if 'keepAliveIntervalMs: 10000' not in content:
        content = re.sub(r'keepAliveIntervalMs: \d+', 'keepAliveIntervalMs: 10000', content)
        cambios_aplicados.append("keepAliveIntervalMs: 10000")
    
    if 'fireInitQueries: false' not in content:
        content = re.sub(r'fireInitQueries: true', 'fireInitQueries: false', content)
        cambios_aplicados.append("fireInitQueries: false")
    
    # 3. Reemplazar shouldSyncAppState (buscar múltiples variantes)
    patterns_should_sync = [
        r"shouldSyncAppState: \(update\) => \{[^}]*\},",  # Función completa
        r"shouldSyncAppState: \(update\) => \{[^}]*return true[^}]*\},",  # Con return true
        r"shouldSyncAppState: \(update\) => \{[^}]*return false[^}]*\},",  # Con return false
    ]
    
    replacement_should_sync = "shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)"
    
    for pattern in patterns_should_sync:
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, replacement_should_sync, content, flags=re.DOTALL)
            cambios_aplicados.append("shouldSyncAppState actualizado")
            break
    
    # 4. Actualizar manejo de conexión 'open' (buscar múltiples variantes)
    patterns_connection = [
        r"// Guardar timestamp de conexión\s+connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando app state.*?console\.log\('💡 La sincronización puede tardar hasta 15 minutos.*?\);",
        r"// Guardar timestamp.*?connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando.*?console\.log.*?sincronización.*?\);",
        r"connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando.*?console\.log.*?sincronización.*?\);",
    ]
    
    new_connection = """// Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            // MODO PASIVO: No hay sincronización del app state
            // Marcar como completamente conectado inmediatamente
            isSyncingAppState = false;
            connectionStatus = 'open'; // Ya está completamente conectado (modo pasivo)
            console.log('💡 Modo pasivo activado - Sin sincronización de app state');
            console.log('✅ Conexión completa inmediata (más rápido, sin esperar sincronización)');"""
    
    for pattern in patterns_connection:
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, new_connection, content, flags=re.DOTALL)
            cambios_aplicados.append("Manejo de conexión 'open' actualizado")
            break
    
    # 5. Eliminar timeouts de sincronización (buscar múltiples variantes)
    patterns_timeouts = [
        r"// Esperar un tiempo antes de marcar como completamente conectado.*?console\.log\('✅ Evento de conexión emitido via Socket\.IO \(sincronizando\)'\);",
        r"// Esperar un tiempo antes.*?setTimeout.*?sincronización.*?console\.log.*?sincronizando.*?\);",
        r"setTimeout.*?sincronización.*?console\.log.*?sincronizando.*?\);",
    ]
    
    new_timeouts = """// MODO PASIVO: Emitir conexión inmediatamente (no hay sincronización)
            io.emit('connection', { 
                status: 'open', // Ya está completamente conectado
                phone: phoneNumber,
                name: phoneName
            });
            console.log('✅ Evento de conexión emitido via Socket.IO');"""
    
    for pattern in patterns_timeouts:
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, new_timeouts, content, flags=re.DOTALL)
            cambios_aplicados.append("Timeouts de sincronización eliminados")
            break
    
    # Guardar archivo
    try:
        with open(FILE_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Archivo actualizado: {FILE_PATH}")
        print(f"\n📋 Cambios aplicados:")
        for cambio in cambios_aplicados:
            print(f"   - {cambio}")
        return True
    except Exception as e:
        print(f"❌ Error guardando archivo: {e}")
        return False

if __name__ == '__main__':
    if aplicar_cambios():
        print("\n✅ Cambios aplicados correctamente")
        print("\n📝 Próximos pasos:")
        print("   1. Verificar: git diff whatsapp-server/whatsapp-server-baileys.js | head -150")
        print("   2. Agregar: git add whatsapp-server/whatsapp-server-baileys.js")
        print("   3. Commit: git commit -m 'Fix: Completar modo pasivo - todos los cambios'")
        print("   4. Push: git push")
        sys.exit(0)
    else:
        print("\n❌ Error aplicando cambios")
        sys.exit(1)
