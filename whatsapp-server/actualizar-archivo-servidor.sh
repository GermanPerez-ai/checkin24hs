#!/bin/bash
# 🔧 Actualizar archivo en el servidor

echo "=============================================================="
echo "🔧 ACTUALIZANDO ARCHIVO EN EL SERVIDOR"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# Verificar que el archivo existe
if [ ! -f "whatsapp-server/whatsapp-server-baileys.js" ]; then
    echo "❌ Archivo no encontrado"
    exit 1
fi

# Hacer backup
echo "1️⃣  Creando backup..."
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup
echo "   ✅ Backup creado: whatsapp-server/whatsapp-server-baileys.js.backup"
echo ""

# Buscar la línea donde empieza la función start
START_LINE=$(grep -n "async function start()" whatsapp-server/whatsapp-server-baileys.js | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    echo "❌ No se encontró la función start()"
    exit 1
fi

echo "2️⃣  Función start() encontrada en línea $START_LINE"
echo ""

# Crear archivo temporal con el código actualizado
TEMP_FILE=$(mktemp)

# Copiar todo hasta antes de la función start
head -n $((START_LINE - 1)) whatsapp-server/whatsapp-server-baileys.js > "$TEMP_FILE"

# Agregar el código actualizado de la función start
cat >> "$TEMP_FILE" << 'EOF'
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

# Buscar dónde termina la función start (buscar la siguiente función o el final del archivo)
# Buscar la línea después de "process.exit(1);" que cierra el try-catch
END_LINE=$(sed -n "${START_LINE},$"p whatsapp-server/whatsapp-server-baileys.js | grep -n "^}" | head -1 | cut -d: -f1)
END_LINE=$((START_LINE + END_LINE - 1))

# Buscar la siguiente sección importante (process.on o comentario)
NEXT_SECTION=$(sed -n "$((END_LINE + 1)),$"p whatsapp-server/whatsapp-server-baileys.js | grep -n "^//\|^process.on\|^start()" | head -1 | cut -d: -f1)

if [ -n "$NEXT_SECTION" ]; then
    # Copiar el resto del archivo desde después de la función start
    tail -n +$((END_LINE + 1)) whatsapp-server/whatsapp-server-baileys.js >> "$TEMP_FILE"
else
    # Si no hay más contenido, solo agregar las líneas finales que vimos
    cat >> "$TEMP_FILE" << 'EOF'

// Manejar cierre limpio
process.on('SIGINT', () => {
    console.log('\n🛑 Cerrando servidor...');
    if (sock) {
        sock.end();
    }
    process.exit(0);
});

// Iniciar
start();
EOF
fi

# Reemplazar el archivo original
echo "3️⃣  Reemplazando archivo..."
mv "$TEMP_FILE" whatsapp-server/whatsapp-server-baileys.js
echo "   ✅ Archivo actualizado"
echo ""

# Verificar que el cambio se aplicó
echo "4️⃣  Verificando cambios..."
if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ El archivo tiene el código actualizado"
else
    echo "   ⚠️  No se pudo verificar el cambio"
fi
echo ""

echo "=============================================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "📤 PRÓXIMOS PASOS:"
echo ""
echo "1. Sube los cambios a GitHub:"
echo "   cd /root/checkin24hs"
echo "   git add whatsapp-server/whatsapp-server-baileys.js"
echo "   git commit -m 'Fix: Iniciar servidor HTTP antes de conectar WhatsApp'"
echo "   git push"
echo ""
echo "2. En EasyPanel, haz redeploy del servicio whatsapp"
echo ""
echo "💡 Si algo sale mal, puedes restaurar el backup:"
echo "   cp whatsapp-server/whatsapp-server-baileys.js.backup whatsapp-server/whatsapp-server-baileys.js"
echo ""
