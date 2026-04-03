// ============================================
// REGENERAR QR Y VERIFICAR SERVIDOR
// ============================================
// Ejecuta este script para regenerar el QR y verificar el servidor

console.log('🔄 REGENERANDO QR Y VERIFICANDO SERVIDOR...\n');

async function regenerarYVerificar(cardNumber) {
    console.log(`📱 Procesando tarjeta ${cardNumber}...\n`);
    
    // 1. Obtener URL del servidor
    const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl') || 'http://configwp.checkin24hs.com';
    let instanceUrl = serverUrl;
    
    if (window.location.protocol === 'https:') {
        instanceUrl = instanceUrl.replace('http://', 'https://');
        instanceUrl = `${instanceUrl}/api${cardNumber}`;
    } else {
        const port = 3000 + cardNumber;
        instanceUrl = `${serverUrl}:${port}`;
    }
    
    console.log(`1️⃣ Verificando servidor: ${instanceUrl}`);
    
    // 2. Verificar que el servidor responda
    try {
        const statusResponse = await fetch(`${instanceUrl}/api/status`);
        if (!statusResponse.ok) {
            throw new Error(`HTTP ${statusResponse.status}`);
        }
        const statusData = await statusResponse.json();
        console.log(`   ✅ Servidor responde correctamente`);
        console.log(`   Estado: ${statusData.whatsapp || statusData.status || 'unknown'}`);
        
        if (statusData.connected || statusData.whatsapp === 'connected') {
            console.log(`   ✅ WhatsApp ya está conectado`);
            return;
        }
    } catch (error) {
        console.error(`   ❌ Error al conectar con el servidor:`, error.message);
        console.error(`   ⚠️ El servidor no es accesible desde este navegador`);
        console.error(`   Posibles causas:`);
        console.error(`   - El servidor no está corriendo`);
        console.error(`   - El servidor no es accesible desde internet`);
        console.error(`   - Problema de red o firewall`);
        console.error(`   - URL incorrecta`);
        return;
    }
    
    // 3. Cancelar conexión actual si existe
    console.log(`\n2️⃣ Cancelando conexión actual...`);
    const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    const currentData = cardData[cardNumber] || {};
    
    if (currentData.status === 'connecting') {
        // Detener actualización de QR
        if (typeof window.stopQRRefresh === 'function') {
            window.stopQRRefresh(cardNumber);
        }
        
        currentData.status = 'disconnected';
        currentData.qr = null;
        currentData.qrTimestamp = null;
        cardData[cardNumber] = currentData;
        localStorage.setItem('whatsappCards', JSON.stringify(cardData));
        
        if (typeof window.updateWhatsAppCard === 'function') {
            window.updateWhatsAppCard(cardNumber, currentData);
        }
        
        console.log(`   ✅ Conexión cancelada`);
        
        // Esperar un momento antes de reconectar
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    // 4. Generar nuevo QR
    console.log(`\n3️⃣ Generando nuevo QR...`);
    
    if (typeof window.connectWhatsApp === 'function') {
        console.log(`   🚀 Llamando a connectWhatsApp(${cardNumber})...`);
        try {
            await window.connectWhatsApp(cardNumber);
            console.log(`   ✅ Función ejecutada`);
            
            // Esperar a que se genere el QR
            console.log(`   ⏳ Esperando QR del servidor...`);
            await new Promise(resolve => setTimeout(resolve, 3000));
            
            // Verificar que se haya generado
            const updatedCardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
            const updatedCard = updatedCardData[cardNumber] || {};
            
            if (updatedCard.qr) {
                console.log(`   ✅ QR generado correctamente`);
                console.log(`   📏 Longitud: ${updatedCard.qr.length} caracteres`);
                console.log(`   ⏱️ Timestamp: ${updatedCard.qrTimestamp ? new Date(updatedCard.qrTimestamp).toLocaleTimeString() : 'No disponible'}`);
                console.log(`\n   📱 INSTRUCCIONES:`);
                console.log(`   1. Abre WhatsApp en tu teléfono`);
                console.log(`   2. Ve a Configuración → Dispositivos vinculados`);
                console.log(`   3. Toca "Vincular un dispositivo"`);
                console.log(`   4. Escanea el QR INMEDIATAMENTE (tienes 20-30 segundos)`);
                console.log(`   5. El QR se actualiza automáticamente cada 15 segundos`);
            } else {
                console.warn(`   ⚠️ QR no se generó. Verifica los logs del servidor.`);
            }
        } catch (error) {
            console.error(`   ❌ Error al generar QR:`, error);
            console.error(`   Stack:`, error.stack);
        }
    } else {
        console.error(`   ❌ Función connectWhatsApp no disponible`);
    }
}

// Función global
window.regenerarQRWhatsApp = regenerarYVerificar;

console.log('✅ Script cargado');
console.log('\n💡 Para regenerar el QR de una tarjeta, ejecuta:');
console.log('   regenerarQRWhatsApp(1);  // Para WhatsApp 1');
console.log('   regenerarQRWhatsApp(2);  // Para WhatsApp 2');
console.log('   regenerarQRWhatsApp(3);  // Para WhatsApp 3');
console.log('   regenerarQRWhatsApp(4);  // Para WhatsApp 4');


