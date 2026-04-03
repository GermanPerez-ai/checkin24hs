// ============================================
// SOLUCIÓN: QR EXPIRADO - Obtener QR más reciente
// ============================================
// Ejecuta este script para obtener los QRs más recientes del servidor

console.log('🔄 OBTENIENDO QRs MÁS RECIENTES DEL SERVIDOR...\n');

async function obtenerQRReciente(cardNumber) {
    console.log(`📱 Obteniendo QR más reciente para tarjeta ${cardNumber}...`);
    
    // Obtener URL del servidor
    const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl') || 'http://configwp.checkin24hs.com';
    let instanceUrl = serverUrl;
    
    if (window.location.protocol === 'https:') {
        instanceUrl = instanceUrl.replace('http://', 'https://');
        instanceUrl = `${instanceUrl}/api${cardNumber}`;
    } else {
        const port = 3000 + cardNumber;
        instanceUrl = `${serverUrl}:${port}`;
    }
    
    try {
        // Obtener QR del servidor
        const response = await fetch(`${instanceUrl}/api/qr?card=${cardNumber}`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        console.log(`   Estado del servidor: ${data.status}`);
        
        if (data.qr) {
            console.log(`   ✅ QR obtenido del servidor`);
            console.log(`   Longitud: ${data.qr.length} caracteres`);
            console.log(`   Primeros 30 caracteres: ${data.qr.substring(0, 30)}...`);
            
            // Actualizar localStorage
            const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
            const oldQR = cardData[cardNumber]?.qr;
            
            cardData[cardNumber] = {
                ...cardData[cardNumber],
                qr: data.qr,
                qrTimestamp: Date.now(),
                status: 'connecting'
            };
            localStorage.setItem('whatsappCards', JSON.stringify(cardData));
            
            // Verificar si cambió
            if (oldQR && oldQR !== data.qr) {
                console.log(`   🔄 QR ACTUALIZADO (era diferente al guardado)`);
            } else if (!oldQR) {
                console.log(`   ✅ QR NUEVO guardado`);
            } else {
                console.log(`   ℹ️ QR es el mismo (pero ahora tiene timestamp)`);
            }
            
            // Actualizar visualmente
            if (typeof window.updateWhatsAppCard === 'function') {
                window.updateWhatsAppCard(cardNumber, cardData[cardNumber]);
                console.log(`   ✅ Tarjeta actualizada visualmente`);
            }
            
            // Reiniciar actualización automática
            if (typeof window.startQRRefresh === 'function') {
                window.startQRRefresh(cardNumber);
                console.log(`   ✅ Actualización automática reiniciada`);
            }
            
            console.log(`\n   📱 INSTRUCCIONES:`);
            console.log(`   1. Abre WhatsApp en tu teléfono`);
            console.log(`   2. Ve a Configuración → Dispositivos vinculados`);
            console.log(`   3. Toca "Vincular un dispositivo"`);
            console.log(`   4. Escanea el QR INMEDIATAMENTE (tienes 20-30 segundos)`);
            console.log(`   5. El QR se actualiza automáticamente cada 15 segundos`);
            
            return true;
        } else if (data.status === 'connected') {
            console.log(`   ✅ WhatsApp ya está conectado`);
            return true;
        } else {
            console.warn(`   ⚠️ Servidor no tiene QR disponible (estado: ${data.status})`);
            return false;
        }
    } catch (error) {
        console.error(`   ❌ Error:`, error.message);
        return false;
    }
}

// Función global
window.obtenerQRReciente = obtenerQRReciente;

// Obtener QRs para todas las tarjetas que estén conectando
async function actualizarTodosLosQRs() {
    console.log('🔄 Actualizando todos los QRs...\n');
    
    const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    let actualizados = 0;
    
    for (let i = 1; i <= 4; i++) {
        const card = cardData[i] || {};
        if (card.status === 'connecting') {
            console.log(`\n📱 Procesando tarjeta ${i}...`);
            const resultado = await obtenerQRReciente(i);
            if (resultado) {
                actualizados++;
            }
            // Esperar un poco entre peticiones
            await new Promise(resolve => setTimeout(resolve, 500));
        }
    }
    
    console.log(`\n✅ Proceso completado: ${actualizados} QR(s) actualizado(s)`);
    console.log('\n💡 Si los QRs aparecen, escanéalos INMEDIATAMENTE con WhatsApp');
}

// Ejecutar automáticamente
actualizarTodosLosQRs();

console.log('\n💡 Para actualizar un QR específico, ejecuta:');
console.log('   obtenerQRReciente(1);  // Para WhatsApp 1');
console.log('   obtenerQRReciente(2);  // Para WhatsApp 2');


