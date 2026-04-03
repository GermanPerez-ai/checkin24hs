#!/bin/bash
# Restaurar código correcto y aplicar modo pasivo correctamente

cd /root/checkin24hs
FILE="whatsapp-server/whatsapp-server-baileys.js"

echo "🔄 Restaurando código correcto y aplicando modo pasivo..."
echo ""

# 1. Hacer backup del archivo actual
echo "1️⃣  Creando backup..."
cp "$FILE" "$FILE.backup-roto-$(date +%s)"
echo "✅ Backup creado"
echo ""

# 2. Restaurar desde el commit anterior (antes del cambio problemático)
echo "2️⃣  Restaurando desde commit anterior..."
# Buscar el commit antes del problemático
COMMIT_ANTERIOR=$(git log --oneline whatsapp-server/whatsapp-server-baileys.js | grep -v "Completar modo pasivo" | head -1 | cut -d' ' -f1)
if [ -z "$COMMIT_ANTERIOR" ]; then
    # Si no encontramos, usar HEAD~2 (2 commits atrás)
    COMMIT_ANTERIOR="HEAD~2"
fi

echo "   Restaurando desde commit: $COMMIT_ANTERIOR"
git checkout "$COMMIT_ANTERIOR" -- "$FILE"
echo "✅ Archivo restaurado"
echo ""

# 3. Verificar que el archivo esté correcto
echo "3️⃣  Verificando sintaxis..."
if node -c "$FILE" 2>&1; then
    echo "✅ Sintaxis correcta"
else
    echo "❌ Aún hay errores de sintaxis, restaurando desde HEAD~3..."
    git checkout HEAD~3 -- "$FILE"
    node -c "$FILE" && echo "✅ Sintaxis correcta" || echo "❌ Error persistente"
fi
echo ""

# 4. Aplicar modo pasivo correctamente
echo "4️⃣  Aplicando modo pasivo correctamente..."
python3 << 'PYEOF'
import re
from datetime import datetime

file_path = '/root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Backup antes de cambios
backup_path = f"{file_path}.backup-antes-modo-pasivo-{int(datetime.now().timestamp())}"
with open(backup_path, 'w', encoding='utf-8') as f:
    f.write(content)
print(f"✅ Backup creado: {backup_path}")

cambios = []

# 1. Agregar passive: true después de browser
if 'passive: true' not in content:
    content = re.sub(
        r"(browser: \['Chrome', 'Desktop', '1\.0\.0'\],)",
        r"\1\n        \n        // MODO PASIVO - Desactiva sincronización del app state (evita timeouts)\n        passive: true,",
        content
    )
    cambios.append("passive: true agregado")
else:
    cambios.append("passive: true ya existe")

# 2. Cambiar timeouts
if 'appStateSyncTimeoutMs: 0' not in content:
    content = re.sub(r'appStateSyncTimeoutMs: \d+', 'appStateSyncTimeoutMs: 0', content)
    cambios.append("appStateSyncTimeoutMs: 0")

if 'defaultQueryTimeoutMs: 60000' not in content:
    content = re.sub(r'defaultQueryTimeoutMs: \d+', 'defaultQueryTimeoutMs: 60000', content)
    cambios.append("defaultQueryTimeoutMs: 60000")

if 'keepAliveIntervalMs: 10000' not in content:
    content = re.sub(r'keepAliveIntervalMs: \d+', 'keepAliveIntervalMs: 10000', content)
    cambios.append("keepAliveIntervalMs: 10000")

if 'fireInitQueries: false' not in content:
    content = re.sub(r'fireInitQueries: true', 'fireInitQueries: false', content)
    cambios.append("fireInitQueries: false")

# 3. Reemplazar shouldSyncAppState
pattern_should_sync = r"shouldSyncAppState: \(update\) => \{[^}]*\},"
replacement_should_sync = "shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)"

if re.search(pattern_should_sync, content, re.DOTALL):
    content = re.sub(pattern_should_sync, replacement_should_sync, content, flags=re.DOTALL)
    cambios.append("shouldSyncAppState actualizado")

# 4. Actualizar manejo de conexión 'open' - SOLO la parte de timestamp y estado
# NO tocar el código de reconexión
old_connection = r"// Guardar timestamp de conexión\s+connectionTimestamp = Date\.now\(\);\s+// Marcar que estamos sincronizando app state.*?console\.log\('💡 La sincronización puede tardar hasta 15 minutos.*?\);"
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
    cambios.append("Manejo de conexión 'open' actualizado")

# 5. Reemplazar SOLO los timeouts de sincronización (los setTimeout que esperan sincronización)
# Buscar el patrón específico de los timeouts de sincronización
old_timeouts = r"// Esperar un tiempo antes de marcar como completamente conectado.*?// Esto da tiempo a que la sincronización del app state comience.*?setTimeout\(\(\) => \{.*?// Si después de 2 minutos aún estamos sincronizando.*?if \(isSyncingAppState && connectionStatus === 'syncing'\).*?console\.log\('⏳ La sincronización del app state está en progreso\.\.\.'\);.*?console\.log\('💡 Esto es normal y puede tardar varios minutos más'\);.*?\}, 120000\);.*?// Marcar como completamente conectado después de 5 minutos.*?setTimeout\(\(\) => \{.*?if \(connectionStatus === 'syncing' && !isSyncingAppState\).*?connectionStatus = 'open';.*?console\.log\('✅ Sincronización completada\. WhatsApp completamente conectado\.'\);.*?io\.emit\('connection', \{.*?status: 'open',.*?phone: phoneNumber,.*?name: phoneName.*?\}\);.*?\} else if \(connectionStatus === 'syncing'\).*?console\.log\('⏳ La sincronización aún está en progreso\. Esperando más tiempo\.\.\.'\);.*?\}, 300000\);.*?// Marcar como completamente conectado después de 15 minutos.*?setTimeout\(\(\) => \{.*?if \(connectionStatus === 'syncing'\).*?connectionStatus = 'open';.*?isSyncingAppState = false;.*?console\.log\('✅ Sincronización completada \(timeout\)\. WhatsApp completamente conectado\.'\);.*?io\.emit\('connection', \{.*?status: 'open',.*?phone: phoneNumber,.*?name: phoneName.*?\}\);.*?\}, 900000\);.*?io\.emit\('connection', \{.*?status: 'syncing',.*?phone: phoneNumber,.*?name: phoneName,.*?message: 'Sincronizando estado de la aplicación\.\.\.'.*?\}\);.*?console\.log\('✅ Evento de conexión emitido via Socket\.IO \(sincronizando\)'\);"

new_timeouts = """// MODO PASIVO: Emitir conexión inmediatamente (no hay sincronización)
            io.emit('connection', { 
                status: 'open', // Ya está completamente conectado
                phone: phoneNumber,
                name: phoneName
            });
            console.log('✅ Evento de conexión emitido via Socket.IO');"""

# Buscar un patrón más simple y seguro
old_timeouts_simple = r"// Esperar un tiempo antes de marcar como completamente conectado.*?console\.log\('✅ Evento de conexión emitido via Socket\.IO \(sincronizando\)'\);"

if re.search(old_timeouts_simple, content, re.DOTALL):
    content = re.sub(old_timeouts_simple, new_timeouts, content, flags=re.DOTALL)
    cambios.append("Timeouts de sincronización eliminados")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Cambios aplicados:")
for cambio in cambios:
    print(f"   - {cambio}")
PYEOF

echo ""
echo "5️⃣  Verificando sintaxis final..."
if node -c "$FILE" 2>&1; then
    echo "✅ Sintaxis correcta"
    echo ""
    echo "✅ Código restaurado y modo pasivo aplicado correctamente"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Verificar cambios: git diff $FILE | head -100"
    echo "   2. Commit: git add $FILE && git commit -m 'Fix: Restaurar código y aplicar modo pasivo correctamente'"
    echo "   3. Push: git push"
    echo "   4. Redeploy desde EasyPanel"
else
    echo "❌ Aún hay errores de sintaxis"
    echo "   Revisar el archivo manualmente"
    exit 1
fi
