// ============================================
// FORZAR MOSTRAR QR DIRECTAMENTE
// ============================================
// Este script fuerza la visualización del QR directamente en el DOM

console.log('🔧 FORZANDO VISUALIZACIÓN DE QR...\n');

// Función para mostrar QR directamente
function mostrarQRDirecto(cardNumber) {
    const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    const card = cardData[cardNumber] || {};
    
    console.log(`📋 Tarjeta ${cardNumber}:`, {
        status: card.status,
        tieneQR: !!card.qr,
        qrLength: card.qr ? card.qr.length : 0,
        qrPreview: card.qr ? card.qr.substring(0, 50) : 'null'
    });
    
    if (!card.qr) {
        console.log(`❌ Tarjeta ${cardNumber} no tiene QR guardado`);
        return false;
    }
    
    // Buscar contenedores
    const qrContainer = document.getElementById(`whatsapp-${cardNumber}-qr-container`);
    const qrDiv = document.getElementById(`whatsapp-${cardNumber}-qr`);
    
    console.log(`🔍 Contenedores encontrados:`, {
        qrContainer: !!qrContainer,
        qrDiv: !!qrDiv
    });
    
    if (!qrContainer) {
        console.error(`❌ Contenedor whatsapp-${cardNumber}-qr-container no encontrado`);
        return false;
    }
    
    // Asegurar que el contenedor esté visible
    qrContainer.style.display = 'block';
    
    if (!qrDiv) {
        console.error(`❌ Div whatsapp-${cardNumber}-qr no encontrado, creándolo...`);
        // Crear el div si no existe
        const newQrDiv = document.createElement('div');
        newQrDiv.id = `whatsapp-${cardNumber}-qr`;
        qrContainer.appendChild(newQrDiv);
        return mostrarQRDirecto(cardNumber); // Reintentar
    }
    
    // Limpiar contenido previo
    qrDiv.innerHTML = '';
    
    // Verificar tipo de QR
    const qrData = card.qr;
    console.log(`📦 Tipo de QR:`, {
        esBase64: qrData.startsWith('data:image'),
        esURL: qrData.startsWith('http'),
        longitud: qrData.length,
        primeros50: qrData.substring(0, 50)
    });
    
    // Generar URL de imagen QR usando API externa
    const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(qrData)}`;
    
    // Crear HTML completo con advertencia e instrucciones
    qrDiv.innerHTML = `
        <div style="text-align: center;">
            <div style="background: #fff3cd; border: 2px solid #ffc107; border-radius: 8px; padding: 10px; margin-bottom: 10px;">
                <p style="margin: 0; color: #856404; font-size: 12px; font-weight: bold;">⏱️ Este QR expira en 20-30 segundos</p>
                <p style="margin: 5px 0 0 0; color: #856404; font-size: 11px;">Se actualiza automáticamente. Escanéalo rápido.</p>
            </div>
            <img src="${qrImageUrl}" alt="QR Code" style="width: 200px; height: 200px; border-radius: 8px; display: block; margin: 0 auto; border: 3px solid #25D366;">
            <div style="margin-top: 10px; padding: 10px; background: #f8f9fa; border-radius: 8px;">
                <p style="margin: 0 0 5px 0; font-size: 12px; font-weight: bold; color: #333;">📱 Cómo escanear:</p>
                <ol style="margin: 0; padding-left: 20px; text-align: left; font-size: 11px; color: #666;">
                    <li>Abre WhatsApp en tu teléfono</li>
                    <li>Ve a <strong>Dispositivos vinculados</strong></li>
                    <li>Toca <strong>Vincular un dispositivo</strong></li>
                    <li>Escanea este código QR</li>
                </ol>
            </div>
        </div>
    `;
    
    console.log(`✅ QR mostrado directamente para tarjeta ${cardNumber}`);
    return true;
}

// Mostrar QRs para todas las tarjetas que tengan QR
console.log('🔍 Buscando QRs guardados...\n');

const cardsData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
let qrsMostrados = 0;

for (let i = 1; i <= 4; i++) {
    const card = cardsData[i] || {};
    if (card.qr && card.status === 'connecting') {
        console.log(`\n📱 Procesando tarjeta ${i}...`);
        if (mostrarQRDirecto(i)) {
            qrsMostrados++;
        }
    }
}

console.log(`\n✅ Proceso completado: ${qrsMostrados} QR(s) mostrado(s)`);

if (qrsMostrados === 0) {
    console.log('\n⚠️ No se encontraron QRs para mostrar.');
    console.log('💡 Verifica que:');
    console.log('   1. Las tarjetas estén en estado "connecting"');
    console.log('   2. Tengan QR guardado en localStorage');
    console.log('\n📋 Para verificar, ejecuta:');
    console.log('   const cards = JSON.parse(localStorage.getItem("whatsappCards") || \'{"1":{},"2":{},"3":{},"4":{}}\');');
    console.log('   console.log(cards);');
}

// Función global para forzar actualización
window.forzarMostrarQR = function(cardNumber) {
    console.log(`\n🔧 Forzando visualización de QR para tarjeta ${cardNumber}...`);
    return mostrarQRDirecto(cardNumber);
};

console.log('\n💡 Para forzar mostrar un QR específico, ejecuta:');
console.log('   forzarMostrarQR(1);  // Para WhatsApp 1');
console.log('   forzarMostrarQR(2);  // Para WhatsApp 2');


