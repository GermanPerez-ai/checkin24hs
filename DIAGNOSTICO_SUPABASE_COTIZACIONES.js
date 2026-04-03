// ============================================
// DIAGNÓSTICO: Verificar por qué no se guardan cotizaciones en Supabase
// ============================================
// Ejecuta este código en la consola del navegador (F12 → Console)

async function diagnosticarSupabaseCotizaciones() {
    console.log('🔍 Iniciando diagnóstico de Supabase para cotizaciones...\n');
    
    // 1. Verificar si Supabase está disponible
    console.log('1️⃣ Verificando si Supabase está disponible...');
    if (!window.supabaseClient) {
        console.error('❌ window.supabaseClient no existe');
        console.log('💡 Solución: Verifica que supabase-client.js esté cargado');
        return;
    }
    console.log('✅ window.supabaseClient existe');
    
    // 2. Verificar si está inicializado
    console.log('\n2️⃣ Verificando si Supabase está inicializado...');
    try {
        const isInit = window.supabaseClient.isInitialized();
        if (!isInit) {
            console.error('❌ Supabase NO está inicializado');
            console.log('💡 Solución: Verifica que supabase-config.js tenga las credenciales correctas');
            return;
        }
        console.log('✅ Supabase está inicializado');
    } catch (error) {
        console.error('❌ Error verificando inicialización:', error);
        return;
    }
    
    // 3. Verificar configuración
    console.log('\n3️⃣ Verificando configuración...');
    const config = window.SUPABASE_CONFIG || {};
    if (!config.url || config.url.includes('TU_SUPABASE')) {
        console.error('❌ Configuración de Supabase no válida');
        console.log('💡 Solución: Configura supabase-config.js con tus credenciales');
        return;
    }
    console.log('✅ Configuración encontrada');
    console.log('   URL:', config.url);
    console.log('   anonKey:', config.anonKey ? '✅ Configurada' : '❌ No configurada');
    
    // 4. Probar conexión
    console.log('\n4️⃣ Probando conexión con Supabase...');
    try {
        if (window.supabaseClient.testConnection) {
            const test = await window.supabaseClient.testConnection();
            if (test.success) {
                console.log('✅ Conexión exitosa');
            } else {
                console.error('❌ Error de conexión:', test.error);
            }
        } else {
            console.log('⚠️ Función testConnection no disponible, probando directamente...');
            const { data, error } = await window.supabaseClient.client
                .from('quotes')
                .select('id')
                .limit(1);
            
            if (error) {
                console.error('❌ Error de conexión:', error);
            } else {
                console.log('✅ Conexión exitosa');
            }
        }
    } catch (error) {
        console.error('❌ Error probando conexión:', error);
    }
    
    // 5. Verificar si la tabla existe
    console.log('\n5️⃣ Verificando si la tabla quotes existe...');
    try {
        const { data, error } = await window.supabaseClient.client
            .from('quotes')
            .select('id')
            .limit(1);
        
        if (error) {
            if (error.code === '42P01') {
                console.error('❌ La tabla "quotes" NO existe en Supabase');
                console.log('💡 Solución: Ejecuta create-tables.sql en Supabase SQL Editor');
            } else {
                console.error('❌ Error accediendo a la tabla:', error);
            }
        } else {
            console.log('✅ La tabla quotes existe');
        }
    } catch (error) {
        console.error('❌ Error verificando tabla:', error);
    }
    
    // 6. Verificar cotizaciones en localStorage
    console.log('\n6️⃣ Verificando cotizaciones en localStorage...');
    try {
        const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
        console.log(`📊 Total de cotizaciones en localStorage: ${quotes.length}`);
        if (quotes.length > 0) {
            const ultima = quotes[quotes.length - 1];
            console.log('📋 Última cotización:', {
                id: ultima.id,
                code: ultima.code,
                clientName: ultima.clientName,
                timestamp: ultima.timestamp
            });
        }
    } catch (error) {
        console.error('❌ Error leyendo localStorage:', error);
    }
    
    // 7. Intentar crear una cotización de prueba
    console.log('\n7️⃣ Intentando crear una cotización de prueba...');
    try {
        const testQuote = {
            id: 'TEST-' + Date.now(),
            code: 'TEST1',
            clientName: 'Test Cliente',
            clientPhone: '+56912345678',
            hotelId: null,
            checkIn: new Date().toISOString().split('T')[0],
            checkOut: new Date(Date.now() + 86400000).toISOString().split('T')[0],
            adults: 2,
            children: 0,
            tariff: 100,
            finalTariff: 100,
            status: 'pending',
            timestamp: new Date().toISOString(),
            source: 'test'
        };
        
        console.log('📤 Enviando cotización de prueba...');
        const result = await window.supabaseClient.createQuote(testQuote);
        console.log('✅ Cotización de prueba creada:', result);
        
        // Verificar que se guardó
        const { data: verifyData, error: verifyError } = await window.supabaseClient.client
            .from('quotes')
            .select('*')
            .eq('code', 'TEST1')
            .single();
        
        if (verifyError) {
            console.error('❌ No se pudo verificar la cotización:', verifyError);
        } else {
            console.log('✅ Cotización verificada en Supabase:', verifyData);
        }
    } catch (error) {
        console.error('❌ Error creando cotización de prueba:', error);
        console.log('📋 Detalles del error:', {
            message: error.message,
            code: error.code,
            details: error.details,
            hint: error.hint
        });
    }
    
    // 8. Verificar cotizaciones existentes en Supabase
    console.log('\n8️⃣ Verificando cotizaciones en Supabase...');
    try {
        const quotes = await window.supabaseClient.getQuotes();
        console.log(`📊 Total de cotizaciones en Supabase: ${quotes.length}`);
        if (quotes.length > 0) {
            console.log('📋 Últimas 3 cotizaciones:');
            quotes.slice(0, 3).forEach((q, i) => {
                console.log(`   ${i + 1}. ID: ${q.id}, Código: ${q.code || 'N/A'}, Cliente: ${q.clientName || q.customer_name || 'N/A'}`);
            });
        }
    } catch (error) {
        console.error('❌ Error obteniendo cotizaciones:', error);
    }
    
    console.log('\n✅ Diagnóstico completado');
    console.log('\n💡 Si hay errores, revisa:');
    console.log('   1. Que supabase-config.js tenga las credenciales correctas');
    console.log('   2. Que la tabla quotes exista en Supabase');
    console.log('   3. Que la columna code exista en la tabla quotes');
    console.log('   4. Que tengas permisos para insertar en la tabla');
}

// Ejecutar diagnóstico
diagnosticarSupabaseCotizaciones();
