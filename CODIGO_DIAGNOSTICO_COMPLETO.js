// ============================================
// CÓDIGO DE DIAGNÓSTICO COMPLETO
// Copia y pega TODO este código en la consola del navegador (F12)
// ============================================

console.log('🔍 ===== INICIANDO DIAGNÓSTICO =====');

// 1. Verificar que la función existe
console.log('1️⃣ connectWhatsApp disponible:', typeof window.connectWhatsApp);
console.log('1️⃣ getServerURL disponible:', typeof window.getServerURL);

// 2. Verificar URL configurada
const url = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
console.log('2️⃣ URL configurada:', url);

// 3. Verificar URL construida para tarjeta 1
if (typeof window.getServerURL === 'function') {
    const url1 = window.getServerURL(1);
    console.log('2️⃣ URL construida para tarjeta 1:', url1);
}

// 4. Verificar estado de botones
console.log('3️⃣ Verificando botones...');
for (let i = 1; i <= 4; i++) {
    const btn = document.getElementById(`whatsapp-${i}-connect-btn`);
    if (btn) {
        console.log(`   Botón ${i}:`, {
            existe: true,
            texto: btn.textContent,
            deshabilitado: btn.disabled,
            onclick: btn.getAttribute('onclick'),
            tieneListener: btn.onclick !== null
        });
    } else {
        console.log(`   Botón ${i}: NO ENCONTRADO`);
    }
}

// 5. Verificar estado de las tarjetas
const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
console.log('4️⃣ Estado de tarjetas:', cardData);

// 6. Probar conexión manualmente
console.log('5️⃣ Probando conexión manual...');
if (typeof window.connectWhatsApp === 'function') {
    console.log('   ✅ Función disponible, ejecutando connectWhatsApp(1)...');
    window.connectWhatsApp(1);
} else {
    console.error('   ❌ La función no está disponible. Recarga la página.');
}

console.log('✅ ===== DIAGNÓSTICO COMPLETADO =====');


