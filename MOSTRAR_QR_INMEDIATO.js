// ============================================
// MOSTRAR QR INMEDIATAMENTE USANDO API ONLINE
// Copia y pega este código en la consola del navegador (F12)
// ============================================

console.log('🚀 Mostrando QR inmediatamente...');

const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');

for (let i = 1; i <= 4; i++) {
    if (cardData[i] && cardData[i].qr && cardData[i].status === 'connecting') {
        const qrDiv = document.getElementById(`whatsapp-${i}-qr`);
        const qrContainer = document.getElementById(`whatsapp-${i}-qr-container`);
        
        if (qrDiv && qrContainer) {
            qrContainer.style.display = 'block';
            
            // Usar API de QR online
            const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(cardData[i].qr)}`;
            qrDiv.innerHTML = `<img src="${qrImageUrl}" alt="QR Code" style="width: 200px; height: 200px; border-radius: 8px; display: block; margin: 0 auto;">`;
            
            console.log(`✅ QR mostrado para tarjeta ${i} usando API online`);
        }
    }
}

console.log('✅ Proceso completado. El QR debería estar visible ahora.');


