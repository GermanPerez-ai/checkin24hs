#!/bin/bash
# Script FÁCIL - Copiar y pegar todo en el servidor

cd ~/checkin24hs/whatsapp-server

# 1. Backup
cp whatsapp-server.js whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"

# 2. Reemplazar dataPath
sed -i "s/dataPath: '.wwebjs_auth'/dataPath: sessionDataPath/" whatsapp-server.js
echo "✅ dataPath reemplazado"

# 3. Buscar línea donde insertar código (antes de "new Client({")
LINEA=$(grep -n "// Crear cliente de WhatsApp" whatsapp-server.js | head -1 | cut -d: -f1)
if [ -z "$LINEA" ]; then
    LINEA=$(grep -n "new Client({" whatsapp-server.js | head -1 | cut -d: -f1)
fi

if [ -n "$LINEA" ]; then
    # Crear archivo temporal con el código a insertar
    cat > /tmp/codigo_nuevo.txt << 'EOF'

// Función para limpiar locks de Chrome antes de inicializar
function cleanChromeLocks(dataPath) {
    try {
        const sessionPath = path.join(__dirname, dataPath);
        const defaultPath = path.join(sessionPath, 'session', 'Default');
        
        if (fs.existsSync(defaultPath)) {
            // Eliminar archivos de lock
            const lockFiles = [
                'SingletonLock',
                'SingletonSocket',
                'SingletonCookie',
                'lockfile'
            ];
            
            lockFiles.forEach(lockFile => {
                const lockPath = path.join(defaultPath, lockFile);
                if (fs.existsSync(lockPath)) {
                    try {
                        fs.unlinkSync(lockPath);
                        console.log(`✅ Lock eliminado: ${lockFile}`);
                    } catch (e) {
                        // Ignorar errores si el archivo está en uso
                    }
                }
            });
            
            // Buscar y eliminar otros archivos de lock
            try {
                const files = fs.readdirSync(defaultPath);
                files.forEach(file => {
                    if (file.includes('Lock') || file.includes('Singleton')) {
                        const filePath = path.join(defaultPath, file);
                        try {
                            fs.unlinkSync(filePath);
                        } catch (e) {
                            // Ignorar errores
                        }
                    }
                });
            } catch (e) {
                // Ignorar errores de lectura
            }
        }
    } catch (error) {
        console.log(`⚠️ No se pudieron limpiar locks (puede ser normal): ${error.message}`);
    }
}

// Directorio de sesión único por instancia
const sessionDataPath = `.wwebjs_auth_${CONFIG.INSTANCE_NUMBER}`;
console.log(`📁 Usando directorio de sesión: ${sessionDataPath} (Instancia ${CONFIG.INSTANCE_NUMBER})`);

// Limpiar locks antes de crear el cliente
cleanChromeLocks(sessionDataPath);

EOF
    
    # Insertar antes de la línea encontrada
    sed -i "${LINEA}r /tmp/codigo_nuevo.txt" whatsapp-server.js
    echo "✅ Código insertado en línea $LINEA"
    rm -f /tmp/codigo_nuevo.txt
else
    echo "⚠️  No se encontró la línea del cliente"
fi

# 4. Agregar argumentos adicionales de puppeteer (si no existen)
if ! grep -q "disable-software-rasterizer" whatsapp-server.js; then
    sed -i "/--disable-gpu/a\            '--disable-software-rasterizer',\n            '--disable-background-timer-throttling',\n            '--disable-backgrounding-occluded-windows',\n            '--disable-renderer-backgrounding',\n            '--disable-features=TranslateUI',\n            '--disable-ipc-flooding-protection'," whatsapp-server.js
    echo "✅ Argumentos de puppeteer agregados"
fi

# 5. Mejorar manejo de SIGTERM (si no existe)
if ! grep -q "process.on('SIGTERM'" whatsapp-server.js; then
    sed -i "/process.on('SIGINT'/a\\nprocess.on('SIGTERM', async () => {\n    console.log('\\n🛑 Cerrando servidor (SIGTERM)...');\n    try {\n        if (client) {\n            await client.destroy();\n        }\n    } catch (error) {\n        console.error('⚠️ Error al destruir cliente:', error.message);\n    }\n    process.exit(0);\n});" whatsapp-server.js
    echo "✅ Manejo de SIGTERM agregado"
fi

# 6. Verificar cambios
echo ""
echo "📋 Verificando cambios..."
if grep -q "sessionDataPath" whatsapp-server.js; then
    echo "✅ ¡Cambios aplicados correctamente!"
    echo ""
    echo "📝 Líneas modificadas:"
    grep -n "sessionDataPath" whatsapp-server.js | head -3
else
    echo "❌ Error: Los cambios no se aplicaron"
fi

echo ""
echo "✅ ¡Listo! Ahora ejecuta: pm2 restart all"

