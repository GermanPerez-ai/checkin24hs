/**
 * Script para limpiar la sesión de WhatsApp bloqueada
 * 
 * Este script:
 * 1. Elimina archivos de lock de Chrome/Puppeteer
 * 2. Limpia la sesión de WhatsApp si es necesario
 * 3. Prepara el servidor para una nueva conexión
 */

const fs = require('fs');
const path = require('path');

const SESSION_DIR = path.join(__dirname, '.wwebjs_auth');
const LOCK_FILE = path.join(SESSION_DIR, 'Default', 'SingletonLock');
const LOCK_SOCKET = path.join(SESSION_DIR, 'Default', 'SingletonSocket');
const LOCK_COOKIE = path.join(SESSION_DIR, 'Default', 'SingletonCookie');

console.log('🧹 Limpiando sesión de WhatsApp...\n');

// Función para eliminar archivo o directorio
function removeFileOrDir(filePath) {
    try {
        if (fs.existsSync(filePath)) {
            const stats = fs.statSync(filePath);
            if (stats.isDirectory()) {
                fs.rmSync(filePath, { recursive: true, force: true });
                console.log(`✅ Eliminado directorio: ${path.basename(filePath)}`);
            } else {
                fs.unlinkSync(filePath);
                console.log(`✅ Eliminado archivo: ${path.basename(filePath)}`);
            }
            return true;
        }
        return false;
    } catch (error) {
        console.error(`❌ Error eliminando ${filePath}:`, error.message);
        return false;
    }
}

// Eliminar archivos de lock
console.log('📋 Eliminando archivos de lock...');
removeFileOrDir(LOCK_FILE);
removeFileOrDir(LOCK_SOCKET);
removeFileOrDir(LOCK_COOKIE);

// Buscar y eliminar otros archivos de lock en el directorio Default
if (fs.existsSync(path.join(SESSION_DIR, 'Default'))) {
    const defaultDir = path.join(SESSION_DIR, 'Default');
    const files = fs.readdirSync(defaultDir);
    
    files.forEach(file => {
        if (file.includes('Lock') || file.includes('Singleton')) {
            const filePath = path.join(defaultDir, file);
            removeFileOrDir(filePath);
        }
    });
}

// Opción para limpiar toda la sesión (descomentar si es necesario)
const CLEAR_ALL_SESSION = process.argv.includes('--clear-all');

if (CLEAR_ALL_SESSION) {
    console.log('\n🗑️  Limpiando toda la sesión de WhatsApp...');
    if (removeFileOrDir(SESSION_DIR)) {
        console.log('✅ Sesión completa eliminada. Necesitarás escanear el QR nuevamente.');
    }
} else {
    console.log('\n✅ Archivos de lock eliminados.');
    console.log('💡 Si el problema persiste, ejecuta: node limpiar_sesion.js --clear-all');
    console.log('   (Esto eliminará la sesión y necesitarás escanear el QR nuevamente)');
}

console.log('\n✅ Limpieza completada. Puedes reiniciar el servidor ahora.');

