// ============================================
// DIAGNÓSTICO: Por qué no se puede vincular WhatsApp
// ============================================
// Ejecuta este script para diagnosticar problemas de vinculación

console.log('🔍 DIAGNÓSTICO DE VINCULACIÓN WHATSAPP...\n');

// 1. Verificar estado del servidor
console.log('1️⃣ Verificando estado del servidor...');
const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl') || 'http://configwp.checkin24hs.com';
console.log(`   URL del servidor: ${serverUrl}`);

// Verificar cada instancia
for (let i = 1; i <= 4; i++) {
    const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    const card = cardData[i] || {};
    
    if (card.status === 'connecting' && card.qr) {
        console.log(`\n📱 Tarjeta ${i}:`);
        console.log(`   Estado: ${card.status}`);
        console.log(`   Tiene QR: Sí`);
        console.log(`   Longitud del QR: ${card.qr.length} caracteres`);
        console.log(`   Primeros 50 caracteres: ${card.qr.substring(0, 50)}...`);
        
        // Construir URL del servidor para esta tarjeta
        let instanceUrl = serverUrl;
        if (window.location.protocol === 'https:') {
            instanceUrl = instanceUrl.replace('http://', 'https://');
            instanceUrl = `${instanceUrl}/api${i}`;
        } else {
            // Detectar si usa puertos o rutas
            const port = 3000 + i;
            instanceUrl = `${serverUrl}:${port}`;
        }
        
        console.log(`   URL de la instancia: ${instanceUrl}`);
        
        // Verificar si el servidor responde
        fetch(`${instanceUrl}/api/status`)
            .then(response => {
                if (response.ok) {
                    return response.json();
                } else {
                    throw new Error(`HTTP ${response.status}`);
                }
            })
            .then(data => {
                console.log(`   ✅ Servidor responde correctamente`);
                console.log(`   Estado del servidor:`, {
                    connected: data.connected || data.whatsapp === 'connected',
                    status: data.whatsapp || data.status,
                    tieneQR: !!data.qrCode || !!data.qr
                });
                
                // Verificar si el QR del servidor coincide con el guardado
                if (data.qrCode || data.qr) {
                    const serverQR = data.qrCode || data.qr;
                    const storedQR = card.qr;
                    
                    if (serverQR === storedQR || serverQR.includes(storedQR.substring(0, 20))) {
                        console.log(`   ✅ QR del servidor coincide con el guardado`);
                    } else {
                        console.warn(`   ⚠️ QR del servidor NO coincide con el guardado`);
                        console.warn(`   El QR puede haber expirado. Necesitas generar uno nuevo.`);
                    }
                }
            })
            .catch(error => {
                console.error(`   ❌ Error al conectar con el servidor:`, error.message);
                console.error(`   Posibles causas:`);
                console.error(`   - El servidor no está corriendo`);
                console.error(`   - El servidor no es accesible desde internet`);
                console.error(`   - Problema de red o firewall`);
                console.error(`   - URL incorrecta`);
            });
        
        // Verificar si el QR es válido
        console.log(`\n   🔍 Verificando formato del QR...`);
        const qrData = card.qr;
        
        // Los QRs de WhatsApp suelen empezar con ciertos patrones
        if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
            console.log(`   ✅ QR parece ser una URL (formato correcto)`);
        } else if (qrData.length > 100) {
            console.log(`   ✅ QR tiene longitud adecuada (${qrData.length} caracteres)`);
        } else {
            console.warn(`   ⚠️ QR puede ser inválido (muy corto: ${qrData.length} caracteres)`);
        }
        
        // Verificar antigüedad del QR (si tiene timestamp)
        if (card.qrTimestamp) {
            const age = Date.now() - card.qrTimestamp;
            const ageSeconds = Math.floor(age / 1000);
            console.log(`   ⏱️ QR generado hace ${ageSeconds} segundos`);
            
            if (ageSeconds > 30) {
                console.warn(`   ⚠️ QR EXPIRADO (más de 30 segundos)`);
                console.warn(`   Los QRs de WhatsApp expiran en 20-30 segundos`);
                console.warn(`   Necesitas generar un QR nuevo`);
            } else {
                console.log(`   ✅ QR aún válido (menos de 30 segundos)`);
            }
        } else {
            console.warn(`   ⚠️ No se puede determinar la antigüedad del QR`);
            console.warn(`   El QR puede haber expirado`);
        }
    }
}

// 2. Verificar conectividad
console.log('\n2️⃣ Verificando conectividad...');
console.log('   Para vincular WhatsApp, el servidor debe ser accesible desde internet');
console.log('   Si el servidor está en localhost o IP privada, NO funcionará desde tu teléfono');

// 3. Instrucciones
console.log('\n3️⃣ SOLUCIONES POSIBLES:');
console.log('\n   A) Si el QR expiró:');
console.log('      1. Haz clic en "Cancelar" en la tarjeta');
console.log('      2. Haz clic en "Conectar" nuevamente');
console.log('      3. Escanea el QR INMEDIATAMENTE (tienes 20-30 segundos)');
console.log('\n   B) Si el servidor no es accesible:');
console.log('      - Verifica que el servidor esté corriendo en EasyPanel');
console.log('      - Verifica que el servidor tenga IP pública o dominio');
console.log('      - Verifica que los puertos estén abiertos (3001, 3002, 3003, 3004)');
console.log('      - Si usas HTTPS, verifica que el certificado SSL sea válido');
console.log('\n   C) Si el QR no es válido:');
console.log('      - Verifica los logs del servidor en EasyPanel');
console.log('      - Verifica que whatsapp-web.js esté funcionando correctamente');
console.log('      - Intenta reiniciar el servicio de WhatsApp');

// Función para regenerar QR
window.regenerarQR = async function(cardNumber) {
    console.log(`\n🔄 Regenerando QR para tarjeta ${cardNumber}...`);
    
    // Cancelar conexión actual
    const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    cardData[cardNumber] = {
        ...cardData[cardNumber],
        status: 'disconnected',
        qr: null
    };
    localStorage.setItem('whatsappCards', JSON.stringify(cardData));
    
    if (typeof window.updateWhatsAppCard === 'function') {
        window.updateWhatsAppCard(cardNumber, cardData[cardNumber]);
    }
    
    // Esperar un momento y reconectar
    setTimeout(() => {
        if (typeof window.connectWhatsApp === 'function') {
            console.log(`🚀 Conectando WhatsApp ${cardNumber}...`);
            window.connectWhatsApp(cardNumber);
        } else {
            console.error('❌ Función connectWhatsApp no disponible');
        }
    }, 1000);
};

console.log('\n💡 Para regenerar un QR, ejecuta:');
console.log('   regenerarQR(1);  // Para WhatsApp 1');
console.log('   regenerarQR(2);  // Para WhatsApp 2');

console.log('\n✅ DIAGNÓSTICO COMPLETADO');


