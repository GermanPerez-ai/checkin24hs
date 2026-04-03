#!/bin/bash
# Aplicar modo pasivo de Baileys directamente en el servidor

cd /root/checkin24hs
FILE="whatsapp-server/whatsapp-server-baileys.js"

echo "🔄 Aplicando modo pasivo de Baileys..."

# Crear backup
cp "$FILE" "$FILE.backup"

# 1. Agregar passive: true después de browser
sed -i "/browser: \['Chrome', 'Desktop', '1.0.0'\],/a\\
        \\
        // MODO PASIVO - Desactiva sincronización del app state (evita timeouts)\\
        passive: true,\\
" "$FILE"

# 2. Cambiar connectTimeoutMs a 300000
sed -i 's/connectTimeoutMs: 900000/connectTimeoutMs: 300000/g' "$FILE"

# 3. Cambiar defaultQueryTimeoutMs a 60000
sed -i 's/defaultQueryTimeoutMs: 600000/defaultQueryTimeoutMs: 60000/g' "$FILE"

# 4. Cambiar appStateSyncTimeoutMs a 0
sed -i 's/appStateSyncTimeoutMs: 900000/appStateSyncTimeoutMs: 0/g' "$FILE"

# 5. Cambiar keepAliveIntervalMs a 10000
sed -i 's/keepAliveIntervalMs: 5000/keepAliveIntervalMs: 10000/g' "$FILE"

# 6. Cambiar shouldSyncAppState para que siempre retorne false
sed -i 's/shouldSyncAppState: (update) => {.*?return true; \/\/ Después de autenticado, permitir todas las sincronizaciones/shouldSyncAppState: () => false, \/\/ NO sincronizar app state (modo pasivo)/g' "$FILE"

# 7. Cambiar fireInitQueries a false
sed -i 's/fireInitQueries: true/fireInitQueries: false/g' "$FILE"

# 8. Actualizar manejo de conexión 'open'
sed -i '/connectionTimestamp = Date\.now();/,/console\.log.*sincronización puede tardar hasta 15 minutos/c\
            // Guardar timestamp de conexión\
            connectionTimestamp = Date.now();\
            \
            // MODO PASIVO: No hay sincronización del app state\
            // Marcar como completamente conectado inmediatamente\
            isSyncingAppState = false;\
            connectionStatus = '\''open'\''; // Ya está completamente conectado (modo pasivo)\
            console.log('\''💡 Modo pasivo activado - Sin sincronización de app state'\'');\
            console.log('\''✅ Conexión completa inmediata (más rápido, sin esperar sincronización)'\'');\
' "$FILE"

# 9. Reemplazar timeouts de sincronización con emisión inmediata
sed -i '/\/\/ Esperar un tiempo antes de marcar como completamente conectado/,/console\.log.*Evento de conexión emitido via Socket\.IO (sincronizando)/c\
            // MODO PASIVO: Emitir conexión inmediatamente (no hay sincronización)\
            io.emit('\''connection'\'', { \
                status: '\''open'\'', // Ya está completamente conectado\
                phone: phoneNumber,\
                name: phoneName\
            });\
            console.log('\''✅ Evento de conexión emitido via Socket.IO'\'');\
' "$FILE"

echo "✅ Cambios aplicados"
echo ""
echo "📝 Verificar cambios:"
echo "   git diff $FILE | head -100"
echo ""
echo "📝 Luego hacer commit y push:"
echo "   git add $FILE"
echo "   git commit -m 'Fix: Modo pasivo de Baileys para evitar problemas de sincronización'"
echo "   git push"
