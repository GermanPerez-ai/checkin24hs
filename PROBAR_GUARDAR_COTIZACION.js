// ============================================
// PRUEBA RÁPIDA: Intentar guardar una cotización en Supabase
// ============================================
// Copia y pega este código completo en la consola (F12 → Console)

(async function() {
    console.log('🧪 PRUEBA: Intentando guardar cotización en Supabase...\n');
    
    // 1. Verificar Supabase
    if (!window.supabaseClient) {
        console.error('❌ window.supabaseClient no existe');
        return;
    }
    console.log('✅ window.supabaseClient existe');
    
    if (!window.supabaseClient.isInitialized()) {
        console.error('❌ Supabase NO está inicializado');
        return;
    }
    console.log('✅ Supabase está inicializado\n');
    
    // 2. Generar código de prueba (debe ser exactamente 5 caracteres)
    function generateTestCode() {
        const numbers = [];
        for (let i = 0; i < 2; i++) {
            numbers.push(Math.floor(Math.random() * 10));
        }
        const letters = [];
        const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        for (let i = 0; i < 3; i++) {
            letters.push(alphabet.charAt(Math.floor(Math.random() * alphabet.length)));
        }
        const allChars = [...numbers, ...letters];
        for (let i = allChars.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [allChars[i], allChars[j]] = [allChars[j], allChars[i]];
        }
        return allChars.join('');
    }
    
    // 3. Crear cotización de prueba
    const testQuote = {
        id: 'TEST-' + Date.now(),
        code: generateTestCode(), // Código de exactamente 5 caracteres
        clientName: 'Cliente Prueba',
        clientPhone: '+56912345678',
        hotelId: null,
        hotel: 'Hotel Prueba',
        checkIn: new Date().toISOString().split('T')[0],
        checkOut: new Date(Date.now() + 86400000).toISOString().split('T')[0],
        adults: 2,
        children: 0,
        infants: 0,
        tariff: 100,
        discount: 0,
        finalTariff: 100,
        status: 'pending',
        timestamp: new Date().toISOString(),
        source: 'test'
    };
    
    console.log('📤 Cotización de prueba:', testQuote);
    console.log(`📝 Código generado: "${testQuote.code}" (${testQuote.code.length} caracteres)`);
    console.log('\n⏳ Intentando guardar...\n');
    
    // 4. Intentar guardar
    try {
        const result = await window.supabaseClient.createQuote(testQuote);
        console.log('✅ ✅ ✅ ÉXITO: Cotización guardada en Supabase');
        console.log('📋 Resultado:', result);
        
        // 5. Verificar que se guardó
        console.log('\n🔍 Verificando en Supabase...');
        const { data, error } = await window.supabaseClient.client
            .from('quotes')
            .select('*')
            .eq('code', testQuote.code)
            .single();
        
        if (error) {
            console.error('⚠️ No se pudo verificar:', error);
        } else {
            console.log('✅ ✅ ✅ VERIFICADO: La cotización está en Supabase');
            console.log('📋 Datos en Supabase:', data);
        }
        
    } catch (error) {
        console.error('❌ ❌ ❌ ERROR al guardar:');
        console.error('   Mensaje:', error.message);
        console.error('   Código:', error.code);
        console.error('   Detalles:', error.details);
        console.error('   Hint:', error.hint);
        console.error('\n💡 Esto indica por qué no se están guardando las cotizaciones');
    }
})();
