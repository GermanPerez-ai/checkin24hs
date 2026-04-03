// Script de diagnóstico para problemas con cotizaciones en el dashboard
// Ejecutar en la consola del navegador (F12) cuando estés en el dashboard

console.log('==========================================');
console.log('🔍 DIAGNÓSTICO DE COTIZACIONES');
console.log('==========================================');
console.log('');

// 1. Verificar si Supabase está inicializado
console.log('1️⃣ Verificando Supabase Client...');
if (typeof window.supabaseClient === 'undefined') {
    console.error('❌ window.supabaseClient NO está definido');
    console.log('   El cliente de Supabase no se ha inicializado');
} else {
    console.log('✅ window.supabaseClient existe');
    
    if (window.supabaseClient.isInitialized && window.supabaseClient.isInitialized()) {
        console.log('✅ Supabase está inicializado');
    } else {
        console.warn('⚠️ Supabase NO está inicializado');
        console.log('   Esto puede ser normal si las variables de entorno no están configuradas');
    }
}
console.log('');

// 2. Verificar localStorage
console.log('2️⃣ Verificando localStorage...');
const quotesFromStorage = JSON.parse(localStorage.getItem('quotesDB') || '[]');
console.log(`   Cotizaciones en localStorage: ${quotesFromStorage.length}`);
if (quotesFromStorage.length > 0) {
    console.log('   ✅ Hay cotizaciones en localStorage');
    console.log('   Primera cotización:', quotesFromStorage[0]);
} else {
    console.log('   ⚠️ No hay cotizaciones en localStorage');
}
console.log('');

// 3. Verificar si la función loadQuotesTable existe
console.log('3️⃣ Verificando función loadQuotesTable...');
if (typeof loadQuotesTable === 'function') {
    console.log('✅ loadQuotesTable existe');
} else {
    console.error('❌ loadQuotesTable NO existe');
    console.log('   La función no está definida en el scope global');
}
console.log('');

// 4. Verificar elemento del DOM
console.log('4️⃣ Verificando elementos del DOM...');
const tbody = document.getElementById('quotesTableBody');
if (tbody) {
    console.log('✅ quotesTableBody existe en el DOM');
    console.log(`   Filas actuales: ${tbody.children.length}`);
} else {
    console.error('❌ quotesTableBody NO existe en el DOM');
    console.log('   El elemento no se encuentra. Verifica que estés en la sección de Cotizaciones');
}
console.log('');

// 5. Intentar cargar cotizaciones manualmente
console.log('5️⃣ Intentando cargar cotizaciones manualmente...');
if (window.supabaseClient && window.supabaseClient.isInitialized && window.supabaseClient.isInitialized()) {
    console.log('   Intentando desde Supabase...');
    window.supabaseClient.getQuotes()
        .then(quotes => {
            console.log(`   ✅ ${quotes.length} cotizaciones obtenidas desde Supabase`);
            if (quotes.length > 0) {
                console.log('   Primera cotización:', quotes[0]);
            }
        })
        .catch(error => {
            console.error('   ❌ Error obteniendo cotizaciones desde Supabase:', error);
            console.log('   Detalles del error:', error.message);
            if (error.message) {
                console.log('   Mensaje:', error.message);
            }
            if (error.details) {
                console.log('   Detalles:', error.details);
            }
            if (error.hint) {
                console.log('   Hint:', error.hint);
            }
        });
} else {
    console.log('   ⚠️ Supabase no está inicializado, usando localStorage');
    console.log(`   Cotizaciones disponibles: ${quotesFromStorage.length}`);
}
console.log('');

// 6. Verificar si hay errores en la consola
console.log('6️⃣ Verificando errores...');
console.log('   Revisa la consola del navegador (F12) para ver si hay errores en rojo');
console.log('   Busca mensajes que contengan:');
console.log('   - "Error obteniendo cotizaciones"');
console.log('   - "Error cargando desde Supabase"');
console.log('   - "quotes"');
console.log('   - "Supabase"');
console.log('');

// 7. Intentar ejecutar loadQuotesTable manualmente
console.log('7️⃣ Intentando ejecutar loadQuotesTable()...');
if (typeof loadQuotesTable === 'function') {
    try {
        console.log('   Ejecutando loadQuotesTable()...');
        loadQuotesTable()
            .then(() => {
                console.log('   ✅ loadQuotesTable() se ejecutó correctamente');
                setTimeout(() => {
                    const tbodyAfter = document.getElementById('quotesTableBody');
                    if (tbodyAfter) {
                        console.log(`   Filas después de ejecutar: ${tbodyAfter.children.length}`);
                    }
                }, 1000);
            })
            .catch(error => {
                console.error('   ❌ Error ejecutando loadQuotesTable():', error);
            });
    } catch (error) {
        console.error('   ❌ Error al intentar ejecutar loadQuotesTable():', error);
    }
} else {
    console.log('   ⚠️ loadQuotesTable no está disponible');
}
console.log('');

// 8. Verificar configuración de Supabase
console.log('8️⃣ Verificando configuración de Supabase...');
if (window.supabaseClient && window.supabaseClient.client) {
    console.log('✅ Cliente de Supabase existe');
    // Intentar verificar conexión
    window.supabaseClient.client.from('quotes').select('id').limit(1)
        .then(({ data, error }) => {
            if (error) {
                console.error('   ❌ Error consultando tabla quotes:', error);
                console.log('   Mensaje:', error.message);
                if (error.message.includes('permission') || error.message.includes('policy')) {
                    console.log('   ⚠️ Problema de permisos en Supabase');
                    console.log('   Verifica las políticas RLS (Row Level Security) en Supabase');
                }
            } else {
                console.log('   ✅ Conexión a Supabase funciona');
                console.log(`   Total de cotizaciones en Supabase: ${data ? 'al menos 1' : '0'}`);
            }
        })
        .catch(error => {
            console.error('   ❌ Error de conexión:', error);
        });
} else {
    console.log('   ⚠️ Cliente de Supabase no está disponible');
}
console.log('');

console.log('==========================================');
console.log('✅ Diagnóstico completado');
console.log('==========================================');
console.log('');
console.log('📋 Próximos pasos:');
console.log('   1. Revisa los errores mostrados arriba');
console.log('   2. Si hay errores de Supabase, verifica:');
console.log('      - Variables de entorno (SUPABASE_URL, SUPABASE_ANON_KEY)');
console.log('      - Políticas RLS en Supabase');
console.log('      - Que la tabla "quotes" exista');
console.log('   3. Si no hay errores pero no se cargan, verifica:');
console.log('      - Que estés en la sección "Cotizaciones" del dashboard');
console.log('      - Que la función loadQuotesTable() se ejecute al cargar la sección');
