// ============================================
// FORZAR MOSTRAR QR EXISTENTE
// ============================================
// Ejecuta este script para mostrar los QRs que ya están guardados
// pero no se están mostrando en la interfaz

console.log('🔄 Forzando actualización de tarjetas WhatsApp...\n');

// Cargar datos de las tarjetas
const cardsData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');

// Actualizar cada tarjeta
for (let i = 1; i <= 4; i++) {
    const card = cardsData[i] || {};
    console.log(`📋 Tarjeta ${i}:`, {
        status: card.status || 'disconnected',
        tieneQR: !!card.qr,
        qrLength: card.qr ? card.qr.length : 0,
        phone: card.phone || '-',
        name: card.name || '-'
    });
    
    // Si tiene QR y está en estado "connecting", forzar actualización
    if (card.status === 'connecting' && card.qr) {
        console.log(`   ✅ Tarjeta ${i} tiene QR guardado, forzando actualización visual...`);
        
        // Llamar a updateWhatsAppCard para mostrar el QR
        if (typeof window.updateWhatsAppCard === 'function') {
            window.updateWhatsAppCard(i, card);
            console.log(`   ✅ Tarjeta ${i} actualizada visualmente`);
        } else {
            console.error(`   ❌ window.updateWhatsAppCard no está disponible`);
    }
    
    // Reiniciar actualización automática si está conectando
    if (card.status === 'connecting' && typeof window.startQRRefresh === 'function') {
        console.log(`   🔄 Reiniciando actualización automática de QR para tarjeta ${i}...`);
        window.startQRRefresh(i);
    }
    
    // Reiniciar verificación de conexión
    if (card.status === 'connecting' && typeof window.checkWhatsAppConnectionStatus === 'function') {
        console.log(`   🔄 Reiniciando verificación de conexión para tarjeta ${i}...`);
        window.checkWhatsAppConnectionStatus(i);
    }
}

console.log('\n✅ Actualización completada');
console.log('\n📋 Si los QRs no aparecen:');
console.log('   1. Verifica que el contenedor del QR exista en el DOM');
console.log('   2. Revisa la consola para errores');
console.log('   3. Intenta recargar la página (F5)');

// Función para verificar contenedores de QR
window.verificarContenedoresQR = function() {
    console.log('\n🔍 Verificando contenedores de QR en el DOM:');
    for (let i = 1; i <= 4; i++) {
        const qrContainer = document.getElementById(`whatsapp-${i}-qr-container`);
        const qrDiv = document.getElementById(`whatsapp-${i}-qr`);
        console.log(`   Tarjeta ${i}:`);
        console.log(`     - Contenedor (qr-container):`, qrContainer ? '✅ Existe' : '❌ NO EXISTE');
        console.log(`     - Div QR (qr):`, qrDiv ? '✅ Existe' : '❌ NO EXISTE');
        if (qrDiv) {
            console.log(`     - Contenido del div:`, qrDiv.innerHTML.substring(0, 100));
        }
    }
};

console.log('\n💡 Para verificar los contenedores de QR, ejecuta:');
console.log('   verificarContenedoresQR();');


