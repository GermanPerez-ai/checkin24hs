// ============================================
// SCRIPT DE PRUEBA MANUAL PARA CHATS
// ============================================
// Copia y pega este código en la consola del navegador (F12)
// para probar la carga de chats directamente
// ============================================

(async function testChats() {
    console.log('🧪 INICIANDO PRUEBA MANUAL DE CHATS...');
    
    // 1. Verificar Supabase
    console.log('\n1️⃣ Verificando Supabase...');
    console.log('   - Supabase existe:', !!window.supabaseClient);
    if (window.supabaseClient) {
        console.log('   - Supabase inicializado:', window.supabaseClient.isInitialized());
    }
    
    // 2. Probar obtener chats directamente
    console.log('\n2️⃣ Obteniendo chats desde Supabase...');
    try {
        const chats = await window.supabaseClient.getWhatsAppChats(10);
        console.log('   ✅ Chats obtenidos:', chats.length);
        console.log('   📋 Primeros 3 chats:', chats.slice(0, 3));
        
        if (chats.length > 0) {
            console.log('\n   🔍 Estructura del primer chat:');
            console.log('   ', chats[0]);
        }
    } catch (error) {
        console.error('   ❌ Error obteniendo chats:', error);
    }
    
    // 3. Verificar elemento del DOM
    console.log('\n3️⃣ Verificando elemento chatsList...');
    const chatsList = document.getElementById('chatsList');
    console.log('   - chatsList encontrado:', !!chatsList);
    if (chatsList) {
        console.log('   - Contenido actual:', chatsList.innerHTML.substring(0, 100) + '...');
    }
    
    // 4. Ejecutar loadChats manualmente
    console.log('\n4️⃣ Ejecutando loadChats() manualmente...');
    if (typeof loadChats === 'function') {
        try {
            await loadChats();
            console.log('   ✅ loadChats() ejecutado');
        } catch (error) {
            console.error('   ❌ Error en loadChats():', error);
        }
    } else {
        console.error('   ❌ loadChats no está definida');
    }
    
    // 5. Verificar resultado final
    console.log('\n5️⃣ Verificando resultado final...');
    const finalChatsList = document.getElementById('chatsList');
    if (finalChatsList) {
        const hasContent = finalChatsList.innerHTML.trim().length > 0;
        const hasNoChatsMessage = finalChatsList.innerHTML.includes('No hay chats activos');
        const hasChats = !hasNoChatsMessage && hasContent;
        
        console.log('   - Tiene contenido:', hasContent);
        console.log('   - Muestra "No hay chats":', hasNoChatsMessage);
        console.log('   - Parece tener chats:', hasChats);
        
        if (hasChats) {
            console.log('   ✅ ¡ÉXITO! Los chats se están mostrando');
        } else if (hasNoChatsMessage) {
            console.log('   ⚠️ Muestra mensaje de "No hay chats"');
        } else {
            console.log('   ⚠️ Estado desconocido');
        }
    }
    
    console.log('\n✅ PRUEBA COMPLETADA');
})();

