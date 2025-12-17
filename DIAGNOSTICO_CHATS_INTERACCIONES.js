// Script de diagnóstico para chats e interacciones
// Copia y pega este código en la consola del navegador (F12)

console.log('🔍 INICIANDO DIAGNÓSTICO DE CHATS E INTERACCIONES...\n');

// 1. Verificar Supabase
console.log('1️⃣ Verificando Supabase...');
if (!window.supabaseClient) {
    console.error('❌ window.supabaseClient no existe');
} else if (!window.supabaseClient.isInitialized()) {
    console.error('❌ Supabase no está inicializado');
} else {
    console.log('✅ Supabase está inicializado');
}

// 2. Verificar elementos del DOM
console.log('\n2️⃣ Verificando elementos del DOM...');
const chatsList = document.getElementById('chatsList');
const interactionsTableBody = document.getElementById('interactionsTableBody');
console.log('chatsList encontrado:', !!chatsList);
console.log('interactionsTableBody encontrado:', !!interactionsTableBody);

// 3. Intentar cargar chats manualmente
console.log('\n3️⃣ Intentando cargar chats desde Supabase...');
if (window.supabaseClient && window.supabaseClient.isInitialized()) {
    window.supabaseClient.getWhatsAppChats(10)
        .then(chats => {
            console.log(`✅ Chats cargados: ${chats.length}`);
            if (chats.length > 0) {
                console.log('📱 Primer chat:', chats[0]);
            } else {
                console.log('⚠️ No hay chats en Supabase');
            }
        })
        .catch(error => {
            console.error('❌ Error cargando chats:', error);
        });
} else {
    console.error('❌ No se puede cargar chats - Supabase no está disponible');
}

// 4. Intentar cargar interacciones manualmente
console.log('\n4️⃣ Intentando cargar interacciones desde Supabase...');
if (window.supabaseClient && window.supabaseClient.isInitialized()) {
    window.supabaseClient.getFlorInteractions(10)
        .then(interactions => {
            console.log(`✅ Interacciones cargadas: ${interactions.length}`);
            if (interactions.length > 0) {
                console.log('🌸 Primera interacción:', interactions[0]);
            } else {
                console.log('⚠️ No hay interacciones en Supabase');
            }
        })
        .catch(error => {
            console.error('❌ Error cargando interacciones:', error);
        });
} else {
    console.error('❌ No se puede cargar interacciones - Supabase no está disponible');
}

// 5. Verificar funciones globales
console.log('\n5️⃣ Verificando funciones globales...');
console.log('loadChats disponible:', typeof window.loadChats === 'function');
console.log('loadInteractions disponible:', typeof window.loadInteractions === 'function');

// 6. Intentar ejecutar funciones manualmente
console.log('\n6️⃣ Intentando ejecutar funciones manualmente...');
if (typeof window.loadChats === 'function') {
    console.log('🔄 Ejecutando loadChats()...');
    window.loadChats().catch(err => {
        console.error('❌ Error ejecutando loadChats:', err);
    });
} else {
    console.error('❌ loadChats no está disponible');
}

setTimeout(() => {
    if (typeof window.loadInteractions === 'function') {
        console.log('🔄 Ejecutando loadInteractions()...');
        window.loadInteractions().catch(err => {
            console.error('❌ Error ejecutando loadInteractions:', err);
        });
    } else {
        console.error('❌ loadInteractions no está disponible');
    }
}, 2000);

console.log('\n✅ Diagnóstico completado. Revisa los resultados arriba.');

