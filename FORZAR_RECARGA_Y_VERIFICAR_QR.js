// ============================================
// SCRIPT PARA FORZAR RECARGA Y VERIFICAR QR
// Copia y pega este código en la consola del navegador (F12)
// ============================================

console.log('🔄 Forzando recarga completa...');

// 1. Limpiar caché del navegador forzando recarga
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for(let registration of registrations) {
            registration.unregister();
        }
    });
}

// 2. Verificar estado actual del QR
const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
console.log('📊 Estado actual de las tarjetas:', cardData);

// 3. Verificar si hay QR guardado
for (let i = 1; i <= 4; i++) {
    if (cardData[i] && cardData[i].qr) {
        console.log(`✅ Tarjeta ${i} tiene QR guardado:`, {
            tieneQR: !!cardData[i].qr,
            tipoQR: typeof cardData[i].qr,
            longitud: cardData[i].qr ? cardData[i].qr.length : 0,
            preview: cardData[i].qr ? cardData[i].qr.substring(0, 50) : 'null',
            status: cardData[i].status
        });
        
        // Intentar mostrar el QR manualmente
        const qrDiv = document.getElementById(`whatsapp-${i}-qr`);
        const qrContainer = document.getElementById(`whatsapp-${i}-qr-container`);
        
        if (qrDiv && qrContainer) {
            console.log(`🔍 Elementos encontrados para tarjeta ${i}:`, {
                qrDiv: !!qrDiv,
                qrContainer: !!qrContainer,
                qrContainerDisplay: qrContainer.style.display
            });
            
            // Forzar mostrar el QR
            if (cardData[i].status === 'connecting') {
                qrContainer.style.display = 'block';
                console.log(`✅ Contenedor QR mostrado para tarjeta ${i}`);
                
                // Intentar renderizar el QR
                if (cardData[i].qr.startsWith('data:image')) {
                    qrDiv.innerHTML = `<img src="${cardData[i].qr}" style="width: 200px; height: 200px; border-radius: 8px;">`;
                    console.log(`✅ QR mostrado como imagen base64 para tarjeta ${i}`);
                } else if (typeof QRCode !== 'undefined') {
                    qrDiv.innerHTML = '';
                    const canvas = document.createElement('canvas');
                    qrDiv.appendChild(canvas);
                    QRCode.toCanvas(canvas, cardData[i].qr, {
                        width: 200,
                        margin: 2
                    }, function(error) {
                        if (error) {
                            console.error(`❌ Error renderizando QR:`, error);
                        } else {
                            console.log(`✅ QR renderizado correctamente para tarjeta ${i}`);
                        }
                    });
                } else {
                    console.log(`⚠️ QR encontrado pero sin librería QRCode. Cargando...`);
                    qrDiv.innerHTML = `<div style="padding: 20px; text-align: center;">Cargando QR...</div>`;
                }
            }
        } else {
            console.log(`⚠️ Elementos QR no encontrados para tarjeta ${i}`);
        }
    } else {
        console.log(`❌ Tarjeta ${i} NO tiene QR guardado`);
    }
}

// 4. Recargar página completamente
console.log('🔄 Recargando página en 2 segundos...');
setTimeout(() => {
    window.location.reload(true);
}, 2000);

