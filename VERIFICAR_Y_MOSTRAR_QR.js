// ============================================
// VERIFICAR Y MOSTRAR QR MANUALMENTE
// Copia y pega este código en la consola del navegador (F12)
// ============================================

console.log('🔍 Verificando estado del QR...');

// 1. Verificar estado en localStorage
const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
console.log('📊 Estado completo de las tarjetas:', cardData);

// 2. Verificar cada tarjeta
for (let i = 1; i <= 4; i++) {
    console.log(`\n📋 === TARJETA ${i} ===`);
    
    if (cardData[i] && cardData[i].qr) {
        console.log(`✅ Tarjeta ${i} tiene QR guardado:`, {
            tieneQR: !!cardData[i].qr,
            tipoQR: typeof cardData[i].qr,
            longitud: cardData[i].qr ? cardData[i].qr.length : 0,
            preview: cardData[i].qr ? cardData[i].qr.substring(0, 80) + '...' : 'null',
            status: cardData[i].status,
            esBase64: cardData[i].qr ? cardData[i].qr.startsWith('data:image') : false
        });
        
        // Verificar elementos del DOM
        const qrDiv = document.getElementById(`whatsapp-${i}-qr`);
        const qrContainer = document.getElementById(`whatsapp-${i}-qr-container`);
        const statusBtn = document.getElementById(`whatsapp-${i}-status`);
        
        console.log(`🔍 Elementos del DOM:`, {
            qrDiv: !!qrDiv,
            qrContainer: !!qrContainer,
            statusBtn: !!statusBtn,
            qrContainerDisplay: qrContainer ? qrContainer.style.display : 'N/A',
            statusBtnText: statusBtn ? statusBtn.textContent : 'N/A'
        });
        
        // Si está en estado "connecting" y tiene QR, intentar mostrarlo
        if (cardData[i].status === 'connecting' && qrDiv && qrContainer) {
            console.log(`🎨 Intentando mostrar QR para tarjeta ${i}...`);
            
            // Mostrar el contenedor
            qrContainer.style.display = 'block';
            console.log(`✅ Contenedor QR mostrado`);
            
            // Limpiar contenido previo
            qrDiv.innerHTML = '';
            
            // Intentar renderizar según el tipo
            if (cardData[i].qr.startsWith('data:image')) {
                // Es una imagen base64
                qrDiv.innerHTML = `<img src="${cardData[i].qr}" style="width: 200px; height: 200px; border-radius: 8px; display: block; margin: 0 auto;">`;
                console.log(`✅ QR mostrado como imagen base64`);
            } else {
                // Es un string, necesitamos la librería QRCode
                console.log(`📦 QR es un string, necesitamos librería QRCode...`);
                console.log(`🔍 QRCode disponible:`, typeof QRCode !== 'undefined');
                
                if (typeof QRCode !== 'undefined' && typeof QRCode.toCanvas === 'function') {
                    // Tenemos la librería, renderizar
                    const canvas = document.createElement('canvas');
                    qrDiv.appendChild(canvas);
                    
                    QRCode.toCanvas(canvas, cardData[i].qr, {
                        width: 200,
                        margin: 2,
                        color: {
                            dark: '#000000',
                            light: '#FFFFFF'
                        }
                    }, function(error) {
                        if (error) {
                            console.error(`❌ Error renderizando QR:`, error);
                            qrDiv.innerHTML = `<div style="padding: 20px; text-align: center; color: #ff4757;">Error: ${error.message}</div>`;
                        } else {
                            console.log(`✅ QR renderizado correctamente`);
                        }
                    });
                } else {
                    // No tenemos la librería, cargarla
                    console.log(`📥 Cargando librería QRCode...`);
                    qrDiv.innerHTML = `<div style="padding: 20px; text-align: center;">Cargando QR...</div>`;
                    
                    const script = document.createElement('script');
                    script.src = 'https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js';
                    script.onload = () => {
                        console.log(`✅ Librería QRCode cargada`);
                        setTimeout(() => {
                            if (typeof QRCode !== 'undefined' && typeof QRCode.toCanvas === 'function') {
                                const canvas = document.createElement('canvas');
                                qrDiv.innerHTML = '';
                                qrDiv.appendChild(canvas);
                                
                                QRCode.toCanvas(canvas, cardData[i].qr, {
                                    width: 200,
                                    margin: 2,
                                    color: {
                                        dark: '#000000',
                                        light: '#FFFFFF'
                                    }
                                }, function(error) {
                                    if (error) {
                                        console.error(`❌ Error renderizando QR:`, error);
                                        qrDiv.innerHTML = `<div style="padding: 20px; text-align: center; color: #ff4757;">Error: ${error.message}</div>`;
                                    } else {
                                        console.log(`✅ QR renderizado correctamente después de cargar librería`);
                                    }
                                });
                            } else {
                                console.error(`❌ QRCode no disponible después de cargar`);
                                qrDiv.innerHTML = `<div style="padding: 20px; text-align: center; color: #ff4757;">Error: No se pudo cargar librería QRCode</div>`;
                            }
                        }, 100);
                    };
                    script.onerror = () => {
                        console.error(`❌ Error cargando librería QRCode`);
                        qrDiv.innerHTML = `<div style="padding: 20px; text-align: center; color: #ff4757;">Error cargando librería QRCode</div>`;
                    };
                    document.head.appendChild(script);
                }
            }
        } else {
            console.log(`⚠️ Tarjeta ${i} no está en estado "connecting" o faltan elementos del DOM`);
        }
    } else {
        console.log(`❌ Tarjeta ${i} NO tiene QR guardado`);
    }
}

console.log('\n✅ Verificación completada. Revisa los logs arriba.');


