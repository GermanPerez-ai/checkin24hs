// ============================================
// PRUEBA DIRECTA EN LA CONSOLA
// ============================================
// Copia y pega TODO este código en la consola del navegador (F12)
// ============================================

(async function() {
    console.log('🧪 INICIANDO PRUEBA DIRECTA...\n');
    
    // 1. Verificar Supabase
    console.log('1️⃣ Verificando Supabase...');
    console.log('   Supabase existe:', !!window.supabaseClient);
    console.log('   Supabase inicializado:', window.supabaseClient?.isInitialized());
    
    // 2. Probar obtener chats
    console.log('\n2️⃣ Obteniendo chats desde Supabase...');
    try {
        const chats = await window.supabaseClient.getWhatsAppChats(10);
        console.log('   ✅ Chats obtenidos:', chats.length);
        if (chats.length > 0) {
            console.log('   📋 Primer chat:', chats[0]);
        } else {
            console.log('   ⚠️ No hay chats en Supabase');
        }
    } catch (error) {
        console.error('   ❌ Error:', error);
    }
    
    // 3. Probar obtener interacciones
    console.log('\n3️⃣ Obteniendo interacciones desde Supabase...');
    try {
        const interactions = await window.supabaseClient.getFlorInteractions(10);
        console.log('   ✅ Interacciones obtenidas:', interactions.length);
        if (interactions.length > 0) {
            console.log('   📋 Primera interacción:', interactions[0]);
        } else {
            console.log('   ⚠️ No hay interacciones en Supabase');
        }
    } catch (error) {
        console.error('   ❌ Error:', error);
    }
    
    // 4. Verificar elementos del DOM
    console.log('\n4️⃣ Verificando elementos del DOM...');
    const chatsList = document.getElementById('chatsList');
    const interactionsTable = document.getElementById('interactionsTableBody');
    console.log('   chatsList encontrado:', !!chatsList);
    console.log('   interactionsTableBody encontrado:', !!interactionsTable);
    
    // 5. Si hay chats, renderizarlos manualmente
    if (chats.length > 0 && chatsList) {
        console.log('\n5️⃣ Renderizando chats manualmente...');
        const chatsData = await window.supabaseClient.getWhatsAppChats(50);
        chatsList.innerHTML = chatsData.map(chat => {
            const userName = chat.users?.name || chat.name || chat.phone || 'Cliente';
            const lastMessage = (chat.last_message || 'Sin mensajes').substring(0, 50);
            const lastMessageTime = chat.last_message_time 
                ? new Date(chat.last_message_time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
                : '';
            const unreadBadge = chat.unread_count > 0 
                ? `<span style="background: #25D366; color: white; padding: 2px 8px; border-radius: 10px; font-size: 12px; margin-left: 8px;">${chat.unread_count}</span>` 
                : '';
            
            return `
                <div onclick="selectChat('${chat.id}')" style="padding: 12px; border-bottom: 1px solid #eee; cursor: pointer; transition: background 0.2s; ${chat.unread_count > 0 ? 'background: #f0fff4;' : ''}" onmouseover="this.style.background='#f5f5f5'" onmouseout="this.style.background='${chat.unread_count > 0 ? '#f0fff4' : 'white'}'">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <strong>${userName}${unreadBadge}</strong>
                        <span style="font-size: 0.75rem; color: #999;">${lastMessageTime}</span>
                    </div>
                    <p style="margin: 4px 0 0 0; font-size: 0.85rem; color: #666; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${lastMessage}</p>
                </div>
            `;
        }).join('');
        console.log('   ✅ Chats renderizados:', chatsData.length);
    }
    
    // 6. Si hay interacciones, renderizarlas manualmente
    if (interactions.length > 0 && interactionsTable) {
        console.log('\n6️⃣ Renderizando interacciones manualmente...');
        const interactionsData = await window.supabaseClient.getFlorInteractions(100);
        
        // Agrupar por teléfono/sesión
        const grouped = {};
        interactionsData.forEach(inter => {
            const phone = inter.phone || 'web';
            const date = new Date(inter.created_at).toDateString();
            const key = `${phone}_${date}`;
            
            if (!grouped[key]) {
                grouped[key] = {
                    id: inter.id,
                    phone: phone,
                    date: inter.created_at,
                    messageCount: 1,
                    resolvedBy: inter.used_ai ? 'Flor IA' : 'Flor',
                    status: inter.success !== false ? 'resolved' : 'pending',
                    interactions: [inter]
                };
            } else {
                grouped[key].messageCount++;
                grouped[key].interactions.push(inter);
                if (inter.created_at > grouped[key].date) {
                    grouped[key].date = inter.created_at;
                }
            }
        });
        
        const groupedArray = Object.values(grouped).sort((a, b) => 
            new Date(b.date) - new Date(a.date)
        );
        
        interactionsTable.innerHTML = groupedArray.map(interaction => `
            <tr>
                <td style="padding: 12px;">${new Date(interaction.date).toLocaleString('es-ES')}</td>
                <td style="padding: 12px;">${interaction.phone || 'Desconocido'}</td>
                <td style="padding: 12px; text-align: center;">${interaction.messageCount || 0}</td>
                <td style="padding: 12px;">${interaction.resolvedBy || 'Flor'}</td>
                <td style="padding: 12px; text-align: center;">
                    <span style="background: ${interaction.status === 'resolved' ? '#4caf50' : '#ff9800'}; color: white; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem;">
                        ${interaction.status === 'resolved' ? 'Resuelto' : 'Pendiente'}
                    </span>
                </td>
                <td style="padding: 12px; text-align: center;">
                    <button onclick="viewInteraction('${interaction.id}')" style="background: #1976d2; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer;">
                        Ver
                    </button>
                </td>
            </tr>
        `).join('');
        console.log('   ✅ Interacciones renderizadas:', groupedArray.length);
    }
    
    console.log('\n✅ PRUEBA COMPLETADA');
})();

