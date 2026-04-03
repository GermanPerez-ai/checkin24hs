#!/bin/bash
# 🔧 Actualizar función start() directamente

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 ACTUALIZANDO FUNCIÓN start()"
echo "=============================================================="
echo ""

# Backup
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup
echo "✅ Backup creado"
echo ""

# Crear archivo con el código nuevo
cat > /tmp/new_start.js << 'EOF'
async function start() {
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
EOF

# Usar awk para reemplazar la función
awk '
/^async function start\(\) \{/ {
    # Imprimir el nuevo código
    while ((getline line < "/tmp/new_start.js") > 0) {
        print line
    }
    close("/tmp/new_start.js")
    # Saltar las líneas antiguas hasta encontrar el cierre
    skip = 1
    brace_count = 0
    next
}
skip {
    # Contar llaves para encontrar el final de la función
    brace_count += gsub(/\{/, "&")
    brace_count -= gsub(/\}/, "&")
    if (brace_count <= 0 && /^}/) {
        skip = 0
    }
    next
}
{ print }
' whatsapp-server/whatsapp-server-baileys.js > whatsapp-server/whatsapp-server-baileys.js.new

# Reemplazar el archivo
mv whatsapp-server/whatsapp-server-baileys.js.new whatsapp-server/whatsapp-server-baileys.js

# Limpiar
rm -f /tmp/new_start.js

# Verificar
if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
    echo "✅ Archivo actualizado correctamente"
else
    echo "⚠️  Verificación falló, restaurando backup..."
    cp whatsapp-server/whatsapp-server-baileys.js.backup whatsapp-server/whatsapp-server-baileys.js
    exit 1
fi

echo ""
echo "✅ COMPLETADO"
echo ""
