// ============================================
// VERIFICAR POR QUÉ LOS CHATS NO SE RENDERIZAN
// Ejecutar en la consola del navegador (F12) mientras estás en la sección "Chats"
// ============================================

console.log('===========================================');
console.log('VERIFICAR RENDERIZADO DE CHATS');
console.log('===========================================');
console.log('');

// 1. Verificar datos cargados
console.log('=== 1. DATOS CARGADOS ===');
if (window._lastLoadedChats) {
    console.log('✅ Chats en memoria:', window._lastLoadedChats.length);
    if (window._lastLoadedChats.length > 0) {
        console.log('Primer chat completo:', window._lastLoadedChats[0]);
        console.log('Estructura del primer chat:', {
            id: window._lastLoadedChats[0].id,
            phone: window._lastLoadedChats[0].phone,
            name: window._lastLoadedChats[0].name,
            users: window._lastLoadedChats[0].users,
            last_message: window._lastLoadedChats[0].last_message,
            last_message_time: window._lastLoadedChats[0].last_message_time,
            unread_count: window._lastLoadedChats[0].unread_count,
            updated_at: window._lastLoadedChats[0].updated_at
        });
        
        // Verificar si tiene datos válidos para renderizar
        const primerChat = window._lastLoadedChats[0];
        console.log('¿Tiene datos válidos?', {
            tiene_id: !!primerChat.id,
            tiene_phone: !!primerChat.phone,
            tiene_name_o_phone: !!(primerChat.name || primerChat.phone || primerChat.users?.name),
            tiene_last_message: !!primerChat.last_message,
            tiene_last_message_time: !!primerChat.last_message_time
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
        console.log('HTML del primer elemento:', chatsList.children[0].outerHTML.substring(0, 200));
    } else {
        console.log('❌ No hay elementos renderizados en chatsList');
        console.log('Contenido innerHTML (primeros 1000 caracteres):', chatsList.innerHTML.substring(0, 1000));
        
        // Verificar si está mostrando "No hay chats activos"
        if (chatsList.innerHTML.includes('No hay chats activos')) {
            console.log('⚠️ Está mostrando "No hay chats activos" aunque hay chats cargados');
        }
        
        // Verificar si está mostrando "Cargando chats..."
        if (chatsList.innerHTML.includes('Cargando chats')) {
            console.log('⚠️ Está mostrando "Cargando chats..." - puede estar atascado');
        }
    }
} else {
    console.log('❌ chatsList NO encontrado en el DOM');
}
console.log('');

// 3. Intentar renderizar manualmente
console.log('=== 3. INTENTAR RENDERIZAR MANUALMENTE ===');
if (window._lastLoadedChats && window._lastLoadedChats.length > 0 && chatsList) {
    console.log('Intentando renderizar manualmente...');
    try {
        const esc = (s) => ('' + (s ?? '')).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        const primerChat = window._lastLoadedChats[0];
        const userName = primerChat.users?.name || primerChat.name || primerChat.phone || 'Cliente';
        const lastMessage = primerChat.last_message || 'Sin mensajes';
        const lastMessageTime = primerChat.last_message_time ? new Date(primerChat.last_message_time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }) : '';
        const id = (primerChat.id != null ? primerChat.id : '').toString().replace(/'/g, "\\'");
        
        const htmlPrueba = `
            <div onclick="selectChat('${id}')" style="padding: 12px; border-bottom: 1px solid #eee; cursor: pointer; background: #f0fff4;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <strong>${esc(userName)}</strong>
                    <span style="font-size: 0.75rem; color: #999;">${esc(lastMessageTime)}</span>
                </div>
                <p style="margin: 4px 0 0 0; font-size: 0.85rem; color: #666;">${esc(lastMessage)}</p>
            </div>
        `;
        
        console.log('HTML de prueba generado:', htmlPrueba.substring(0, 200));
        console.log('✅ HTML válido generado');
    } catch (error) {
        console.error('❌ Error generando HTML de prueba:', error);
    }
} else {
    console.log('⚠️ No se puede renderizar manualmente (faltan datos o elemento)');
}
console.log('');

// 4. Forzar recarga
console.log('=== 4. FORZAR RECARGA ===');
console.log('Para forzar recarga de chats, ejecuta:');
console.log('window.loadChats()');
console.log('');

// 5. Resumen
console.log('===========================================');
console.log('RESUMEN');
console.log('===========================================');

if (window._lastLoadedChats && window._lastLoadedChats.length > 0) {
    console.log('✅ Los chats están cargados en memoria');
    if (chatsList && chatsList.children.length > 0) {
        console.log('✅ Los chats están renderizados en el DOM');
    } else {
        console.log('❌ Los chats NO están renderizados en el DOM');
        console.log('   → Problema: Los chats se cargan pero no se renderizan');
        console.log('   → Posible causa: Error en el código de renderizado o datos inválidos');
    }
} else {
    console.log('❌ Los chats NO están cargados en memoria');
    console.log('   → Ejecuta: window.loadChats()');
}
