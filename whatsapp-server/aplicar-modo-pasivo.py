#!/usr/bin/env python3
"""
Aplicar modo pasivo de Baileys para evitar problemas de sincronización
"""

import re
import sys

FILE_PATH = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

def aplicar_cambios():
    print("🔄 Aplicando modo pasivo de Baileys...")
    
    try:
        with open(FILE_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return False
    
    # 1. Reemplazar configuración de makeWASocket con modo pasivo
    old_config = r'''    sock = makeWASocket\(\{
        auth: state,
        printQRInTerminal: true,
        version,
        browser: \['Chrome', 'Desktop', '1\.0\.0'\],.*?logger: \{
            level: 'silent',
            child: \(\) => \(\{ level: 'silent' \}\)
        \},.*?\}\);'''
    
    new_config = '''    sock = makeWASocket({
        auth: state,
        printQRInTerminal: true,
        version,
        browser: ['Chrome', 'Desktop', '1.0.0'],
        
        // MODO PASIVO - Desactiva sincronización del app state (evita timeouts)
        passive: true,
        
        // Timeouts normales (no tan largos porque no sincroniza)
        qrTimeout: 120000, // 2 minutos
        connectTimeoutMs: 300000, // 5 minutos (suficiente sin sincronización)
        defaultQueryTimeoutMs: 60000, // 1 minuto
        appStateSyncTimeoutMs: 0, // No aplica (modo pasivo no sincroniza)
        
        // Keep-alive normal
        keepAliveIntervalMs: 10000, // 10 segundos
        
        // Desactivar TODA la sincronización
        syncFullHistory: false,
        shouldSyncHistoryMessage: () => false,
        shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)
        fireInitQueries: false, // NO ejecutar queries iniciales (evita bloqueos)
        
        // Configuración básica
        markOnlineOnConnect: true,
        generateHighQualityLinkPreview: false,
        retryRequestDelayMs: 1000,
        maxMsgRetryCount: 3,
        shouldIgnoreJid: () => false,
        getMessage: async (key) => {
            return undefined; // No obtener mensajes antiguos
        },
        
        // Logger silencioso para mejor rendimiento
        logger: {
            level: 'silent',
            child: () => ({ level: 'silent' })
        },
    });'''
    
    # Buscar y reemplazar la configuración completa
    pattern = re.compile(
        r'    sock = makeWASocket\(\{.*?logger: \{\s*level: \'silent\',\s*child: \(\) => \(\{ level: \'silent\' \}\)\s*\},\s*// Nota:.*?\}\);',
        re.DOTALL
    )
    
    if not pattern.search(content):
        # Intentar patrón más simple
        pattern = re.compile(
            r'    sock = makeWASocket\(\{.*?logger: \{\s*level: \'silent\',\s*child: \(\) => \(\{ level: \'silent\' \}\)\s*\},.*?\}\);',
            re.DOTALL
        )
    
    if pattern.search(content):
        content = pattern.sub(new_config, content)
        print("✅ Configuración de makeWASocket actualizada")
    else:
        print("⚠️  No se encontró el patrón exacto, usando búsqueda más específica...")
        # Buscar línea por línea y reemplazar
        lines = content.split('\n')
        new_lines = []
        in_config = False
        config_start = -1
        brace_count = 0
        
        for i, line in enumerate(lines):
            if 'sock = makeWASocket({' in line:
                in_config = True
                config_start = i
                brace_count = line.count('{') - line.count('}')
                new_lines.append(line)
                continue
            
            if in_config:
                brace_count += line.count('{') - line.count('}')
                if brace_count == 0 and '});' in line:
                    # Fin de la configuración, insertar nueva
                    new_lines.append(new_config)
                    in_config = False
                    continue
                # Saltar líneas antiguas
                continue
            
            new_lines.append(line)
        
        if in_config:
            print("⚠️  No se pudo encontrar el final de la configuración")
            return False
        
        content = '\n'.join(new_lines)
        print("✅ Configuración reemplazada (método alternativo)")
    
    # 2. Actualizar manejo de conexión 'open' para modo pasivo
    old_connection = r'''            // Guardar timestamp de conexión
            connectionTimestamp = Date\.now\(\);
            
            // Marcar que estamos sincronizando app state \(puede tardar varios minutos\)
            isSyncingAppState = true;
            connectionStatus = 'syncing'; // Estado intermedio: conectado pero sincronizando
            console\.log\('🔄 Sincronizando estado de la aplicación \(esto puede tardar varios minutos\)\.\.\.'\);
            console\.log\('💡 Por favor, NO cierres WhatsApp en tu teléfono durante la sincronización'\);
            console\.log\('💡 La sincronización puede tardar hasta 15 minutos con conexiones lentas'\);'''
    
    new_connection = '''            // Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            // MODO PASIVO: No hay sincronización del app state
            // Marcar como completamente conectado inmediatamente
            isSyncingAppState = false;
            connectionStatus = 'open'; // Ya está completamente conectado (modo pasivo)
            console.log('💡 Modo pasivo activado - Sin sincronización de app state');
            console.log('✅ Conexión completa inmediata (más rápido, sin esperar sincronización)');'''
    
    content = re.sub(old_connection, new_connection, content, flags=re.DOTALL)
    
    # 3. Eliminar timeouts de sincronización y emitir conexión inmediatamente
    old_timeouts = r'''            // Esperar un tiempo antes de marcar como completamente conectado.*?console\.log\('✅ Evento de conexión emitido via Socket\.IO \(sincronizando\)'\);'''
    
    new_timeouts = '''            // MODO PASIVO: Emitir conexión inmediatamente (no hay sincronización)
            io.emit('connection', { 
                status: 'open', // Ya está completamente conectado
                phone: phoneNumber,
                name: phoneName
            });
            console.log('✅ Evento de conexión emitido via Socket.IO');'''
    
    content = re.sub(old_timeouts, new_timeouts, content, flags=re.DOTALL)
    
    # Guardar archivo
    try:
        with open(FILE_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        print("✅ Archivo actualizado correctamente")
        return True
    except Exception as e:
        print(f"❌ Error guardando archivo: {e}")
        return False

if __name__ == '__main__':
    if aplicar_cambios():
        print("\n✅ Cambios aplicados correctamente")
        print("📝 Ahora ejecuta: git add whatsapp-server/whatsapp-server-baileys.js && git commit -m '...' && git push")
        sys.exit(0)
    else:
        print("\n❌ Error aplicando cambios")
        sys.exit(1)
