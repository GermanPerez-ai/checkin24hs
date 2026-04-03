// ============================================
// SCRIPT DE VERIFICACIÓN: Servidor de WhatsApp y Supabase
// ============================================
// Este script verifica que el servidor de WhatsApp esté
// configurado correctamente para guardar en Supabase
// ============================================

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Configuración de Supabase (debe coincidir con supabase-config.js)
const SUPABASE_CONFIG = {
    url: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
};

async function verificarServidorWhatsApp() {
    console.log('🔍 Verificando configuración del servidor de WhatsApp...\n');
    
    // 1. Verificar archivo del servidor
    const serverPath = path.join(__dirname, 'whatsapp-server', 'whatsapp-server.js');
    if (!fs.existsSync(serverPath)) {
        console.error('❌ No se encontró el archivo whatsapp-server.js');
        return;
    }
    
    console.log('✅ Archivo del servidor encontrado');
    
    // 2. Leer configuración del servidor
    const serverContent = fs.readFileSync(serverPath, 'utf8');
    
    // Verificar que SAVE_TO_SUPABASE esté en true
    if (serverContent.includes('SAVE_TO_SUPABASE: true')) {
        console.log('✅ SAVE_TO_SUPABASE está habilitado');
    } else {
        console.warn('⚠️ SAVE_TO_SUPABASE no está habilitado o no se encontró');
    }
    
    // Verificar que tenga la URL de Supabase
    if (serverContent.includes('SUPABASE_URL') || serverContent.includes('lmoeuyasuvoqhtvhkyia.supabase.co')) {
        console.log('✅ URL de Supabase configurada');
    } else {
        console.warn('⚠️ URL de Supabase no encontrada en el código');
    }
    
    // Verificar que tenga las funciones de guardado
    const funcionesRequeridas = [
        'saveMessageToSupabase',
        'saveInteraction',
        'saveOrUpdateChat',
        'saveOrUpdateUser'
    ];
    
    console.log('\n📋 Verificando funciones de guardado:');
    funcionesRequeridas.forEach(func => {
        if (serverContent.includes(`async function ${func}`) || serverContent.includes(`function ${func}`)) {
            console.log(`  ✅ ${func} encontrada`);
        } else {
            console.warn(`  ⚠️ ${func} no encontrada`);
        }
    });
    
    // 3. Verificar conexión con Supabase
    console.log('\n🔌 Verificando conexión con Supabase...');
    try {
        const supabase = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
        
        // Probar consulta simple
        const { data: chats, error: chatsError } = await supabase
            .from('whatsapp_chats')
            .select('count')
            .limit(1);
        
        if (chatsError) {
            console.error('❌ Error conectando a Supabase:', chatsError.message);
            if (chatsError.message.includes('RLS')) {
                console.error('   ⚠️ Posible problema con Row Level Security (RLS)');
                console.error('   💡 Ejecuta el script script_rls_completo.sql en Supabase');
            }
        } else {
            console.log('✅ Conexión con Supabase exitosa');
        }
        
        // 4. Verificar datos existentes
        console.log('\n📊 Verificando datos en Supabase...');
        
        // Contar chats
        const { count: chatsCount, error: chatsCountError } = await supabase
            .from('whatsapp_chats')
            .select('*', { count: 'exact', head: true });
        
        if (!chatsCountError) {
            console.log(`  📱 Chats: ${chatsCount || 0}`);
        } else {
            console.warn(`  ⚠️ Error contando chats: ${chatsCountError.message}`);
        }
        
        // Contar mensajes
        const { count: messagesCount, error: messagesCountError } = await supabase
            .from('whatsapp_messages')
            .select('*', { count: 'exact', head: true });
        
        if (!messagesCountError) {
            console.log(`  💬 Mensajes: ${messagesCount || 0}`);
        } else {
            console.warn(`  ⚠️ Error contando mensajes: ${messagesCountError.message}`);
        }
        
        // Contar interacciones
        const { count: interactionsCount, error: interactionsCountError } = await supabase
            .from('flor_interactions')
            .select('*', { count: 'exact', head: true });
        
        if (!interactionsCountError) {
            console.log(`  🌸 Interacciones: ${interactionsCount || 0}`);
        } else {
            console.warn(`  ⚠️ Error contando interacciones: ${interactionsCountError.message}`);
        }
        
        // 5. Verificar últimos registros
        console.log('\n📅 Últimos registros:');
        
        // Último chat
        const { data: lastChat, error: lastChatError } = await supabase
            .from('whatsapp_chats')
            .select('phone, last_message_time, created_at')
            .order('last_message_time', { ascending: false })
            .limit(1)
            .single();
        
        if (!lastChatError && lastChat) {
            console.log(`  📱 Último chat: ${lastChat.phone} - ${new Date(lastChat.last_message_time).toLocaleString('es-ES')}`);
        } else if (lastChatError && lastChatError.code !== 'PGRST116') {
            console.warn(`  ⚠️ Error obteniendo último chat: ${lastChatError.message}`);
        } else {
            console.log('  📱 No hay chats aún');
        }
        
        // Última interacción
        const { data: lastInteraction, error: lastInteractionError } = await supabase
            .from('flor_interactions')
            .select('phone, created_at, intent')
            .order('created_at', { ascending: false })
            .limit(1)
            .single();
        
        if (!lastInteractionError && lastInteraction) {
            console.log(`  🌸 Última interacción: ${lastInteraction.phone} - ${lastInteraction.intent} - ${new Date(lastInteraction.created_at).toLocaleString('es-ES')}`);
        } else if (lastInteractionError && lastInteractionError.code !== 'PGRST116') {
            console.warn(`  ⚠️ Error obteniendo última interacción: ${lastInteractionError.message}`);
        } else {
            console.log('  🌸 No hay interacciones aún');
        }
        
    } catch (error) {
        console.error('❌ Error verificando Supabase:', error.message);
    }
    
    // 6. Resumen y recomendaciones
    console.log('\n📋 Resumen:');
    console.log('  1. Verifica que el servidor de WhatsApp esté corriendo');
    console.log('  2. Verifica que SAVE_TO_SUPABASE esté en true');
    console.log('  3. Verifica que la URL y anonKey de Supabase sean correctas');
    console.log('  4. Envía un mensaje de prueba a WhatsApp');
    console.log('  5. Revisa los logs del servidor para ver si guarda en Supabase');
    console.log('\n💡 Si no hay datos, puede ser porque:');
    console.log('  - El servidor no está corriendo');
    console.log('  - No se han recibido mensajes aún');
    console.log('  - Hay un error en la configuración de Supabase');
    console.log('  - RLS no está configurado correctamente');
}

// Ejecutar verificación
verificarServidorWhatsApp().catch(console.error);

