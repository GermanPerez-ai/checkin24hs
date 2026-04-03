// Script de diagnóstico para verificar promociones en localStorage
// Ejecutar en la consola del navegador en https://cotizar.checkin24hs.com/

console.log('🔍 DIAGNÓSTICO DE PROMOCIONES');
console.log('================================');

// 1. Buscar todas las claves de promociones
const allKeys = Object.keys(localStorage);
const promotionKeys = allKeys.filter(key => key.startsWith('promotions_'));
console.log('\n📋 Claves de promociones encontradas:', promotionKeys);

// 2. Mostrar contenido de cada clave
promotionKeys.forEach(key => {
    try {
        const promotions = JSON.parse(localStorage.getItem(key) || '[]');
        console.log(`\n🔑 ${key}:`);
        console.log(`   Total promociones: ${promotions.length}`);
        if (promotions.length > 0) {
            promotions.forEach((promo, index) => {
                console.log(`   [${index + 1}] ${promo.name || promo.type || 'Sin nombre'}`);
                console.log(`       Status: ${promo.status || 'undefined'}`);
                console.log(`       Fechas: ${promo.startDate || 'N/A'} - ${promo.endDate || 'N/A'}`);
            });
        }
    } catch (error) {
        console.error(`   ❌ Error leyendo ${key}:`, error);
    }
});

// 3. Buscar hoteles
console.log('\n🏨 HOTELES:');
try {
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    console.log(`Total hoteles: ${hotels.length}`);
    hotels.forEach((hotel, index) => {
        console.log(`\n[${index + 1}] ${hotel.name || 'Sin nombre'}`);
        console.log(`   ID: ${hotel.id || 'Sin ID'}`);
        console.log(`   Clave esperada: promotions_${hotel.id || hotel.name}`);
        
        // Verificar si hay promociones para este hotel
        const promoKey = `promotions_${hotel.id || hotel.name}`;
        const hasPromotions = promotionKeys.includes(promoKey);
        if (hasPromotions) {
            const promos = JSON.parse(localStorage.getItem(promoKey) || '[]');
            console.log(`   ✅ Tiene ${promos.length} promociones guardadas`);
        } else {
            console.log(`   ⚠️ NO tiene promociones guardadas`);
        }
    });
} catch (error) {
    console.error('❌ Error leyendo hoteles:', error);
}

// 4. Buscar "Termas de Puyehue" específicamente
console.log('\n🔍 BUSCANDO "Termas de Puyehue":');
const puyehueKeys = promotionKeys.filter(key => 
    key.toLowerCase().includes('puyehue') || 
    key.toLowerCase().includes('termas')
);
if (puyehueKeys.length > 0) {
    console.log('✅ Claves encontradas:', puyehueKeys);
    puyehueKeys.forEach(key => {
        const promos = JSON.parse(localStorage.getItem(key) || '[]');
        console.log(`   ${key}: ${promos.length} promociones`);
    });
} else {
    console.log('⚠️ No se encontraron claves con "puyehue" o "termas"');
}

console.log('\n✅ Diagnóstico completado');
