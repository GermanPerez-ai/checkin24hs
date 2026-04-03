#!/bin/bash
# Script para aplicar cambios de directorios de sesión únicos en el servidor

ARCHIVO="whatsapp-server.js"
BACKUP="${ARCHIVO}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Aplicando cambios a ${ARCHIVO}..."

# Crear backup
cp "$ARCHIVO" "$BACKUP"
echo "✅ Backup creado: $BACKUP"

# Verificar si ya tiene los cambios
if grep -q "sessionDataPath" "$ARCHIVO"; then
    echo "⚠️  El archivo ya parece tener los cambios. Verificando..."
    if grep -q "\.wwebjs_auth_\${CONFIG.INSTANCE_NUMBER}" "$ARCHIVO"; then
        echo "✅ Los cambios ya están aplicados!"
        exit 0
    fi
fi

# Buscar la línea donde está el código actual del cliente
LINEA_CLIENTE=$(grep -n "new Client({" "$ARCHIVO" | head -1 | cut -d: -f1)

if [ -z "$LINEA_CLIENTE" ]; then
    echo "❌ No se encontró la línea del cliente. Abortando."
    exit 1
fi

echo "📝 Encontrada línea del cliente en: $LINEA_CLIENTE"

# Buscar la línea donde está dataPath: '.wwebjs_auth'
LINEA_DATAPATH=$(grep -n "dataPath: '.wwebjs_auth'" "$ARCHIVO" | head -1 | cut -d: -f1)

if [ -z "$LINEA_DATAPATH" ]; then
    echo "⚠️  No se encontró la línea dataPath antigua. El archivo puede estar ya modificado."
    echo "📋 Verificando contenido actual..."
    grep -A 5 "authStrategy: new LocalAuth" "$ARCHIVO" | head -10
    exit 1
fi

echo "📝 Encontrada línea dataPath antigua en: $LINEA_DATAPATH"

# Crear archivo temporal con los cambios
TEMP_FILE=$(mktemp)

# Copiar todo hasta antes de la línea del cliente
head -n $((LINEA_CLIENTE - 1)) "$ARCHIVO" > "$TEMP_FILE"

# Agregar la función cleanChromeLocks
cat >> "$TEMP_FILE" << 'FUNCION_EOF'

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

FUNCION_EOF

# Buscar y reemplazar la sección del cliente
# Necesitamos encontrar desde "new Client({" hasta el cierre correspondiente
# Esto es más complejo, mejor usar un enfoque diferente

echo "⚠️  El script automático es complejo. Usando método manual..."
echo ""
echo "📋 INSTRUCCIONES MANUALES:"
echo ""
echo "1. Edita el archivo: nano whatsapp-server.js"
echo ""
echo "2. Busca la línea que dice:"
echo "   authStrategy: new LocalAuth({"
echo "       dataPath: '.wwebjs_auth'"
echo ""
echo "3. Reemplázala con:"
echo "   authStrategy: new LocalAuth({"
echo "       dataPath: sessionDataPath"
echo ""
echo "4. ANTES de esa línea, agrega:"
echo ""
echo "// Función para limpiar locks de Chrome antes de inicializar"
echo "function cleanChromeLocks(dataPath) { ... }"
echo ""
echo "// Directorio de sesión único por instancia"
echo "const sessionDataPath = \`.wwebjs_auth_\${CONFIG.INSTANCE_NUMBER}\`;"
echo "console.log(\`📁 Usando directorio de sesión: \${sessionDataPath} (Instancia \${CONFIG.INSTANCE_NUMBER})\`);"
echo ""
echo "// Limpiar locks antes de crear el cliente"
echo "cleanChromeLocks(sessionDataPath);"
echo ""

rm -f "$TEMP_FILE"
echo "✅ Script completado. Sigue las instrucciones manuales arriba."

