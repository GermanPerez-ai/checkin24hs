// ============================================
// DIAGNÓSTICO COMPLETO DE CHATS EN DASHBOARD
// Ejecutar en la consola del navegador (F12) mientras estás en la sección "Chats"
// ============================================

console.log('===========================================');
console.log('DIAGNÓSTICO: CHATS EN DASHBOARD');
console.log('===========================================');
console.log('');

// 1. Verificar datos cargados
console.log('=== 1. DATOS CARGADOS ===');
if (window._lastLoadedChats) {
    console.log('✅ Chats en memoria:', window._lastLoadedChats.length);
    if (window._lastLoadedChats.length > 0) {
        console.log('Primer chat:', window._lastLoadedChats[0]);
        console.log('Estructura del primer chat:', {
            id: window._lastLoadedChats[0].id,
            phone: window._lastLoadedChats[0].phone,
            name: window._lastLoadedChats[0].name,
            users: window._lastLoadedChats[0].users,
            last_message: window._lastLoadedChats[0].last_message,
            last_message_time: window._lastLoadedChats[0].last_message_time,
            unread_count: window._lastLoadedChats[0].unread_count
        });
    }
} else {
    console.log('❌ No hay chats en memoria (window._lastLoadedChats)');
}
console.log('');

// 2. Verificar elemento del DOM
console.log('=== 2. ELEMENTO DEL DOM ===');
const chatsList = document.getElementById('chatsList');
if (chatsList) {
    console.log('✅ chatsList encontrado');
    console.log('   - innerHTML length:', chatsList.innerHTML.length);
    console.log('   - children count:', chatsList.children.length);
    console.log('   - Display:', window.getComputedStyle(chatsList).display);
    console.log('   - Visibility:', window.getComputedStyle(chatsList).visibility);
    console.log('   - Height:', chatsList.offsetHeight);
    console.log('   - Width:', chatsList.offsetWidth);
    console.log('   - Overflow:', window.getComputedStyle(chatsList).overflow);
    
    // Verificar contenido
    if (chatsList.children.length > 0) {
        console.log('✅ Hay elementos renderizados:', chatsList.children.length);
        console.log('Primer elemento:', chatsList.children[0]);
    } else {
        console.log('❌ No hay elementos renderizados en chatsList');
        console.log('Contenido innerHTML (primeros 500 caracteres):', chatsList.innerHTML.substring(0, 500));
    }
} else {
    console.log('❌ chatsList NO encontrado en el DOM');
}
console.log('');

// 3. Verificar Supabase
console.log('=== 3. CONEXIÓN CON SUPABASE ===');
if (window.supabaseClient) {
    console.log('✅ window.supabaseClient existe');
    if (window.supabaseClient.isInitialized()) {
        console.log('✅ Supabase está inicializado');
        
        // Intentar cargar chats directamente
        window.supabaseClient.getWhatsAppChats(10).then(data => {
            console.log('✅ Chats cargados directamente desde Supabase:', data.length);
            if (data.length > 0) {
                console.log('Primer chat desde Supabase:', data[0]);
            }
        }).catch(error => {
            console.error('❌ Error cargando chats desde Supabase:', error);
        });
    } else {
        console.log('❌ Supabase NO está inicializado');
    }
} else {
    console.log('❌ window.supabaseClient NO existe');
}
console.log('');

// 4. Verificar sección visible
console.log('=== 4. SECCIÓN VISIBLE ===');
const chatsSection = document.getElementById('chats-section');
if (chatsSection) {
    const style = window.getComputedStyle(chatsSection);
    console.log('✅ chats-section encontrado');
    console.log('   - Display:', style.display);
    console.log('   - Visibility:', style.visibility);
    console.log('   - Opacity:', style.opacity);
    console.log('   - Height:', chatsSection.offsetHeight);
    console.log('   - Width:', chatsSection.offsetWidth);
} else {
    console.log('❌ chats-section NO encontrado');
}
console.log('');

// 5. Verificar función loadChats
console.log('=== 5. FUNCIÓN loadChats ===');
if (typeof window.loadChats === 'function') {
    console.log('✅ window.loadChats está definida');
    console.log('   - Tipo:', typeof window.loadChats);
} else {
    console.log('❌ window.loadChats NO está definida');
}
console.log('');

// 6. Resumen y recomendaciones
console.log('===========================================');
console.log('RESUMEN Y RECOMENDACIONES');
console.log('===========================================');

if (window._lastLoadedChats && window._lastLoadedChats.length > 0) {
    console.log('✅ Los chats están cargados en memoria');
} else {
    console.log('❌ Los chats NO están cargados en memoria');
    console.log('   → Ejecuta: window.loadChats()');
}

if (chatsList && chatsList.children.length > 0) {
    console.log('✅ Los chats están renderizados en el DOM');
} else {
    console.log('❌ Los chats NO están renderizados en el DOM');
    console.log('   → Ejecuta: window.loadChats()');
}

if (chatsSection && window.getComputedStyle(chatsSection).display !== 'none') {
    console.log('✅ La sección de chats está visible');
} else {
    console.log('❌ La sección de chats NO está visible');
    console.log('   → Verifica que estés en la sección "Chats"');
}

console.log('');
console.log('Para recargar chats, ejecuta:');
console.log('window.loadChats()');
