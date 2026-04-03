// ============================================
// DIAGNÓSTICO: Por qué no se genera el QR
// ============================================
// Ejecuta este script en la consola del navegador
// para diagnosticar por qué no se genera el QR

console.log('🔍 INICIANDO DIAGNÓSTICO DE QR WHATSAPP...\n');

// 1. Verificar que las funciones estén disponibles
console.log('1️⃣ Verificando funciones disponibles:');
console.log('   - window.connectWhatsApp:', typeof window.connectWhatsApp);
console.log('   - window.disconnectWhatsApp:', typeof window.disconnectWhatsApp);
console.log('   - window.updateWhatsApp:', typeof window.updateWhatsApp);
console.log('   - window.getServerURL:', typeof window.getServerURL);

// 2. Verificar que los botones existan
console.log('\n2️⃣ Verificando botones en el DOM:');
for (let i = 1; i <= 4; i++) {
    const btn = document.getElementById(`whatsapp-${i}-connect-btn`);
    console.log(`   - Botón WhatsApp ${i}:`, btn ? '✅ Existe' : '❌ NO EXISTE');
    if (btn) {
        console.log(`     Texto: "${btn.textContent}"`);
        console.log(`     Deshabilitado: ${btn.disabled}`);
        console.log(`     Tiene onclick: ${btn.hasAttribute('onclick')}`);
    }
}

// 3. Verificar event listeners
console.log('\n3️⃣ Verificando event listeners:');
for (let i = 1; i <= 4; i++) {
    const btn = document.getElementById(`whatsapp-${i}-connect-btn`);
    if (btn) {
        // Intentar obtener los listeners (no siempre funciona en todos los navegadores)
        console.log(`   - Botón WhatsApp ${i}:`);
        console.log(`     Tipo: ${btn.tagName}`);
        console.log(`     ID: ${btn.id}`);
    }
}

// 4. Verificar URL del servidor
console.log('\n4️⃣ Verificando configuración del servidor:');
const serverUrlInput = document.getElementById('whatsapp-server-url');
if (serverUrlInput) {
    console.log('   - Input encontrado:', serverUrlInput.value);
} else {
    console.log('   - ❌ Input de URL no encontrado');
}

const storedUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
console.log('   - URL guardada en localStorage:', storedUrl);

// 5. Verificar estado de las tarjetas
console.log('\n5️⃣ Verificando estado de las tarjetas:');
const cardsData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
for (let i = 1; i <= 4; i++) {
    const card = cardsData[i] || {};
    console.log(`   - Tarjeta ${i}:`, {
        status: card.status || 'disconnected',
        tieneQR: !!card.qr,
        phone: card.phone || '-',
        name: card.name || '-'
    });
}

// 6. Probar función getServerURL
console.log('\n6️⃣ Probando función getServerURL:');
if (typeof window.getServerURL === 'function') {
    for (let i = 1; i <= 4; i++) {
        try {
            const url = window.getServerURL(i);
            console.log(`   - Tarjeta ${i}: ${url}`);
        } catch (error) {
            console.log(`   - ❌ Error obteniendo URL para tarjeta ${i}:`, error.message);
        }
    }
} else {
    console.log('   - ❌ Función getServerURL no disponible');
}

// 7. Probar hacer clic manualmente
console.log('\n7️⃣ Para probar manualmente, ejecuta en la consola:');
console.log('   window.connectWhatsApp(1);');
console.log('   (Esto debería generar el QR para WhatsApp 1)');

// 8. Verificar si hay errores en la consola
console.log('\n8️⃣ Verificando errores:');
console.log('   - Revisa la consola arriba para ver si hay errores en rojo');
console.log('   - Si ves errores, cópialos y compártelos');

// 9. Función de prueba directa
window.testConnectWhatsApp = function(cardNumber = 1) {
    console.log(`\n🧪 PRUEBA DIRECTA: Conectando WhatsApp ${cardNumber}...`);
    
    if (typeof window.connectWhatsApp !== 'function') {
        console.error('❌ window.connectWhatsApp no está disponible');
        return;
    }
    
    try {
        window.connectWhatsApp(cardNumber);
        console.log('✅ Función ejecutada. Revisa los logs arriba.');
    } catch (error) {
        console.error('❌ Error al ejecutar:', error);
        console.error('Stack trace:', error.stack);
    }
};

console.log('\n✅ DIAGNÓSTICO COMPLETADO');
console.log('\n📋 Para probar la conexión manualmente, ejecuta:');
console.log('   testConnectWhatsApp(1);  // Para WhatsApp 1');
console.log('   testConnectWhatsApp(2);  // Para WhatsApp 2');
console.log('   testConnectWhatsApp(3);  // Para WhatsApp 3');
console.log('   testConnectWhatsApp(4);  // Para WhatsApp 4');


