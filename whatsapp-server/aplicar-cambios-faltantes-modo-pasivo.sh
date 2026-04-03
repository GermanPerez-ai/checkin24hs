#!/bin/bash
# Aplicar cambios faltantes del modo pasivo

cd /root/checkin24hs
FILE="whatsapp-server/whatsapp-server-baileys.js"

echo "🔄 Aplicando cambios faltantes del modo pasivo..."

# Backup
cp "$FILE" "$FILE.backup-$(date +%s)"

# 1. Cambiar timeouts (si aún no están cambiados)
sed -i 's/connectTimeoutMs: 900000/connectTimeoutMs: 300000/g' "$FILE"
sed -i 's/defaultQueryTimeoutMs: 600000/defaultQueryTimeoutMs: 60000/g' "$FILE"
sed -i 's/defaultQueryTimeoutMs: 180000/defaultQueryTimeoutMs: 60000/g' "$FILE"
sed -i 's/appStateSyncTimeoutMs: 900000/appStateSyncTimeoutMs: 0/g' "$FILE"
sed -i 's/keepAliveIntervalMs: 5000/keepAliveIntervalMs: 10000/g' "$FILE"
sed -i 's/fireInitQueries: true/fireInitQueries: false/g' "$FILE"

# 2. Cambiar shouldSyncAppState usando Python (más confiable)
python3 << 'PYEOF'
import re

file_path = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Reemplazar shouldSyncAppState (función completa)
pattern = r"shouldSyncAppState: \(update\) => \{[^}]*\},"
replacement = "shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)"

if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    print("✅ shouldSyncAppState actualizado")
else:
    print("ℹ️  shouldSyncAppState ya está actualizado o no se encontró")

# Actualizar manejo de conexión 'open'
old_conn = r"// Guardar timestamp de conexión\s+connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando app state.*?console\.log\('💡 La sincronización puede tardar hasta 15 minutos.*?\);"
new_conn = """// Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            // MODO PASIVO: No hay sincronización del app state
            // Marcar como completamente conectado inmediatamente
            isSyncingAppState = false;
            connectionStatus = 'open'; // Ya está completamente conectado (modo pasivo)
            console.log('💡 Modo pasivo activado - Sin sincronización de app state');
            console.log('✅ Conexión completa inmediata (más rápido, sin esperar sincronización)');"""

if re.search(old_conn, content, re.DOTALL):
    content = re.sub(old_conn, new_conn, content, flags=re.DOTALL)
    print("✅ Manejo de conexión 'open' actualizado")
else:
    print("ℹ️  Manejo de conexión ya está actualizado o no se encontró")

# Eliminar timeouts de sincronización
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
    print("ℹ️  Timeouts de sincronización ya fueron eliminados o no se encontraron")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Cambios aplicados")
PYEOF

echo ""
echo "✅ Cambios aplicados"
echo ""
echo "📝 Verificar cambios:"
echo "   git diff $FILE | head -100"
echo ""
echo "📝 Luego hacer commit y push:"
echo "   git add $FILE"
echo "   git commit -m 'Fix: Completar modo pasivo - desactivar sincronización y timeouts'"
echo "   git push"
