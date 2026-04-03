#!/bin/bash
# 🔧 Fix: Actualizar función start() para iniciar servidor HTTP primero

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 ACTUALIZANDO FUNCIÓN start()"
echo "=============================================================="
echo ""

# Backup
BACKUP_FILE="whatsapp-server/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)"
cp whatsapp-server/whatsapp-server-baileys.js "$BACKUP_FILE"
echo "✅ Backup: $BACKUP_FILE"
echo ""

# Leer el archivo y reemplazar la función start usando Python (más confiable)
python3 << 'PYTHON_EOF'
import re

file_path = 'whatsapp-server/whatsapp-server-baileys.js'

# Leer el archivo
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Código nuevo de la función start
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

# Patrón para encontrar la función start completa
# Buscar desde "async function start()" hasta el cierre del catch
pattern = r'async function start\(\) \{[^}]*try \{[^}]*await connectToWhatsApp\(\);[^}]*server\.listen\([^}]*\}[^}]*\} catch[^}]*\}[^}]*\}'

# Reemplazar
new_content = re.sub(pattern, new_start, content, flags=re.DOTALL)

# Si no funcionó el patrón complejo, intentar uno más simple
if new_content == content:
    # Patrón más simple: desde async function start hasta el cierre
    pattern2 = r'async function start\(\) \{.*?\n\s*\}'
    new_content = re.sub(pattern2, new_start, content, flags=re.DOTALL)

# Escribir el archivo
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

# Verificar
if 'Iniciar servidor HTTP PRIMERO' in new_content:
    print('✅ Archivo actualizado correctamente')
    exit(0)
else:
    print('⚠️  No se pudo verificar el cambio')
    exit(1)
PYTHON_EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ACTUALIZACIÓN COMPLETADA"
    echo ""
    echo "📤 Próximos pasos:"
    echo "   1. git add whatsapp-server/whatsapp-server-baileys.js"
    echo "   2. git commit -m 'Fix: Iniciar servidor HTTP antes de conectar WhatsApp'"
    echo "   3. git push"
    echo "   4. Redeploy en EasyPanel"
    echo ""
else
    echo ""
    echo "❌ Error en la actualización"
    echo "   Restaurando backup..."
    cp "$BACKUP_FILE" whatsapp-server/whatsapp-server-baileys.js
    echo "   Backup restaurado"
fi
