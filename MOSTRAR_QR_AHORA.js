// ============================================
// MOSTRAR QR AHORA - Script rápido
// ============================================
// Copia y pega TODO este código en la consola del navegador

(function() {
    console.log('🔧 FORZANDO VISUALIZACIÓN DE QR...\n');
    
    // Cargar datos
    const cardsData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
    
    // Procesar cada tarjeta
    for (let i = 1; i <= 4; i++) {
        const card = cardsData[i] || {};
        
        if (card.qr && card.status === 'connecting') {
            console.log(`📱 Procesando tarjeta ${i}...`);
            
            // Buscar contenedores
            const qrContainer = document.getElementById(`whatsapp-${i}-qr-container`);
            const qrDiv = document.getElementById(`whatsapp-${i}-qr`);
            
            if (!qrContainer) {
                console.error(`❌ Contenedor whatsapp-${i}-qr-container no encontrado`);
                continue;
            }
            
            // Mostrar contenedor
            qrContainer.style.display = 'block';
            
            if (!qrDiv) {
                console.error(`❌ Div whatsapp-${i}-qr no encontrado`);
                continue;
            }
            
            // Generar URL de imagen QR
            const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(card.qr)}`;
            
            // Renderizar QR
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
            
            console.log(`✅ QR mostrado para tarjeta ${i}`);
        }
    }
    
    console.log('\n✅ Proceso completado');
    console.log('💡 Si el QR aparece, escanéalo rápidamente con WhatsApp');
    console.log('💡 Si no aparece, verifica que las tarjetas estén en estado "connecting"');
})();


