/**
 * 🔧 Script de Configuración de QR para WhatsApp
 * 
 * Este script te permite configurar y gestionar el código QR de WhatsApp
 * de manera fácil desde la línea de comandos.
 */

const readline = require('readline');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Colores para la terminal
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

// Interfaz de línea de comandos
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(prompt) {
    return new Promise((resolve) => {
        rl.question(prompt, resolve);
    });
}

/**
 * Obtener estado del QR desde el servidor
 */
async function obtenerEstadoQR(serverUrl, instance = 1) {
    try {
        const port = 3000 + instance;
        const url = `${serverUrl}:${port}/api/status`;
        
        log(`\n🔍 Verificando estado en ${url}...`, 'cyan');
        
        const response = await axios.get(url, {
            timeout: 5000
        });
        
        return response.data;
    } catch (error) {
        log(`❌ Error obteniendo estado: ${error.message}`, 'red');
        return null;
    }
}

/**
 * Obtener QR code desde el servidor
 */
async function obtenerQR(serverUrl, instance = 1) {
    try {
        const port = 3000 + instance;
        const url = `${serverUrl}:${port}/api/qr`;
        
        log(`\n📱 Obteniendo QR desde ${url}...`, 'cyan');
        
        const response = await axios.get(url, {
            timeout: 5000
        });
        
        return response.data;
    } catch (error) {
        log(`❌ Error obteniendo QR: ${error.message}`, 'red');
        return null;
    }
}

/**
 * Guardar QR como imagen
 */
function guardarQRImagen(qrData, filename = 'qr-code.png') {
    return new Promise((resolve, reject) => {
        if (!qrData.qrImage && !qrData.qr) {
            reject(new Error('No hay datos de QR para guardar'));
            return;
        }
        
        // Si ya es una imagen base64
        if (qrData.qrImage && qrData.qrImage.startsWith('data:image')) {
            const base64Data = qrData.qrImage.replace(/^data:image\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            fs.writeFileSync(filename, buffer);
            resolve(filename);
            return;
        }
        
        // Si es un string QR, usar API externa
        if (qrData.qr) {
            const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=512x512&data=${encodeURIComponent(qrData.qr)}`;
            axios({
                url: qrUrl,
                method: 'GET',
                responseType: 'stream'
            }).then(response => {
                const writer = fs.createWriteStream(filename);
                response.data.pipe(writer);
                writer.on('finish', () => resolve(filename));
                writer.on('error', reject);
            }).catch(reject);
        }
    });
}

/**
 * Mostrar menú principal
 */
function mostrarMenu() {
    log('\n' + '='.repeat(60), 'cyan');
    log('🔧 CONFIGURACIÓN DE QR - WHATSAPP CHECKIN24HS', 'bright');
    log('='.repeat(60), 'cyan');
    log('\n1. Ver estado de conexión');
    log('2. Obtener código QR');
    log('3. Guardar QR como imagen');
    log('4. Verificar todas las instancias (1-4)');
    log('5. Limpiar sesión y generar nuevo QR');
    log('6. Configurar URL del servidor');
    log('0. Salir\n', 'yellow');
}

/**
 * Menú principal
 */
async function main() {
    let serverUrl = process.env.WHATSAPP_SERVER_URL || 'http://localhost';
    
    log('📱 Configurador de QR para WhatsApp', 'bright');
    log(`🌐 URL del servidor: ${serverUrl}`, 'cyan');
    
    // Verificar si existe archivo de configuración
    const configFile = path.join(__dirname, '.qr-config.json');
    if (fs.existsSync(configFile)) {
        try {
            const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
            if (config.serverUrl) {
                serverUrl = config.serverUrl;
                log(`✅ Configuración cargada: ${serverUrl}`, 'green');
            }
        } catch (e) {
            log('⚠️  Error leyendo configuración, usando valores por defecto', 'yellow');
        }
    }
    
    while (true) {
        mostrarMenu();
        
        const opcion = await question('Selecciona una opción: ');
        
        switch (opcion.trim()) {
            case '1':
                await verEstado(serverUrl);
                break;
                
            case '2':
                await verQR(serverUrl);
                break;
                
            case '3':
                await guardarQR(serverUrl);
                break;
                
            case '4':
                await verificarTodasInstancias(serverUrl);
                break;
                
            case '5':
                await limpiarSesion();
                break;
                
            case '6':
                serverUrl = await configurarServidor(serverUrl, configFile);
                break;
                
            case '0':
                log('\n👋 ¡Hasta luego!', 'green');
                rl.close();
                return;
                
            default:
                log('\n❌ Opción inválida', 'red');
        }
        
        await question('\nPresiona Enter para continuar...');
    }
}

/**
 * Ver estado de conexión
 */
async function verEstado(serverUrl) {
    const instance = await question('\n📱 Número de instancia (1-4, Enter para 1): ') || '1';
    const numInstance = parseInt(instance) || 1;
    
    if (numInstance < 1 || numInstance > 4) {
        log('❌ Instancia debe estar entre 1 y 4', 'red');
        return;
    }
    
    const estado = await obtenerEstadoQR(serverUrl, numInstance);
    
    if (!estado) {
        log('❌ No se pudo obtener el estado del servidor', 'red');
        return;
    }
    
    log('\n' + '='.repeat(60), 'cyan');
    log(`📊 ESTADO INSTANCIA ${numInstance}`, 'bright');
    log('='.repeat(60), 'cyan');
    
    log(`\n🔌 Conexión: ${estado.connected ? '✅ Conectado' : '❌ Desconectado'}`, estado.connected ? 'green' : 'red');
    log(`📱 WhatsApp: ${estado.whatsapp}`, estado.whatsapp === 'connected' ? 'green' : 'yellow');
    log(`🤖 Flor IA: ${estado.flor || 'N/A'}`, 'cyan');
    log(`🔄 Auto-respuesta: ${estado.autoReply ? 'Activada' : 'Desactivada'}`, 'cyan');
    
    if (estado.phone) {
        log(`\n📞 Teléfono: ${estado.phone}`, 'green');
        log(`👤 Nombre: ${estado.name || 'N/A'}`, 'green');
    }
    
    if (estado.qrCode) {
        log(`\n📱 QR Code: Disponible`, 'yellow');
        log(`🔗 URL: ${estado.qrCode.substring(0, 80)}...`, 'cyan');
    } else {
        log(`\n📱 QR Code: ${estado.connected ? 'No necesario (conectado)' : 'No disponible'}`, 'yellow');
    }
}

/**
 * Ver código QR
 */
async function verQR(serverUrl) {
    const instance = await question('\n📱 Número de instancia (1-4, Enter para 1): ') || '1';
    const numInstance = parseInt(instance) || 1;
    
    if (numInstance < 1 || numInstance > 4) {
        log('❌ Instancia debe estar entre 1 y 4', 'red');
        return;
    }
    
    const qrData = await obtenerQR(serverUrl, numInstance);
    
    if (!qrData) {
        log('❌ No se pudo obtener el QR del servidor', 'red');
        return;
    }
    
    log('\n' + '='.repeat(60), 'cyan');
    log(`📱 CÓDIGO QR - INSTANCIA ${numInstance}`, 'bright');
    log('='.repeat(60), 'cyan');
    
    log(`\n📊 Estado: ${qrData.status}`, qrData.status === 'waiting_scan' ? 'yellow' : 'green');
    
    if (qrData.qr) {
        log(`\n📱 Código QR (primeros 50 caracteres):`, 'cyan');
        log(`${qrData.qr.substring(0, 50)}...`, 'yellow');
        
        if (qrData.qrImage) {
            log(`\n✅ Imagen QR generada (base64)`, 'green');
        }
        
        // Generar URL para ver QR
        const qrUrl = qrData.qrImage || 
                     `https://api.qrserver.com/v1/create-qr-code/?size=512x512&data=${encodeURIComponent(qrData.qr)}`;
        
        log(`\n🔗 URL del QR:`, 'cyan');
        log(`${qrUrl.substring(0, 100)}...`, 'yellow');
        
        log(`\n💡 Puedes abrir esta URL en tu navegador para ver el QR`, 'cyan');
        log(`   O usar la opción 3 para guardarlo como imagen`, 'cyan');
    } else {
        log(`\n❌ No hay QR disponible`, 'red');
        if (qrData.status === 'connected') {
            log(`   WhatsApp ya está conectado, no se necesita QR`, 'yellow');
        } else {
            log(`   El servidor puede estar inicializando...`, 'yellow');
        }
    }
}

/**
 * Guardar QR como imagen
 */
async function guardarQR(serverUrl) {
    const instance = await question('\n📱 Número de instancia (1-4, Enter para 1): ') || '1';
    const numInstance = parseInt(instance) || 1;
    
    if (numInstance < 1 || numInstance > 4) {
        log('❌ Instancia debe estar entre 1 y 4', 'red');
        return;
    }
    
    const filename = await question(`\n💾 Nombre del archivo (Enter para qr-${numInstance}.png): `) || 
                     `qr-${numInstance}.png`;
    
    log('\n📥 Descargando QR...', 'cyan');
    
    const qrData = await obtenerQR(serverUrl, numInstance);
    
    if (!qrData || !qrData.qr) {
        log('❌ No se pudo obtener el QR del servidor', 'red');
        return;
    }
    
    try {
        await guardarQRImagen(qrData, filename);
        log(`\n✅ QR guardado exitosamente en: ${filename}`, 'green');
        log(`\n📱 Puedes abrir este archivo con cualquier visor de imágenes`, 'cyan');
        log(`   Y escanearlo con WhatsApp desde tu teléfono`, 'cyan');
    } catch (error) {
        log(`\n❌ Error guardando QR: ${error.message}`, 'red');
    }
}

/**
 * Verificar todas las instancias
 */
async function verificarTodasInstancias(serverUrl) {
    log('\n🔍 Verificando todas las instancias...', 'cyan');
    log('='.repeat(60), 'cyan');
    
    for (let i = 1; i <= 4; i++) {
        log(`\n📱 Instancia ${i}:`, 'bright');
        const estado = await obtenerEstadoQR(serverUrl, i);
        
        if (!estado) {
            log(`   ❌ Servidor no disponible en puerto ${3000 + i}`, 'red');
            continue;
        }
        
        const status = estado.connected ? '✅ Conectado' : '⏳ Esperando QR';
        const color = estado.connected ? 'green' : 'yellow';
        log(`   ${status}`, color);
        
        if (estado.phone) {
            log(`   📞 ${estado.phone} (${estado.name || 'Sin nombre'})`, 'cyan');
        }
        
        if (estado.qrCode && !estado.connected) {
            log(`   📱 QR disponible`, 'yellow');
        }
    }
}

/**
 * Limpiar sesión
 */
async function limpiarSesion() {
    log('\n⚠️  LIMPIAR SESIÓN', 'yellow');
    log('='.repeat(60), 'yellow');
    
    const instance = await question('\n📱 Número de instancia (1-4, Enter para 1): ') || '1';
    const numInstance = parseInt(instance) || 1;
    
    if (numInstance < 1 || numInstance > 4) {
        log('❌ Instancia debe estar entre 1 y 4', 'red');
        return;
    }
    
    const confirmacion = await question(`\n⚠️  ¿Estás seguro de limpiar la sesión ${numInstance}? (s/N): `);
    
    if (confirmacion.toLowerCase() !== 's') {
        log('❌ Operación cancelada', 'yellow');
        return;
    }
    
    const authDir = path.join(__dirname, `auth_info_baileys_${numInstance}`);
    
    if (!fs.existsSync(authDir)) {
        log(`\n⚠️  No existe sesión para limpiar en instancia ${numInstance}`, 'yellow');
        return;
    }
    
    try {
        // Eliminar directorio recursivamente
        const deleteRecursive = (dir) => {
            if (fs.existsSync(dir)) {
                const files = fs.readdirSync(dir);
                files.forEach(file => {
                    const filePath = path.join(dir, file);
                    const stat = fs.statSync(filePath);
                    if (stat.isDirectory()) {
                        deleteRecursive(filePath);
                        fs.rmdirSync(filePath);
                    } else {
                        fs.unlinkSync(filePath);
                    }
                });
            }
        };
        
        deleteRecursive(authDir);
        fs.rmdirSync(authDir);
        
        log(`\n✅ Sesión limpiada exitosamente`, 'green');
        log(`\n📱 Reinicia el servidor para generar un nuevo QR`, 'cyan');
    } catch (error) {
        log(`\n❌ Error limpiando sesión: ${error.message}`, 'red');
    }
}

/**
 * Configurar URL del servidor
 */
async function configurarServidor(currentUrl, configFile) {
    log('\n⚙️  CONFIGURAR URL DEL SERVIDOR', 'cyan');
    log('='.repeat(60), 'cyan');
    log(`\nURL actual: ${currentUrl}`, 'yellow');
    
    const newUrl = await question('\nIngresa la nueva URL del servidor (Enter para mantener actual): ');
    
    if (!newUrl.trim()) {
        log('✅ URL no cambiada', 'green');
        return currentUrl;
    }
    
    let finalUrl = newUrl.trim();
    
    // Asegurar que tenga protocolo
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = `http://${finalUrl}`;
    }
    
    // Remover barra final
    finalUrl = finalUrl.replace(/\/$/, '');
    
    try {
        // Guardar en archivo de configuración
        const config = { serverUrl: finalUrl };
        fs.writeFileSync(configFile, JSON.stringify(config, null, 2));
        
        log(`\n✅ URL guardada: ${finalUrl}`, 'green');
        return finalUrl;
    } catch (error) {
        log(`\n❌ Error guardando configuración: ${error.message}`, 'red');
        return currentUrl;
    }
}

// Ejecutar si es el archivo principal
if (require.main === module) {
    main().catch(error => {
        log(`\n❌ Error fatal: ${error.message}`, 'red');
        console.error(error);
        process.exit(1);
    });
}

module.exports = {
    obtenerEstadoQR,
    obtenerQR,
    guardarQRImagen
};
