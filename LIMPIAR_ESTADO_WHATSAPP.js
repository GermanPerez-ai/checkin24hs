// ============================================
// SCRIPT PARA LIMPIAR ESTADO ATASCADO DE WHATSAPP
// Copia y pega este código en la consola del navegador (F12)
// ============================================

console.log('🧹 Limpiando estado atascado de WhatsApp...');

// Limpiar estado de todas las tarjetas
const cardData = {
    "1": { status: 'disconnected' },
    "2": { status: 'disconnected' },
    "3": { status: 'disconnected' },
    "4": { status: 'disconnected' }
};

localStorage.setItem('whatsappCards', JSON.stringify(cardData));
console.log('✅ Estado limpiado. Ahora puedes hacer clic en "Conectar" nuevamente.');

// Actualizar visualmente las tarjetas
if (typeof window.updateWhatsAppCard === 'function') {
    for (let i = 1; i <= 4; i++) {
        window.updateWhatsAppCard(i, cardData[i]);
    }
    console.log('✅ Tarjetas actualizadas visualmente.');
} else {
    console.log('⚠️ Función updateWhatsAppCard no disponible. Recarga la página.');
}

console.log('✅ ===== LIMPIEZA COMPLETADA =====');


