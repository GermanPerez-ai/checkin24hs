#!/bin/bash
# 🔧 Editar función start() directamente en el servidor

cd /root/checkin24hs

echo "🔧 Actualizando función start()..."
echo ""

# Backup
cp whatsapp-server/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js.backup
echo "✅ Backup creado"
echo ""

# Usar Python para hacer el reemplazo
python3 << 'PYEOF'
import re

file_path = 'whatsapp-server/whatsapp-server-baileys.js'

# Leer archivo
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Código nuevo
new_start = """async function start() {
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
}"""

# Patrón: desde "async function start()" hasta el cierre del catch
# Buscar el patrón completo
pattern = r'async function start\(\) \{.*?    \} catch \(error\) \{.*?    \}\n\}'

# Reemplazar
new_content = re.sub(pattern, new_start, content, flags=re.DOTALL)

# Si no funcionó, intentar patrón más simple
if new_content == content:
    # Buscar desde async function start hasta encontrar "// Manejar" o "process.on"
    pattern2 = r'async function start\(\) \{.*?(?=\n// Manejar|\nprocess\.on|\n// Iniciar)'
    new_content = re.sub(pattern2, new_start + '\n', content, flags=re.DOTALL)

# Escribir
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

# Verificar
if 'Iniciar servidor HTTP PRIMERO' in new_content:
    print('✅ Archivo actualizado correctamente')
    exit(0)
else:
    print('⚠️  No se pudo verificar el cambio')
    exit(1)
PYEOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ACTUALIZACIÓN COMPLETADA"
    echo ""
    echo "Verificando..."
    grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js && echo "✅ Verificación exitosa" || echo "⚠️  Verificación falló"
    echo ""
    echo "📤 Próximos pasos:"
    echo "   git add whatsapp-server/whatsapp-server-baileys.js"
    echo "   git commit -m 'Fix: Iniciar servidor HTTP antes de conectar WhatsApp'"
    echo "   git push"
else
    echo ""
    echo "❌ Error. Restaurando backup..."
    cp whatsapp-server/whatsapp-server-baileys.js.backup whatsapp-server/whatsapp-server-baileys.js
fi
