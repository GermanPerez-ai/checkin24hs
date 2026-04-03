#!/bin/bash
# Script simple para aplicar cambios - EJECUTAR EN EL SERVIDOR

ARCHIVO="whatsapp-server.js"

echo "🔧 Aplicando cambios..."

# 1. Backup
cp "$ARCHIVO" "${ARCHIVO}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup creado"

# 2. Reemplazar dataPath
sed -i "s/dataPath: '.wwebjs_auth'/dataPath: sessionDataPath/" "$ARCHIVO"
echo "✅ dataPath reemplazado"

# 3. Agregar argumentos adicionales de puppeteer (si no existen)
if ! grep -q "disable-software-rasterizer" "$ARCHIVO"; then
    sed -i "/--disable-gpu/a\            '--disable-software-rasterizer',\n            '--disable-background-timer-throttling',\n            '--disable-backgrounding-occluded-windows',\n            '--disable-renderer-backgrounding',\n            '--disable-features=TranslateUI',\n            '--disable-ipc-flooding-protection'," "$ARCHIVO"
    echo "✅ Argumentos de puppeteer agregados"
fi

# 4. Insertar código ANTES de "new Client({"
# Crear archivo temporal con el código a insertar
TEMP_CODE=$(mktemp)
cat > "$TEMP_CODE" << 'CODIGO_EOF'

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

CODIGO_EOF

# Encontrar la línea de "new Client({"
LINEA=$(grep -n "// Crear cliente de WhatsApp" "$ARCHIVO" | head -1 | cut -d: -f1)

if [ -z "$LINEA" ]; then
    LINEA=$(grep -n "new Client({" "$ARCHIVO" | head -1 | cut -d: -f1)
fi

if [ -n "$LINEA" ]; then
    # Insertar el código antes de esa línea
    sed -i "${LINEA}r $TEMP_CODE" "$ARCHIVO"
    echo "✅ Código insertado antes de la línea $LINEA"
else
    echo "⚠️  No se encontró la línea del cliente. Necesitas editar manualmente."
    echo "📋 Contenido a insertar está en: $TEMP_CODE"
fi

# 5. Verificar cambios
echo ""
echo "📋 Verificando cambios aplicados..."
if grep -q "sessionDataPath" "$ARCHIVO"; then
    echo "✅ Cambios aplicados correctamente!"
    grep -n "sessionDataPath" "$ARCHIVO" | head -3
else
    echo "❌ Los cambios no se aplicaron correctamente"
fi

rm -f "$TEMP_CODE"
echo ""
echo "✅ Proceso completado!"

